import re
from datetime import datetime
from urllib.parse import urlparse

from bs4 import BeautifulSoup

from app.crawlers.base import CrawledArticle, SourceCrawler


class DantriCrawler(SourceCrawler):
    def parse_listing_page(self, html: str) -> list[str]:
        soup = BeautifulSoup(html, "html.parser")
        urls: list[str] = []
        seen: set[str] = set()

        selectors = "article a[href], .article-item a[href], .news-item a[href]"
        links = soup.select(selectors)

        for link in links:
            href = link.get("href", "")
            if not href:
                continue

            url = href if href.startswith("http") else f"https://dantri.com.vn{href}"

            if ".htm" in url and "dantri.com.vn/" in url and url not in seen:
                parsed = urlparse(url)
                segments = [s for s in parsed.path.split("/") if s]
                if len(segments) >= 2:
                    seen.add(url)
                    urls.append(url)

        return urls

    def parse_article_page(
        self, html: str, article_url: str, category_id: str
    ) -> CrawledArticle | None:
        soup = BeautifulSoup(html, "html.parser")

        audio_el = soup.select_one("audio source[src], audio[src]")
        if not audio_el:
            return None

        audio_src = audio_el.get("src", "")
        if not audio_src:
            return None

        audio_url = (
            audio_src
            if audio_src.startswith("http")
            else f"https://dantri.com.vn{audio_src}"
        )

        title_el = soup.select_one("h1")
        if not title_el:
            return None
        title = title_el.get_text(strip=True)
        if not title:
            return None

        time_el = soup.select_one("time[datetime]")
        if time_el and time_el.get("datetime"):
            try:
                published_at = datetime.fromisoformat(
                    time_el["datetime"].replace("Z", "+00:00")
                )
            except ValueError:
                published_at = datetime.now()
        else:
            published_at = datetime.now()

        article_id = self._generate_id(article_url)

        return CrawledArticle(
            id=article_id,
            title=title,
            source="dantri",
            audio_url=audio_url,
            article_url=article_url,
            published_at=published_at.isoformat(),
        )

    def _generate_id(self, url: str) -> str:
        data = url.encode("utf-8")
        h = 0x811C9DC5
        for byte in data:
            h ^= byte
            h = (h * 0x01000193) & 0xFFFFFFFF
        return f"{h:08x}"
