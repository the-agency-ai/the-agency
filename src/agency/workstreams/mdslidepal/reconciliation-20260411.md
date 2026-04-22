---
type: reconciliation-receipt
workstream: mdslidepal
date: 2026-04-11
captain: the-agency/jordan/captain
principal: jordan
contract: seed-mdslidepal-contract-20260411.md (v1.3)
plans_reconciled:
  - plan-mdslidepal-web-20260411.md
  - plan-mdslidepal-mac-20260411.md
status: approved
---

# Reconciliation Receipt — mdslidepal Web + Mac Plans

## Summary

Two independent planning agents (mdslidepal-web and mdslidepal-mac) produced PVR + A&D + Plan documents against the shared contract at `seed-mdslidepal-contract-20260411.md` (v1.2). Both plans returned within a single captain session on 2026-04-11. Captain reviewed both plans, identified four collaborative decisions, and resolved them 1B1 with the principal. Contract updated to v1.3 with the resolutions baked in. Both plans are **approved to proceed**.

## Alignment

Both plans agree on:

- Contract v1.2 (now v1.3) as the shared interface
- Shared theme JSON files at `themes/agency-default.json`, `themes/agency-dark.json`, `themes/theme-schema.json` as the single source of truth
- Aspect ratio: 16:9, logical 1920×1080
- Offline-first: no CDN dependencies on either side
- 8-fixture corpus at `fixtures/` as acceptance criteria
- Valueflow PVR + A&D + Plan structure

## Scope asymmetry (planned and correct)

| Feature | Web MVP | Mac MVP |
|---|---|---|
| Themes | `agency-default` only | Both themes |
| YAML front-matter | Deferred to Phase 2 | Full support |
| Per-slide `<!-- slide: -->` metadata | Deferred | YAML 1.2 block style |
| Speaker notes | Deferred (single display assumed) | Full presenter view with multi-display |
| PDF export | Phase 2 | MVP (Phase 4 of 5) |
| `render` / `export` commands | Phase 2 | MVP (menu items) |
| Fixtures in scope | 01, 02, 03, 04, 05, 08 | All 8 |

Web is a ~6-hour Saturday sprint wrapping reveal.js, targeting a Monday workshop deadline. Mac is a properly-phased ~18-working-day Valueflow plan with no deadline pressure. Both correct for their constraints.

## Tech stack

### Web (locked)
- Node 20+ / TypeScript / pnpm
- reveal.js 5.2.x (vendored from Plan B, no CDN)
- `sirv` for static serving, `open` for browser launch
- Raw `process.argv` (no CLI framework)
- **Regex pre-processor** for fixture 08 edge cases (Decision 1, ~50 lines)

