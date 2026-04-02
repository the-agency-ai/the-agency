---
allowed-tools: Read, Write, Bash(./claude/tools/crawl-*:*), Bash(./claude/tools/config:*), Bash(source */claude/tools/lib/_provider-resolve:*), WebFetch
description: Crawl and extract content from configured sites using the provider engine
---

# Crawl Sites

Crawl configured sites and extract structured content using the configured crawler engine.

## Arguments

- $ARGUMENTS: Optional flags:
  - `--site <name>` — crawl a specific configured site (default: all)
  - `--output <path>` — output directory for extracted content
  - `--dry-run` — show what would be crawled without executing
  - `--diff` — show changes since last crawl

## How to Execute

### Step 1: Resolve Provider

Read the crawl provider from `claude/config/agency.yaml` under `crawl.provider`.

```yaml
# agency.yaml
crawl:
  provider: "playwright"  # or "wget", "scrapy", "webfetch"
  sites:
    - name: "docs"
      url: "https://docs.example.com"
      patterns: ["/**/*.html"]
    - name: "blog"
      url: "https://blog.example.com"
      patterns: ["/posts/*"]
```

The provider maps to a tool: `./claude/tools/crawl-{provider}`

### Step 2: Check Provider Tool Exists

Verify `./claude/tools/crawl-{provider}` exists and is executable. If not:
- For `webfetch` provider: use the built-in WebFetch tool directly (no external tool needed)
- List available crawl tools: `ls ./claude/tools/crawl-*`
- Tell the user which providers are available

### Step 3: Read Site Configuration

Read the `crawl.sites` array from `agency.yaml`. Each site entry has:
- `name` — identifier for the site
- `url` — base URL to crawl
- `patterns` — URL patterns to include

If `--site` specified, filter to that site only.

### Step 4: Dispatch to Provider

For each site, execute: `./claude/tools/crawl-{provider} {url} {patterns} {output}`

Or for `webfetch` provider, use the WebFetch tool directly with each URL.

### Step 5: Report

Show the user:
- Pages crawled per site
- Content extracted (file count, total size)
- Any errors or skipped pages
- If `--diff`, show what changed since last crawl

## Provider Contract

Each `crawl-{provider}` tool must accept:
- Positional: base URL
- `--patterns` — comma-separated URL patterns
- `--output` — output directory
- `--dry-run` — list URLs without fetching

## Error Handling

- If no provider configured, default to `webfetch` (uses built-in WebFetch)
- If site config missing, suggest adding the `crawl.sites` section to agency.yaml
- Rate limit appropriately — respect robots.txt
- Report unreachable URLs without failing the entire crawl
