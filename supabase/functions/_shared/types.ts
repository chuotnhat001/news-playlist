// Shared types for Edge Functions
export interface CrawledArticle {
  id: string;
  title: string;
  source: string;
  audio_url: string;
  article_url: string;
  published_at: string;
}

export interface CrawlResult {
  articles: CrawledArticle[];
  errors: string[];
  total_found: number;
  no_audio_count: number;
}

export interface Category {
  id: string;
  name: string;
  url: string;
  source: string;
}
