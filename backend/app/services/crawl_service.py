import asyncio
import logging
from datetime import datetime, timezone
from urllib.parse import urlparse

import httpx
from sqlalchemy import select
from sqlalchemy.dialects.postgresql import insert
from sqlalchemy.ext.asyncio import AsyncSession

from app.config import settings
from app.crawlers.base import CrawlResult, SourceCrawler
from app.crawlers.dantri import DantriCrawler
from app.crawlers.soha import SohaCrawler
from app.database import async_session
from app.models import Article, Category

logger = logging.getLogger(__name__)

CRAWLERS: dict[str, SourceCrawler] = {
    "soha": SohaCrawler(),
    "dantri": DantriCrawler(),
}

ALLOWED_CRAWL_HOSTS = {"soha.vn", "www.soha.vn", "dantri.com.vn", "www.dantri.com.vn"}


def _validate_crawl_url(url: str) -> None:
    parsed = urlparse(url)
    host = parsed.hostname or ""
    if parsed.scheme != "https":
        raise ValueError(f"Only HTTPS URLs allowed: {url}")
    if not any(host == h or host.endswith(f".{h}") for h in ALLOWED_CRAWL_HOSTS):
        raise ValueError(f"Disallowed crawl target: {host}")


def get_crawler_for_url(url: str) -> SourceCrawler | None:
    parsed = urlparse(url)
    host = parsed.hostname or ""
    if "soha.vn" in host:
        return CRAWLERS["soha"]
    if "dantri.com.vn" in host:
        return CRAWLERS["dantri"]
    return None


async def crawl_category(category: Category) -> CrawlResult:
    _validate_crawl_url(category.url)

    crawler = get_crawler_for_url(category.url)
    if not crawler:
        return CrawlResult(errors=[f"No crawler for URL: {category.url}"])

    result = CrawlResult()

    async with httpx.AsyncClient(
        timeout=30.0,
        headers={"User-Agent": "NewsPlaylist/1.0"},
        follow_redirects=True,
    ) as client:
        try:
            resp = await client.get(category.url)
            resp.raise_for_status()
            listing_html = resp.text
        except httpx.HTTPError as e:
            return CrawlResult(errors=[f"Failed to fetch listing: {e}"])

        article_urls = crawler.parse_listing_page(listing_html)
        urls_to_fetch = article_urls[: settings.max_articles_per_category]
        result.total_found = len(urls_to_fetch)

        if not urls_to_fetch:
            result.errors.append("No article URLs found on listing page")
            return result

        for url in urls_to_fetch:
            try:
                _validate_crawl_url(url)
            except ValueError:
                result.errors.append(f"Skipped disallowed URL: {url}")
                continue

            try:
                await asyncio.sleep(settings.crawl_delay_seconds)
                resp = await client.get(url)
                resp.raise_for_status()
                article = crawler.parse_article_page(
                    resp.text, url, category.id
                )
                if article:
                    result.articles.append(article)
                else:
                    result.no_audio_count += 1
            except httpx.HTTPError as e:
                result.errors.append(f"Failed: {url}: {e}")

    return result


async def crawl_and_store(category: Category, db: AsyncSession) -> CrawlResult:
    result = await crawl_category(category)

    if result.articles:
        for article in result.articles:
            stmt = insert(Article).values(
                id=article.id,
                title=article.title,
                source=article.source,
                audio_url=article.audio_url,
                article_url=article.article_url,
                category_id=category.id,
                published_at=datetime.fromisoformat(article.published_at),
                crawled_at=datetime.now(timezone.utc),
            ).on_conflict_do_update(
                index_elements=["id"],
                set_={
                    "title": article.title,
                    "audio_url": article.audio_url,
                    "crawled_at": datetime.now(timezone.utc),
                },
            )
            await db.execute(stmt)
        await db.commit()

    logger.info(
        f"Crawled {category.id}: {len(result.articles)} articles, "
        f"{result.no_audio_count} no audio, {len(result.errors)} errors"
    )
    return result


async def refresh_all_categories() -> None:
    async with async_session() as db:
        stmt = select(Category)
        result = await db.execute(stmt)
        categories = result.scalars().all()

    for category in categories:
        async with async_session() as db:
            try:
                await crawl_and_store(category, db)
            except Exception as e:
                logger.error(f"Failed to refresh {category.id}: {e}")
