---
type: seed
date: 2026-04-05
status: draft — needs 1B1 discussion
author: the-agency/jordan/captain
---

# Content Strategy — The Agency & AIADLC

## Context

Jordan is building The Agency (open-source AI agent framework) and developing the AIADLC methodology (AI-Augmented Development Lifecycle). Content serves three goals:

1. **Thought leadership** — establish Jordan as a voice on AI-augmented development, AI transformation, and multi-agent workflows
2. **Framework adoption** — drive developers to discover and adopt The Agency
3. **Book pipeline** — articles serve as drafts, explorations, and validations of ideas that may fold into the book on AIADLC

Content topics: Enforcement Triangle, Continual Improvement Loop, multi-agent review, quality gates, agent coordination, AI transformation strategy, developer experience with AI agents.

## Platforms & Their Audiences

### Where Jordan Already Has Presence

| Platform | Audience | Jordan's Status | Reach Model |
|----------|----------|----------------|-------------|
| **LinkedIn** | Enterprise, CTOs, engineering leaders, AI transformation buyers | Active, has network | Algorithmic feed — posts live ~48 hours, comments extend reach. Best for: thought leadership, AI transformation, methodology. |
| **X/Twitter** | Developers, AI researchers, indie hackers, Claude Code community | @AgencyGroupAI (new) | Algorithmic + follower timeline. Best for: developer patterns, hot takes, community engagement, linking to long-form. |
| **e27** | Southeast Asian tech ecosystem — founders, investors, enterprise tech leaders | Existing author, needs reactivation | Editorial platform — articles are published through their editorial process. Best for: AI transformation for APAC enterprise, bridge to SEA tech community. Regional reach that LinkedIn/X don't cover well. |

### Where Jordan Should Expand

| Platform | Audience | Why | Reach Model |
|----------|----------|-----|-------------|
| **Ghost blog (self-hosted)** | Canonical home — anyone via search | Own the URL, own the SEO, own the content. Every other platform links back here. | Search (long-tail SEO). Posts compound over months/years. Newsletter built-in. |
| **Reddit** | Developer communities (r/ClaudeAI, r/LocalLLaMA, r/programming, r/ExperiencedDevs) | Authentic developer discussion. Reddit threads surface in Google search. Community validates ideas. | Community voting. Best for: technical deep-dives, "here's what I learned" posts, linking to Ghost. |
| **Substack** | Newsletter subscribers, AI/tech readers | Secondary syndication for newsletter format. Some AI writers have large Substack audiences. | Email + Substack discovery. Not canonical — syndicate from Ghost with canonical URL. |
| **Threads** | Emerging, Meta's Twitter competitor | Low-effort cross-post from X. Growing audience, low competition. | Algorithmic. Too early to invest heavily, but free to cross-post. |

### Skip or Deprioritize

| Platform | Why Skip |
|----------|----------|
| **Medium** | No custom domain, dead API, declining developer audience, hostile content ownership terms. |
| **dev.to** | Good SEO amplifier but narrow audience. Cross-post from Ghost if easy, don't invest. |
| **Hacker News** | Not a publishing platform — submit Ghost links when content is strong. Community decides. |

## Content Types × Platform Fit

| Content Type | Primary Platform | Syndication |
|-------------|-----------------|-------------|
| **Long-form articles** (AIADLC methodology, patterns, deep dives) | Ghost (canonical) | e27, LinkedIn article, Substack, Reddit (link + summary) |
| **Short-form insights** (observations, patterns, reactions) | X/Twitter | LinkedIn post, Threads |
| **AI transformation / enterprise** | LinkedIn (native) | Ghost (expanded version), e27 |
| **Developer tutorials** (how-to, code patterns) | Ghost (canonical) | Reddit, dev.to |
| **Book draft chapters** | Ghost (canonical, possibly behind member wall) | — (not syndicated until published) |
| **Community engagement** (responses, threads, discussions) | X, Reddit | — |
| **APAC enterprise / SEA tech** | e27 | LinkedIn |

## The Ghost Blog — Canonical Home

**Domain:** TBD (options: `theagency.ai/blog`, `jordandm.com`, `aiadlc.com`, separate subdomain)

**Why Ghost:**
- Full Admin API — programmatic posting, scheduling, CRUD
- You own the domain, the content, the SEO, the subscriber list
- Built-in newsletter replaces Substack dependency
- MIT-licensed, self-hostable (~$6/mo VPS)
- Clean, fast, developer-respected
- RSS built-in for syndication

**What it is NOT:** A destination people browse. Nobody "reads Ghost." They find your posts via search, social, or newsletter. Ghost is the engine — your domain is the brand.

## Publishing Architecture

### Source of Truth

Markdown files in git. Written/edited in mdpal (when ready) or any editor. Stored in the-agency-content repo (private).

### Publishing Flow

```
Write (markdown in git)
  → Captain /publish skill
    → publish-ghost (canonical, returns URL)
    → publish-linkedin (adapted text + canonical link)
    → publish-x (thread or link + excerpt)
    → publish-reddit (subreddit + title + link)
    → publish-substack (syndication, canonical URL back to Ghost)
    → publish-e27 (manual or email — e27 has editorial process)
```

### Captain Tools

