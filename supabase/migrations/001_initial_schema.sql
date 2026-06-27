-- Categories table
CREATE TABLE IF NOT EXISTS categories (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  url TEXT NOT NULL,
  source TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  last_crawled_at TIMESTAMPTZ
);

-- Articles table
CREATE TABLE IF NOT EXISTS articles (
  id TEXT PRIMARY KEY,
  title TEXT NOT NULL,
  source TEXT NOT NULL,
  audio_url TEXT NOT NULL,
  article_url TEXT NOT NULL,
  category_id TEXT NOT NULL REFERENCES categories(id) ON DELETE CASCADE,
  published_at TIMESTAMPTZ NOT NULL,
  crawled_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_articles_category_id ON articles(category_id);
CREATE INDEX IF NOT EXISTS idx_articles_published_at ON articles(published_at DESC);

-- Seed default categories
INSERT INTO categories (id, name, url, source) VALUES
  ('soha_quoc-te', 'Quốc Tế (Soha)', 'https://soha.vn/quoc-te.htm', 'soha'),
  ('tuoitre_the-gioi', 'Thế Giới (Tuổi Trẻ)', 'https://tuoitre.vn/the-gioi.htm', 'tuoitre'),
  ('soha_cong-nghe', 'Công Nghệ (Soha)', 'https://soha.vn/cong-nghe.htm', 'soha')
ON CONFLICT (id) DO NOTHING;
