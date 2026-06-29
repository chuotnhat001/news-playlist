import "jsr:@supabase/functions-js/edge-runtime.d.ts";

const STORAGE_BASE = "https://zkzpdsijcpnrzczmlpfk.supabase.co/storage/v1/object/public/newsplaylist/web";

const INDEX_HTML = `<!DOCTYPE html><html><head>
  <base href="${STORAGE_BASE}/">
  <meta charset="UTF-8">
  <meta content="IE=Edge" http-equiv="X-UA-Compatible">
  <meta name="description" content="News Playlist - Vietnamese news audio">
  <meta name="mobile-web-app-capable" content="yes">
  <meta name="apple-mobile-web-app-status-bar-style" content="black">
  <meta name="apple-mobile-web-app-title" content="News Playlist">
  <link rel="apple-touch-icon" href="${STORAGE_BASE}/icons/Icon-192.png">
  <link rel="icon" type="image/png" href="${STORAGE_BASE}/favicon.png">
  <title>News Playlist</title>
  <link rel="manifest" href="${STORAGE_BASE}/manifest.json">
  <style>
    html { height: 100% }
    body { margin: 0; min-height: 100%; background-color: #1A1A2E; }
    .center { margin: 0; position: absolute; top: 50%; left: 50%; transform: translate(-50%, -50%); }
  </style>
  <script>
    function removeSplashFromWeb() {
      document.getElementById("splash")?.remove();
      document.body.style.background = "transparent";
    }
  </script>
  <meta content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no" name="viewport">
</head>
<body>
  <picture id="splash">
    <source srcset="${STORAGE_BASE}/splash/img/dark-1x.png" media="(prefers-color-scheme: dark)">
    <img class="center" aria-hidden="true" src="${STORAGE_BASE}/splash/img/light-1x.png" alt="">
  </picture>
  <script src="${STORAGE_BASE}/flutter_bootstrap.js" async></script>
</body></html>`;

Deno.serve((_req: Request) => {
  return new Response(INDEX_HTML, {
    status: 200,
    headers: {
      "Content-Type": "text/html; charset=utf-8",
      "Access-Control-Allow-Origin": "*",
      "Cache-Control": "no-cache",
      "X-Content-Type-Options": "nosniff",
    },
  });
});
