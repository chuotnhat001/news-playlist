import { DOMParser, Element } from "https://deno.land/x/deno_dom@v0.1.48/deno-dom-wasm.ts";
import { CrawledArticle } from "./types.ts";

const ALLOWED_HOSTS = new Set([
  "soha.vn", "www.soha.vn",
  "tuoitre.vn", "www.tuoitre.vn",
  "dantri.com.vn", "www.dantri.com.vn",
]);

export function validateCrawlUrl(url: string): void {
  const parsed = new URL(url);
  if (parsed.protocol !== "https:") {
    throw new Error(`Only HTTPS allowed: ${url}`);
  }
  const host = parsed.hostname;
  const isAllowed = [...ALLOWED_HOSTS].some(
    (h) => host === h || host.endsWith(`.${h}`)
  );
  if (!isAllowed) {
    throw new Error(`Disallowed host: ${host}`);
  }
}

function generateId(url: string): string {
  const bytes = new TextEncoder().encode(url);
  let hash = 0x811c9dc5;
  for (const byte of bytes) {
    hash ^= byte;
    hash = Math.imul(hash, 0x01000193) >>> 0;
  }
  return hash.toString(16).padStart(8, "0");
}

// --- Shared TTS extraction (works for Soha + Tuoi Tre) ---

function extractJsField(block: string, field: string): string | null {
  const pattern = new RegExp(`${field}\\s*:\\s*["']([^"']+)["']`);
  const match = block.match(pattern);
  return match ? match[1] : null;
}

function extractTtsAudioUrl(html: string): string | null {
  const ttsMatch = html.match(/embedTTS\.init\(\s*\{([^}]+)\}/);
  if (ttsMatch) {
    const block = ttsMatch[1];
    const newsId = extractJsField(block, "newsId");
    const date = extractJsField(block, "distributionDate");
    const namespace = extractJsField(block, "nameSpace") || "sohanews";
    const ext = extractJsField(block, "ext") || "m4a";
    const voice = extractJsField(block, "defaultVoice") || "nu";

    if (newsId && date) {
      return `https://tts.mediacdn.vn/${date}/${namespace}-${voice}-${newsId}.${ext}`;
    }
  }

  const audioMatch = html.match(/<(?:audio|source)[^>]+src="([^"]+)"/);
  if (audioMatch) {
    const src = audioMatch[1];
    if (src.startsWith("http")) return src;
  }

  return null;
}

// --- Soha Crawler ---

export function parseSohaListing(html: string): string[] {
  const doc = new DOMParser().parseFromString(html, "text/html");
  if (!doc) return [];

  const urls: string[] = [];
  const seen = new Set<string>();

  const links = doc.querySelectorAll(
    ".news-item a[href], .item-news a[href], article a[href], .list-news a[href]"
  );

  for (const link of links) {
    const href = (link as Element).getAttribute("href");
    if (!href) continue;

    const url = href.startsWith("http") ? href : `https://soha.vn${href}`;

    if (url.includes(".htm") && url.includes("soha.vn/") && !seen.has(url)) {
      const path = url.split("soha.vn")[1] || "";
      if (path.length > 5 && /\d+\.htm$/.test(path)) {
        seen.add(url);
        urls.push(url);
      }
    }
  }

  return urls;
}

export function parseSohaArticle(
  html: string,
  articleUrl: string,
  categoryId: string
): CrawledArticle | null {
  const audioUrl = extractTtsAudioUrl(html);
  if (!audioUrl) return null;

  const doc = new DOMParser().parseFromString(html, "text/html");
  if (!doc) return null;

  const titleEl = doc.querySelector("h1");
  if (!titleEl) return null;
  const title = titleEl.textContent?.trim();
  if (!title) return null;

  const timeEl = doc.querySelector("time[datetime]");
  let publishedAt = new Date().toISOString();
  if (timeEl) {
    const datetime = (timeEl as Element).getAttribute("datetime");
    if (datetime) {
      try {
        publishedAt = new Date(datetime).toISOString();
      } catch { /* use default */ }
    }
  }

  return {
    id: generateId(articleUrl),
    title,
    source: "soha",
    audio_url: audioUrl,
    article_url: articleUrl,
    published_at: publishedAt,
  };
}

