import re
from datetime import datetime
from urllib.parse import urljoin

from bs4 import BeautifulSoup

from app.crawlers.base import CrawledArticle, SourceCrawler


class SohaCrawler(SourceCrawler):
    def parse_listing_page(self, html: str) -> list[str]:
        soup = BeautifulSoup(html, "html.parser")
        urls: list[str] = []
        seen: set[str] = set()

        selectors = ".news-item a[href], .item-news a[href], article a[href], .list-news a[href]"
        links = soup.select(selectors)

        for link in links:
            href = link.get("href", "")
            if not href:
                continue

            url = href if href.startswith("http") else f"https://soha.vn{href}"

            if ".htm" in url and "soha.vn/" in url and url not in seen:
                path = url.split("soha.vn")[-1] if "soha.vn" in url else ""
                if len(path) > 5 and re.search(r"\d+\.htm$", path):
                    seen.add(url)
                    urls.append(url)

        return urls

    def parse_article_page(
        self, html: str, article_url: str, category_id: str
    ) -> CrawledArticle | None:
        soup = BeautifulSoup(html, "html.parser")

        audio_url = self._extract_audio_url(html)
        if not audio_url:
            return None

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
            source="soha",
            audio_url=audio_url,
            article_url=article_url,
            published_at=published_at.isoformat(),
        )

    def _extract_audio_url(self, html: str) -> str | None:
        tts_match = re.search(r"embedTTS\.init\(\s*\{([^}]+)\}", html)
        if tts_match:
            block = tts_match.group(1)
            news_id = self._extract_js_field(block, "newsId")
            date = self._extract_js_field(block, "distributionDate")
            namespace = self._extract_js_field(block, "nameSpace") or "sohanews"
            ext = self._extract_js_field(block, "ext") or "m4a"
            voice = "nu"

            if news_id and date:
                return f"https://tts.mediacdn.vn/{date}/{namespace}-{voice}-{news_id}.{ext}"

        audio_match = re.search(r'<(?:audio|source)[^>]+src="([^"]+)"', html)
        if audio_match:
            src = audio_match.group(1)
            if src:
                return src if src.startswith("http") else f"https://soha.vn{src}"

        return None

    def _extract_js_field(self, block: str, field: str) -> str | None:
        pattern = rf"{re.escape(field)}\s*:\s*[\"']([^\"']+)[\"']"
        match = re.search(pattern, block)
        return match.group(1) if match else None

    def _generate_id(self, url: str) -> str:
        data = url.encode("utf-8")
        h = 0x811C9DC5
        for byte in data:
            h ^= byte
            h = (h * 0x01000193) & 0xFFFFFFFF
        return f"{h:08x}"
