# Crawl Brief: martinfowler.com for AIADLC Research

## The Problem That Prompted This

We're writing a conference paper (AIADLC — AI Augmented Development Life Cycle) that examines which software development principles survive, transform, or die in AI augmented development. Martin Fowler's blog is a primary reference — 20+ years of foundational writing on refactoring, CI/CD, evolutionary design, testing, team organization, and agile process.

The captain agent dispatched a background research agent to crawl Fowler's blog. The agent successfully fetched 8 tag index pages and extracted ~200 article links. Then it tried to read the individual articles and got blocked — all three approaches (WebFetch, curl, /crawl-sites) were denied by Claude Code's permission system. The agent was making rapid sequential requests, which looked like a bot crawl.

The captain then fetched 9 key articles manually from the main thread (WebFetch worked there — different permission context). But we need ~26 priority articles plus ideally the full site content as a local reference.

**We need a "safe crawl" tool that respects the target site and doesn't trigger rate limits or permission blocks.**

## The "Safe Crawl" Concept

A crawl tool designed for research use against sites we respect. Not a scraper — a careful, slow reader.

**Core principles:**

- **No simultaneous requests.** Ever. One request at a time, sequentially.
- **10-second minimum between requests.** Configurable, but default to polite.
- **Identify honestly.** User-agent should say what we are, not pretend to be a browser.
- **Respect robots.txt.** Check it first, honor disallow rules.
- **Back off on errors.** 429 → wait 60 seconds. 403 → try Chrome/Playwright fallback. 5xx → wait and retry once.
- **Resume-capable.** If interrupted, pick up where we left off based on what's already saved to disk.
- **Save as we go.** Each page saved immediately after fetch — don't accumulate in memory.

**Fallback chain:**

1. `curl` with honest user-agent → if blocked:
2. `WebFetch` tool → if blocked:
3. Chrome/Playwright (renders JavaScript, looks like a real browser)

**This should become a reusable tool** — not just for Fowler's blog. Any time we need to build a local reference from a website for research, we use the safe crawl. It's the polite alternative to our existing `/crawl-sites` which is designed for bulk auditing.

## Scope: Two Passes

### Pass 1: Priority Articles (26 specific URLs)

Fetch these specific articles. These are the ones directly relevant to the AIADLC paper.

**Priority 1 (already summarized by captain — get full text):**

1. https://martinfowler.com/articles/continuousIntegration.html
2. https://martinfowler.com/articles/workflowsOfRefactoring/
3. https://martinfowler.com/bliki/DesignStaminaHypothesis.html
4. https://martinfowler.com/articles/newMethodology.html
5. https://martinfowler.com/articles/designDead.html
6. https://martinfowler.com/bliki/OpportunisticRefactoring.html
7. https://martinfowler.com/bliki/TechnicalDebtQuadrant.html
8. https://martinfowler.com/articles/practical-test-pyramid.html
9. https://martinfowler.com/articles/agileFluency.html

**Priority 2 (not yet read):** 10. https://martinfowler.com/bliki/ContinuousDelivery.html 11. https://martinfowler.com/articles/branching-patterns.html 12. https://martinfowler.com/articles/feature-toggles.html 13. https://martinfowler.com/bliki/BranchByAbstraction.html 14. https://martinfowler.com/articles/microservice-testing/ 15. https://martinfowler.com/articles/2021-test-shapes.html 16. https://martinfowler.com/bliki/CodeSmell.html 17. https://martinfowler.com/bliki/TechnicalDebt.html 18. https://martinfowler.com/articles/on-pair-programming.html 19. https://martinfowler.com/bliki/ExtremeProgramming.html 20. https://martinfowler.com/bliki/StranglerFigApplication.html 21. https://martinfowler.com/bliki/TeamTopologies.html 22. https://martinfowler.com/bliki/MonolithFirst.html 23. https://martinfowler.com/articles/class-too-large.html

**Priority 3:** 24. https://martinfowler.com/articles/evo-arch-forward.html 25. https://martinfowler.com/bliki/ArchitectureDecisionRecord.html 26. https://martinfowler.com/articles/break-monolith-into-microservices.html

### Pass 2: Full Site

After priority articles are saved, crawl the entire martinfowler.com site:

- Start from the tag index pages and sitemap
- Follow internal links to discover all articles, bliki entries, and guides
- Same safe-crawl rules: one request at a time, 10-second gaps, save as we go
- This will take hours — that's fine. Run it in the background.
- The result is a complete local mirror of Fowler's writing as a searchable reference.

## Output Format

Save each article as a separate markdown file in `usr/jordan/conference/references/fowler-articles/`:

```markdown
# {Title}

**URL:** {url}
**Author:** Martin Fowler (+ co-authors if any)
**Date:** {publication date if available}
**Topics:** {comma-separated tags}

## Summary

{One paragraph summary of key argument}

## Full Text

{Article content converted to markdown}
```

Create an index file `fowler-articles/INDEX.md`:

```markdown
| #   | Title                  | URL           | Topics      | Date | Summary |
| --- | ---------------------- | ------------- | ----------- | ---- | ------- |
| 1   | Continuous Integration | /articles/... | CI, testing | 2006 | ...     |
```

## Safe Crawl Tool

This brief should also serve as the seed for building a reusable `/safe-crawl` tool. Requirements:

- Input: list of URLs (file or inline) OR a root URL + "discover all pages"
- Rate: configurable, default 10 seconds between requests
- Concurrency: 1 (no parallel requests, ever)
- Fallback: curl → WebFetch → Chrome/Playwright
- Robots.txt: check and respect
- Resume: skip URLs already saved to output directory
- Output: one markdown file per page + index file
- Progress: report every N pages (default 10)
- Error handling: log failures, continue to next URL, retry once after backoff