| Tool | Platform | API | Notes |
|------|----------|-----|-------|
| `publish-ghost` | Ghost | Admin API (JWT) | Full CRUD, scheduling, canonical |
| `publish-linkedin` | LinkedIn | Community Management API (OAuth) | Personal posts, text adaptation |
| `publish-x` | X/Twitter | v2 API (OAuth 2.0) | Thread splitting, pay-per-tweet ($0.01) |
| `publish-reddit` | Reddit | OAuth, 100 QPM | Subreddit targeting, link posts |
| `publish-substack` | Substack | Unofficial/fragile | Low priority — Ghost newsletter may replace |
| `analytics-pull` | All | Various | Stats → markdown summary in git |

**e27 is manual** — editorial platform with submission process. Captain can draft and remind, but publishing requires human submission.

### Content Adaptation

Each platform needs different formatting:

| Platform | Format | Adaptation |
|----------|--------|-----------|
| Ghost | HTML (from Markdown via pandoc/marked) | Full article, images, code blocks |
| LinkedIn | Plain text, limited bold | Strip headers, simplify formatting, ~1300 char for feed visibility |
| X/Twitter | 280 char threads | Thread splitter — key points as individual tweets, link to Ghost |
| Reddit | Plain text + link | Title + 2-3 paragraph summary + "full article at [link]" |
| Substack | HTML/rich text | Near-identical to Ghost, set canonical URL |
| e27 | Their CMS format | Rewrite for APAC enterprise audience — different framing, same insights |

## Reach Strategy — Not Just API

APIs get content onto platforms. **Reach** gets it in front of people. Different game.

### LinkedIn Reach Levers
- Post timing: weekday mornings (Tue–Thu, 7-9am target timezone)
- First comment strategy: add context in first comment to boost engagement
- Tag relevant people (sparingly, authentically)
- Engage on others' posts in the AI/dev space — reciprocity drives reach
- LinkedIn articles (long-form) vs LinkedIn posts (short-form) — posts get 10x the reach

### X/Twitter Reach Levers
- Consistent posting cadence (daily or near-daily)
- Quote-tweet and engage with AI/Claude community
- Curated follow/watch list (Boris, Anthropic, Claude AI, key developers)
- Threads outperform single tweets for technical content
- Pin a thread linking to Ghost blog

### Reddit Reach Levers
- Subreddit selection matters enormously — r/ClaudeAI, r/LocalLLaMA, r/programming, r/ExperiencedDevs
- Don't just drop links — write genuine summaries, engage in comments
- Reddit rewards authenticity and punishes self-promotion
- Build karma before posting your own content

### e27 Reach Levers
- Regular column/author status — consistency matters
- APAC-relevant framing (AI transformation for SEA enterprises, not just Silicon Valley perspective)
- Jordan's existing network and reputation in the region
- Cross-promote e27 articles on LinkedIn for SEA tech audience

### Ghost/SEO Reach Levers
- Long-tail keywords: "AI agent quality gate", "multi-agent code review", "Claude Code workflow"
- Internal linking between articles
- Technical depth = backlinks from developer communities
- Newsletter subscribers compound — every post reaches existing base + new search traffic

## Audience Segmentation

| Audience | They Care About | Reach Them Via |
|----------|----------------|---------------|
| **Developers using Claude Code** | Patterns, tools, skills, workflow tips | X, Reddit (r/ClaudeAI), Ghost (SEO) |
| **Engineering leaders** | AI transformation, team productivity, methodology | LinkedIn, e27, Ghost |
| **AI researchers / builders** | Architecture, multi-agent patterns, novel approaches | X, Ghost (deep dives), Reddit |
| **SEA tech ecosystem** | AI adoption, enterprise transformation, regional context | e27, LinkedIn |
| **Open source contributors** | Framework design, contribution guide, community | Ghost, GitHub, Reddit |

## Open Questions for Discussion

| # | Question |
|---|----------|
| 1 | **Ghost domain:** `theagency.ai/blog`, `jordandm.com`, `aiadlc.com`, or something else? Affects brand identity. |
| 2 | **e27 reactivation:** What's the submission/editorial process? Regular column or ad-hoc? |
| 3 | **Content repo:** Create the-agency-ai/the-agency-content now? Or wait until Ghost is up? |
| 4 | **Substack necessity:** Does Ghost's built-in newsletter eliminate the need for Substack entirely? |
| 5 | **X API cost:** $200/mo Basic tier or pay-per-use? Volume estimate needed. |
| 6 | **Reddit identity:** Post as Jordan personally or as @AgencyGroupAI? |
| 7 | **Book relationship:** Which articles are "public drafts" of book chapters vs standalone pieces? |
| 8 | **Publishing cadence:** What's sustainable? 1/week long-form + daily short-form? |
| 9 | **Content workstream:** Should this become a formal Agency workstream with its own agent? |
| 10 | **Threads:** Worth investing in, or just auto-cross-post from X? |

## Next Steps

1. 1B1 through the 10 open questions
2. Stand up Ghost (self-hosted, pick domain)
3. Create the-agency-content repo
4. Build `publish-ghost` tool (first platform adapter)
5. Reactivate e27 authorship
6. Build remaining platform adapters incrementally
