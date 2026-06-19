# Spike Results: Audio Crawl Feasibility

## Date: 2026-06-20

## Summary

| Source | Audio Available | Method | Accessible | Legal |
|--------|----------------|--------|------------|-------|
| Soha.vn | YES (TTS) | CDN pattern | Open (CORS *) | robots.txt allows all |
| Dan Tri | NO | N/A | N/A | N/A |

## Soha.vn — FEASIBLE

### Audio URL Pattern
```
https://tts.mediacdn.vn/{yyyy/MM/dd}/{namespace}-{voice}-{newsId}.{ext}
```

### Example
```
https://tts.mediacdn.vn/2026/06/20/sohanews-nu-198260611101056003.m4a
```

### Available Voices
| Voice ID | Description |
|----------|-------------|
| `nu` | Female, Northern Vietnamese |
| `nam` | Male, Northern Vietnamese |
| `nu-1` | Female, Southern Vietnamese |
| `nam-1` | Male, Southern Vietnamese |

### Access
- No auth required
- No hotlink protection
- `Access-Control-Allow-Origin: *`
- Supports Range requests (HTTP 206)
- CDN: Bizfly Cloud (VCCloud)

### Extraction Method
1. Fetch article page HTML
2. Parse `embedTTS.init({...})` JavaScript block
3. Extract: `newsId`, `distributionDate`, `nameSpace`, `ext`
4. Construct URL: `https://tts.mediacdn.vn/{date}/{namespace}-{voice}-{newsId}.{ext}`

### robots.txt
```
User-agent: *
Allow: /
```
No restrictions.

## Dan Tri (dantri.com.vn) — NOT FEASIBLE (no native audio)

### Findings
- No audio/podcast section exists (all podcast URLs return 404)
- No `<audio>` elements in article pages
- CSS class `.dt-audio` exists but is unused (feature not yet live)
- WordPress JSON API is disabled/blocked

### Alternative Approach
Dan Tri content can still be used via external TTS:
1. Crawl text content (allowed per robots.txt with `Crawl-delay: 1s`)
2. Generate audio using Vietnamese TTS (Vbee, FPT.AI, Google Cloud TTS)
3. Store generated audio locally

### robots.txt Restrictions
- `Crawl-delay: 1` for AI bots
- Block: `/wp-json/`, `/print-*.htm`, search pages
- **Article content is NOT blocked**

## Decision

**MVP Strategy:**
- Use Soha.vn as primary source (native TTS audio available)
- Dan Tri deferred to post-MVP (requires external TTS integration)
- Update crawlers accordingly: SohaCrawler needs to parse `embedTTS.init()` JS block

## Impact on Architecture
- SohaCrawler needs update: extract audio URL from JS block instead of `<audio>` tag
- DantriCrawler can be kept as-is structurally but will return 0 articles until TTS is added
- ContentService categories should prioritize Soha
- Consider adding a TTS service interface for future Dan Tri support