// --- Tuoi Tre Crawler ---

export function parseTuoitreListing(html: string): string[] {
  const doc = new DOMParser().parseFromString(html, "text/html");
  if (!doc) return [];

  const urls: string[] = [];
  const seen = new Set<string>();

  const links = doc.querySelectorAll(
    "a[href]"
  );

  for (const link of links) {
    const href = (link as Element).getAttribute("href");
    if (!href) continue;

    const url = href.startsWith("http") ? href : `https://tuoitre.vn${href}`;

    if (url.includes(".htm") && url.includes("tuoitre.vn/") && !seen.has(url)) {
      if (/\d{10,}\.htm$/.test(url)) {
        seen.add(url);
        urls.push(url);
      }
    }
  }

  return urls;
}

export function parseTuoitreArticle(
  html: string,
  articleUrl: string,
  categoryId: string
): CrawledArticle | null {
  const audioUrl = extractTtsAudioUrl(html);
  if (!audioUrl) return null;

  const doc = new DOMParser().parseFromString(html, "text/html");
  if (!doc) return null;

  const titleEl = doc.querySelector("h1");
  if (!titleEl) return null;
  const title = titleEl.textContent?.trim();
  if (!title) return null;

  const timeEl = doc.querySelector("time[datetime]");
  let publishedAt = new Date().toISOString();
  if (timeEl) {
    const datetime = (timeEl as Element).getAttribute("datetime");
    if (datetime) {
      try {
        publishedAt = new Date(datetime).toISOString();
      } catch { /* use default */ }
    }
  }

  return {
    id: generateId(articleUrl),
    title,
    source: "tuoitre",
    audio_url: audioUrl,
    article_url: articleUrl,
    published_at: publishedAt,
  };
}

// --- Dantri Crawler ---

export function parseDantriListing(html: string): string[] {
  const doc = new DOMParser().parseFromString(html, "text/html");
  if (!doc) return [];

  const urls: string[] = [];
  const seen = new Set<string>();

  const links = doc.querySelectorAll(
    "article a[href], .article-item a[href], .news-item a[href]"
  );

  for (const link of links) {
    const href = (link as Element).getAttribute("href");
    if (!href) continue;

    const url = href.startsWith("http")
      ? href
      : `https://dantri.com.vn${href}`;

    if (url.includes(".htm") && url.includes("dantri.com.vn/") && !seen.has(url)) {
      try {
        const parsed = new URL(url);
        const segments = parsed.pathname.split("/").filter(Boolean);
        if (segments.length >= 2) {
          seen.add(url);
          urls.push(url);
        }
      } catch { /* skip invalid URLs */ }
    }
  }

  return urls;
}

export function parseDantriArticle(
  html: string,
  articleUrl: string,
  categoryId: string
): CrawledArticle | null {
  const audioUrl = extractTtsAudioUrl(html);
  if (audioUrl) {
    const doc = new DOMParser().parseFromString(html, "text/html");
    if (!doc) return null;

    const titleEl = doc.querySelector("h1");
    if (!titleEl) return null;
    const title = titleEl.textContent?.trim();
    if (!title) return null;

    const timeEl = doc.querySelector("time[datetime]");
    let publishedAt = new Date().toISOString();
    if (timeEl) {
      const datetime = (timeEl as Element).getAttribute("datetime");
      if (datetime) {
        try {
          publishedAt = new Date(datetime).toISOString();
        } catch { /* use default */ }
      }
    }

    return {
      id: generateId(articleUrl),
      title,
      source: "dantri",
      audio_url: audioUrl,
      article_url: articleUrl,
      published_at: publishedAt,
    };
  }

  return null;
}
