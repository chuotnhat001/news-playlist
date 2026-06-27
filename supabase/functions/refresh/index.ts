import { serve } from "https://deno.land/std@0.208.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.0";

const CORS_HEADERS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "GET, OPTIONS",
  "Access-Control-Allow-Headers": "Content-Type, Authorization, apikey",
  "Content-Type": "application/json",
};

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { headers: CORS_HEADERS });
  }

  if (req.method !== "GET") {
    return new Response(JSON.stringify({ error: "Method not allowed" }), {
      status: 405,
      headers: CORS_HEADERS,
    });
  }

  try {
    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const supabaseKey = Deno.env.get("SUPABASE_ANON_KEY") || Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
    const supabase = createClient(supabaseUrl, supabaseKey);

    const url = new URL(req.url);
    const categoryId = url.searchParams.get("category_id");

    if (categoryId) {
      const { data: category, error: catError } = await supabase
        .from("categories")
        .select("*")
        .eq("id", categoryId)
        .single();

      if (catError || !category) {
        return new Response(
          JSON.stringify({ error: "Category not found" }),
          { status: 404, headers: CORS_HEADERS }
        );
      }

      const { data: articles, error: artError } = await supabase
        .from("articles")
        .select("id, title, source, audio_url, article_url, published_at")
        .eq("category_id", categoryId)
        .order("published_at", { ascending: false })
        .limit(20);

      return new Response(
        JSON.stringify({ category, articles: articles || [] }),
        { headers: CORS_HEADERS }
      );
    }

    // Return all categories with article counts using a single RPC or joined query
    const { data: categories, error: catError } = await supabase
      .from("categories")
      .select("*");

    if (catError || !categories) {
      return new Response(
        JSON.stringify({ error: "Failed to fetch categories" }),
        { status: 500, headers: CORS_HEADERS }
      );
    }

    // Batch count: single query for all category counts
    const { data: counts } = await supabase
      .from("articles")
      .select("category_id")
      .in("category_id", categories.map((c) => c.id));

    const countMap: Record<string, number> = {};
    for (const row of counts || []) {
      countMap[row.category_id] = (countMap[row.category_id] || 0) + 1;
    }

    const result = categories.map((cat) => ({
      ...cat,
      article_count: countMap[cat.id] || 0,
    }));

    return new Response(JSON.stringify(result), { headers: CORS_HEADERS });
  } catch (e) {
    return new Response(
      JSON.stringify({ error: String(e) }),
      { status: 500, headers: CORS_HEADERS }
    );
  }
});