### Mac (locked)
- SwiftUI-first + AppKit interop for multi-display presenter mode (~150 LOC of interop)
- `swift-markdown` (Apple, cmark-gfm-backed) — Ink and MarkdownUI explicitly disqualified
- `HighlightSwift` for syntax highlighting — Highlightr explicitly disqualified
- `Yams` for YAML front-matter
- `PDFKit` + SwiftUI `ImageRenderer` for PDF export
- SPM-managed, macOS 14+ target
- AST-based slide detection (walking swift-markdown's `document.children` for top-level `ThematicBreak` nodes)

## Collaborative decisions resolved 1B1

### Decision 1 — Fixture 08 strictness for web Iteration 1: **Option B**

reveal.js's native markdown plugin uses a regex splitter, not AST-based detection. Without intervention, this would cause web to diverge from Mac on fixture 08's strict edge cases (adjacent `---` collapsing, trailing `---` phantom slide).

**Resolution:** Web Iteration 1 includes a ~50-line regex pre-processor that runs BEFORE reveal.js sees the content, collapsing empty-slide sequences and stripping trailing separators (while respecting fenced code blocks). ~30 minutes of Saturday work. Web and Mac reconcile cleanly at Iteration 1.

**Rationale:** The 30-minute Saturday cost is trivial compared to shipping a divergent MVP and documenting a "known gap" we'd have to fix in Phase 2 anyway. Closing the gap now produces a clean story and a clean reconciliation.

### Decision 2 — License: **RSL**

Contract v1.2 had MIT. Mac agent correctly flagged this against the existing app-workstream precedent (`mdpal-app` and `mock-and-mark` are both RSL, not MIT).

**Resolution:** mdslidepal ships under Reference Source License (RSL), matching the app-workstream precedent. Both `apps/mdslidepal-web/` and `apps/mdslidepal-mac/` carry per-directory RSL LICENSE files.

**Rationale:** The principal's call. mdslidepal is categorically an app (not a framework tool), so it joins the app-workstream RSL bucket. Captain's initial lean toward MIT was overruled by consistency with existing repo conventions.

### Decision 3 — File layout: **workstream + apps/ split**

Captain initially proposed several options but eventually recognized this wasn't a choice between alternatives — it was a misunderstanding of how workstreams and source trees relate in this repo. The principal clarified:

> "Workstream and source trees are different. One is how we manage things vs. where we put our source."

**Resolution:** Two different kinds of things, two different loci.

- **Workstream** (`agency/workstreams/mdslidepal/`) = **how we manage things** — contract, themes, fixtures, plan-b safety net, plans, reconciliation receipts. Coordination artifacts.
- **Source trees** (`apps/mdslidepal-web/`, `apps/mdslidepal-mac/`) = **where we put the code** — actual implementations, each with own build config and local `claude/` agency config.

This matches the existing `apps/mdpal-app/` ↔ `agency/workstreams/mdpal/` precedent.

### Decision 4 — Mac CLI: **Option A (GUI only for MVP)**

**Resolution:** mdslidepal-mac ships as a single `.app` bundle for MVP. No companion CLI binary. Users interact via menus, file-open dialogs, keyboard shortcuts. CLI target is Phase 2 work (~1-2 days) — not required for MVP.

**Rationale:** Nothing Monday depends on a Mac CLI. Mac scope is already substantial (5 phases). A CLI target is a reasonable post-MVP addition that can be built once the Mac app itself is proven.

## Autonomous decisions (resolved without surfacing)

The following items were flagged in agent plans but resolved autonomously with conservative defaults:

- Signing/notarization: dev-signed for MVP, notarization in Phase 2
- Live-reload debounce: 300ms standard
- HTMLBlock parsing risk in swift-markdown: Mac agent investigates during Phase 1 (Yams handles front-matter; `<!-- slide: -->` may need custom HTMLBlock extraction)
- Remote-image offline behavior: warn + render placeholder (per contract error handling)
- Dock drag-drop on macOS 14: Phase 2
- Live-reload during presentation: disabled while in present mode
- Forward-compat `layout:` field: ignore with warning (per contract error handling)

## Fixture coverage at Iteration 1

**Web (6 of 8 fixtures in MVP):**
- ✓ 01-minimal — smoke test
- ✓ 02-multi-slide — basic `---` breaks
- ✓ 03-code-blocks — syntax highlighting for bash/ts/python/swift
- ✓ 04-images — local image resolution (with missing-image fallback)
- ✓ 05-tables-and-lists — GFM tables, nested lists, task lists
- ✓ 08-edge-cases — regex pre-processor handles the strict edge cases (Decision 1)
- ✗ 06-front-matter — deferred to Phase 2.1
- ✗ 07-speaker-notes — deferred to Phase 2.2

**Mac (all 8 fixtures in MVP across phases):**
- Phase 1 (renderer + theme): 01, 02, 03, 05
- Phase 2 (window + file load): 04, 06
- Phase 3 (presenter mode): 07
- Phase 1 AST detection: 08 (works naturally from AST walk)

## Plan B safety net preserved

Plan B at `agency/workstreams/mdslidepal/plan-b/` is untouched and remains operational. reveal.js 5.2.1 is already vendored. Jordan can double-click `plan-b/reveal-js-template.html` right now and present the workshop deck from `plan-b/sample-workshop.md`. Web Iteration 1 builds ON TOP OF Plan B; it does not replace it. Plan C (Marp CLI) is documented as a secondary fallback.

## Next steps

1. ✓ Contract updated to v1.3 with decisions baked in
2. ✓ Reconciliation receipt written (this file)
3. ⬜ Commit v1.3 contract + reconciliation receipt + both plan documents
4. ⬜ Web agent Iteration 1 begins (Saturday sprint, targeting Saturday night MVP)
5. ⬜ Mac agent Phase 1 begins (no deadline pressure)
6. ⬜ Workshop dry-run Sunday afternoon with the web MVP
7. ⬜ Monday 13 April: Republic Polytechnic workshop delivered from mdslidepal-web (or Plan B fallback if needed)

Both agents are cleared to proceed. The contract is locked at v1.3. Any further changes require a new MAR cycle or a new reconciliation round.

---

*Reconciliation complete. Captain approves both plans. Execution begins.*
