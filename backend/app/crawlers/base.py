from abc import ABC, abstractmethod
from dataclasses import dataclass, field


@dataclass
class CrawledArticle:
    id: str
    title: str
    source: str
    audio_url: str
    article_url: str
    published_at: str  # ISO format


@dataclass
class CrawlResult:
    articles: list[CrawledArticle] = field(default_factory=list)
    errors: list[str] = field(default_factory=list)
    total_found: int = 0
    no_audio_count: int = 0


class SourceCrawler(ABC):
    @abstractmethod
    def parse_listing_page(self, html: str) -> list[str]:
        pass

    @abstractmethod
    def parse_article_page(
        self, html: str, article_url: str, category_id: str
    ) -> CrawledArticle | None:
        pass
