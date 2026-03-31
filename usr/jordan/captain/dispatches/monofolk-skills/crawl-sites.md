---
allowed-tools: mcp__plugin_playwright_playwright__browser_navigate, mcp__plugin_playwright_playwright__browser_snapshot, mcp__plugin_playwright_playwright__browser_take_screenshot, Write, Glob, Grep, Bash(mkdir:*)
description: Batch-crawl URLs with Playwright and extract structured content summaries
---

# /crawl-sites

Crawl a list of URLs using Playwright and produce structured content summaries instead of raw accessibility trees.

## Arguments

`$ARGUMENTS` contains one or more URLs (space-separated or newline-separated), plus optional flags:

- `--output <path>` — output file (default: `docs/research/site-audit.json`)
- `--max-pages <N>` — maximum pages to crawl (default: 20)

## Steps

1. **Parse arguments** — extract URLs and flags from `$ARGUMENTS`.

2. **Create output directory** if it doesn't exist:

   ```
   mkdir -p docs/research/
   ```

3. **For each URL**, use Playwright to navigate and extract structured content:

   a. Navigate: use `browser_navigate` with the URL
   b. Take a snapshot: use `browser_snapshot` to get the page structure
   c. Extract from the snapshot (do NOT return raw accessibility tree to conversation):
   - Page title (`<title>`)
   - Meta description
   - Page type (home, product, blog, landing — infer from URL + content)
   - Heading hierarchy (h1-h3)
   - Navigation structure (top-level nav items with links)
   - CTAs (buttons and links with action verbs)
   - Content sections (major landmarks/sections)
   - Open Graph tags if present
     d. Build a compact JSON record for this page

4. **Compile results** into a single JSON array:

   ```json
   [
     {
       "url": "https://example.com",
       "title": "Example Site",
       "meta_description": "...",
       "page_type": "homepage",
       "headings": ["h1: Welcome", "h2: Products", "h2: About"],
       "navigation": [{"text": "Home", "href": "/"}, ...],
       "ctas": [{"text": "Get Started", "href": "/signup"}],
       "sections": ["hero", "product_grid", "testimonials", "footer"],
       "og_tags": {"og:title": "...", "og:image": "..."}
     }
   ]
   ```

5. **Write output** to the specified path (default `docs/research/site-audit.json`).

6. **Return a compact summary** to the conversation (not the full JSON):
   - Total pages crawled
   - Page types found
   - Common patterns across pages
   - Any errors (pages that failed to load)

## Guidelines

- Extract structured data — do NOT dump raw Playwright snapshots into the conversation
- Keep each page record compact (no raw HTML or accessibility tree content)
- If a page fails to load, log the error and continue to the next URL
- Respect --max-pages to avoid runaway crawling
- The output JSON is the artifact — the conversation summary is for context only
