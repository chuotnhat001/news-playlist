import { serve } from "https://deno.land/std@0.208.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.0";
import {
  parseSohaListing,
  parseSohaArticle,
  parseTuoitreListing,
  parseTuoitreArticle,
  parseDantriListing,
  parseDantriArticle,
  validateCrawlUrl,
} from "../_shared/crawlers.ts";
import { Category, CrawlResult, CrawledArticle } from "../_shared/types.ts";

const CRAWL_DELAY_MS = 300;
const MAX_ARTICLES = 15;

async function crawlCategory(category: Category): Promise<CrawlResult> {
  validateCrawlUrl(category.url);

  const result: CrawlResult = {
    articles: [],
    errors: [],
    total_found: 0,
    no_audio_count: 0,
  };

  let parseListing: (html: string) => string[];
  let parseArticle: (html: string, url: string, catId: string) => CrawledArticle | null;

  switch (category.source) {
    case "soha":
      parseListing = parseSohaListing;
      parseArticle = parseSohaArticle;
      break;
    case "tuoitre":
      parseListing = parseTuoitreListing;
      parseArticle = parseTuoitreArticle;
      break;
    case "dantri":
      parseListing = parseDantriListing;
      parseArticle = parseDantriArticle;
      break;
    default:
      return { ...result, errors: [`Unknown source: ${category.source}`] };
  }

  let listingHtml: string;
  try {
    const resp = await fetch(category.url, {
      headers: { "User-Agent": "NewsPlaylist/1.0" },
    });
    if (!resp.ok) throw new Error(`HTTP ${resp.status}`);
    listingHtml = await resp.text();
  } catch (e) {
    return { ...result, errors: [`Failed to fetch listing: ${e}`] };
  }

  const articleUrls = parseListing(listingHtml).slice(0, MAX_ARTICLES);
  result.total_found = articleUrls.length;

  if (articleUrls.length === 0) {
    result.errors.push("No article URLs found on listing page");
    return result;
  }

  for (const url of articleUrls) {
    try {
      validateCrawlUrl(url);
    } catch {
      result.errors.push(`Skipped disallowed URL: ${url}`);
      continue;
    }

    try {
      await new Promise((r) => setTimeout(r, CRAWL_DELAY_MS));
      const resp = await fetch(url, {
        headers: { "User-Agent": "NewsPlaylist/1.0" },
      });
      if (!resp.ok) throw new Error(`HTTP ${resp.status}`);
      const html = await resp.text();

      const article = parseArticle(html, url, category.id);
      if (article) {
        result.articles.push(article);
      } else {
        result.no_audio_count++;
      }
    } catch (e) {
      result.errors.push(`Failed: ${url}: ${e}`);
    }
  }

  return result;
}

serve(async (req) => {
  try {
    if (req.method === "OPTIONS") {
      return new Response(null, {
        headers: {
          "Access-Control-Allow-Origin": "*",
          "Access-Control-Allow-Methods": "POST, OPTIONS",
          "Access-Control-Allow-Headers": "Content-Type, Authorization, x-api-key",
        },
      });
    }

    if (req.method !== "POST") {
      return new Response(JSON.stringify({ error: "Method not allowed" }), {
        status: 405,
        headers: { "Content-Type": "application/json" },
      });
    }

    const apiKey = req.headers.get("x-api-key");
    const expectedKey = Deno.env.get("API_KEY");
    if (expectedKey && apiKey !== expectedKey) {
      return new Response(JSON.stringify({ error: "Unauthorized" }), {
        status: 401,
        headers: { "Content-Type": "application/json" },
      });
    }

    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const supabaseKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
    const supabase = createClient(supabaseUrl, supabaseKey);

    let category_id: string | undefined;
    try {
      const body = await req.json();
      category_id = body.category_id;
    } catch {
      // Empty body = crawl all categories
    }

    let categories: Category[];
    if (category_id) {
      const { data, error } = await supabase
        .from("categories")
        .select("*")
        .eq("id", category_id);
      if (error) throw error;
      categories = data || [];
    } else {
      const { data, error } = await supabase.from("categories").select("*");
      if (error) throw error;
      categories = data || [];
    }

    if (categories.length === 0) {
      return new Response(
        JSON.stringify({ error: "Category not found" }),
        { status: 404, headers: { "Content-Type": "application/json" } }
      );
    }

    const results: Record<string, CrawlResult> = {};

    for (const category of categories) {
      const result = await crawlCategory(category);
      results[category.id] = result;

      if (result.articles.length > 0) {
        const rows = result.articles.map((a) => ({
          id: a.id,
          title: a.title,
          source: a.source,
          audio_url: a.audio_url,
          article_url: a.article_url,
          category_id: category.id,
          published_at: a.published_at,
          crawled_at: new Date().toISOString(),
        }));

        const { error: upsertError } = await supabase
          .from("articles")
          .upsert(rows, { onConflict: "id" });

        if (upsertError) {
          results[category.id].errors.push(`DB upsert failed: ${upsertError.message}`);
        }
      }

      await supabase
        .from("categories")
        .update({ last_crawled_at: new Date().toISOString() })
        .eq("id", category.id);
    }

    return new Response(JSON.stringify({ results }), {
      status: 200,
      headers: {
        "Content-Type": "application/json",
        "Access-Control-Allow-Origin": "*",
      },
    });
  } catch (e) {
    return new Response(
      JSON.stringify({ error: String(e) }),
      { status: 500, headers: { "Content-Type": "application/json" } }
    );
  }
});
