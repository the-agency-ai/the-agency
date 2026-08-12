# Flag-Mountain Triage Outcome — 2026-08-12

Triaged 216 accumulated flags (filed 2026-04-05 → 2026-08-12) via 5 parallel
categorization agents, each citing evidence. Disposition approved by principal:
**bulk-clear Bucket 1 (resolved), convert Bucket 2 to work-items, walk Bucket 3.**

- **Bucket 1 — Resolved/Obsolete: ~141** — cleared from the flag queue. Overtaken
  by the Great Rename, safe-tool family, ISCP-on-SQLite, 41 declarative hookify
  rules, receipt infra, `monitor-dispatches`, one-agent-one-worktree, and this
  session's PRs (#466–#472). Includes ~25 empty/test/placeholder flags and the
  self-closing post-merge auto-flags (#180–#215, all releases cut through v46.35).
- **Bucket 2 — Autonomous: the work-items below** (this doc IS the tracking).
- **Bucket 3 — Collaborative: the decisions below** (walked with principal).

---

## Bucket 2 — Autonomous work-items (do NOT build-now; tracked here)

### Missing BATS tests
- **#138** `figma-extract` has no bats — write tests.
- **#139** `designsystem-add` has no bats — write tests.
- **#140** `designsystem-build` not merged to `agency/tools/` + no bats — land tool + tests.
- **#144** hookify dispatcher integration harness missing (`src/tests/hookify/` has only canaries) — build block-raw-tools dispatch harness.

### Unbuilt skills
- **#47** `/why-did-this-fail` (infra ready: end-events + run-id surfacing landed).
- **#77** `/make-slides` (wrap mdslidepal serve).
- **#152 / #80** `/seed` skill.
- **#137 / #190 / #192** `anthropic-feedback` skill (monofolk draft exists as exemplar).

### Small tool additions / fixes
- **#109** `git-captain` feature→feature merge subcommand.
- **#120** `git-captain` cherry-pick subcommand.
- **#115** `detect_main_branch` edge case (main deleted locally).
- **#186 / #194** register `reviewer-*` agents as instances (or wire QG to load the class agent.md) — silently degrades QG otherwise.
- **#94** enforce correct-gate-for-boundary: check receipt `boundary` field (pr-prep vs iteration).
- **#95** `/verify-chain` full five-hash verify (receipt-verify only checks Hash E today).
- **#142** verify git-safe-commit recognizes new-format receipts (no longer globs qgr).
- **#117** exclude receipts from stage-hash (or document) in git-safe-commit.
- **#119** fully-qualified-path-to-principal convention helper.
- **#81** gitignore backup files + `messages.db`.

### Doc fixes
- **#213** — **HIGH** — 7 v2 skills point `required_reading` at pre-Great-Rename `agency/REFERENCE-*.md` (should be `agency/REFERENCE/REFERENCE-*.md`): captain-release, captain-review, captain-sync-all, captain-log, sync, pr-captain-merge, pr-captain-post-merge. Silently broken. Sweep + fix. (Flag #241 duplicates this.)
- **#106** clarify REFERENCE-RECEIPT-INFRASTRUCTURE.md §6 ("on disk" = committed vs working tree).
- **#145** document the agent-class `## Class` convention (paths/registration/workspace).
- **#143** skill pnpm-test validator (`skill-validation.bats:136`) too restrictive — allow inline-code/list contexts.

### QG / process
- **#207** QG Step-10 ordering: diff-hash can't see uncommitted, so Hash E asked pre-commit → E==A. Reorder to commit-first (or make diff-hash see uncommitted). (Flag #235 duplicates.)
- **#216** discipline capture: never sign a QGR "no findings" until the review that would surface them has reported; when taking over a stalled agent's gate, retrieve/re-run its review. (Flag #244 duplicates — this session's lesson.)
- **#87** wire RG receipts into define/design/plan via pre-phase-review.
- **#148** designex Phase 1.5 deferred findings → dispatch into a plan.
- **#149 / #8** command/skill relevance audit (surface thin post-v2).
- **#14 / #40** structure + update-readiness audit → fold into agency-health.
- **#41** CI health pass (confirm auto-release/bash32-probe/release-version-precheck/smoke).
- **#42** docker-test self-heal/document or deprecate for local BATS.
- **#43** telemetry compound-pattern scanner (the seeded tool-discovery loop).
- **#86** add Dependabot alerts + issue check to session-preflight/session-resume.

### Seeds / captures
- **#62** cross-repo evolution seed (book material).
- **#65** framework pre-history (the-agency-starter) capture.
- **#31** Granola ingestion/redact pipeline (seed + MCP exist).
- **#129** iCloud integration seed.
- **#123** valueflow-pipeline.svg back-arrows fix.

### App-workstream dispatches (routed to owning agents — see below)
- **#209** mdpal-app: wire DiffView/LineDiff to a user entry point (Phase 2.3 diff-in-conflict).
- **#210** mdpal-app: MDPAL_MOCK=1 dead for DocumentGroup flow (MarkdownDocument bypasses CLIServiceFactory).
- **#211** mdpal-cli: `mdpal create --content` unbounded argv (E2BIG) → add `--content-stdin` 16KiB threshold.
- **#78** mdslidepal: smart-quote (SmartyPants) rendering not present.

---

## Bucket 3 — Collaborative decisions (walk with principal)

### App contract rulings
- **#203** mdslidepal-mac: remote images = tracking beacon. Contract §5:219 says "loaded directly." Add consent gate (contradicts contract) vs accept as-is.
- **#204** mdslidepal-mac: fixture08 slide count — blocked on dispatch #217 (open since April).
- **#205** mdslidepal-mac: fixture05 autolinks unimplementable (swift-markdown has no cmark-gfm autolink option) — amend contract.
- **#206** mdslidepal-mac: "hero" slide implemented but undefined in contract — define or remove.
- **#183** mdpal/ migration — `usr/jordan/mdpal` still alongside `agency/workstreams/mdpal`; pick migration scope (a/b/c).

### Public-launch gates
- **#28** adopter permission scoping + threat model (currently `Bash(*)`; public framework needs scoped perms — settings-template concern).
- **#146** install-surface vs repo-surface boundary — undefined; needs a rule + enforcement.

### Framework architecture (design sessions)
- **#55** "collaboration" naming rework (pairwise naming, separator, migration).
- **#80 / #92** remote dispatch-service (replacing file-based collaborate) + receipt registry DB/index.
- **#90** RG-on-QGR formal gate (review-the-review).
- **#91** universal artifact naming (`{org}-{principal}-…`) + multi-project-per-workstream.
- **#102 / #105** skill-vs-tool enforcement gap (no hookify rule blocks direct-tool bypass of skills; needs design + Anthropic feedback).
- **#110** Claude Code Routines adoption (cloud-session + receipt integration).
- **#150** refactor skill + subagent defs (pending monofolk agency-skills-v2 upstream).

### Business / external
- **#33 / #34** agentic-email service — market/viability strategy call.
- **#67** session auto-rename trust (Claude Code harness; root cause unconfirmed).

---

---

## Bucket 3 — Dispositions (principal-delegated, "as you recommend", 2026-08-12)

### App contract rulings → dispatched to mdslidepal-mac (ISCP #1004)
- **#203** remote-image beacon → **accept as-is**; honor contract §5:219, keep bounds (10s/16MB), document the privacy characteristic; no consent gate.
- **#204** fixture08 count (#217) → **resolve by the contract's canonical slide-split rules**; fix whichever side is wrong, document, close #217.
- **#205** fixture05 autolinks → **amend contract**: "not supported (upstream: swift-markdown has no cmark-gfm autolink option)."
- **#206** "hero" slide → **define in contract** to match implementation (agent flags back if vestigial).
- **#183** mdpal migration → **consolidate to `agency/workstreams/mdpal`**, migrate unique content from `usr/jordan/mdpal`, remove duplicate. Tracked as captain task #15.

### Public-launch gates → directional, detailed work deferred to "adopter hardening" effort
- **#28** permission scoping → internal stays `Bash(*)`; adopter-scoped perms are a settings-template concern, deferred to pre-launch hardening (not blocking until public release).
- **#146** install-surface vs repo-surface → define install-surface = `src/` payload `agency init` ships, repo-surface = running instance; a hookify rule should enforce the mirror. Rule design deferred to the same hardening effort.

### Framework architecture → deferred to a dedicated design session
- **#55** collaboration naming · **#80/#92** remote dispatch-service + receipt registry · **#90** RG-on-QGR gate · **#91** artifact naming + multi-project · **#102/#105** skill-vs-tool enforcement · **#110** Routines adoption · **#150** refactor skill (pending monofolk upstream). Seven deep design calls — schedule as their own session.

### Business / external
- **#33/#34** agentic-email service → strategy backlog. · **#67** session-rename trust → upstream-dependent, monitor.

---

## Tool quirk noted during this triage
`flag list` displays ALL flags including already-processed ones (216 shown), so the "mountain" persists visually even though the unprocessed queue is empty (`flag count` = 0, `flag clear` = "nothing to clear"). `flag list` should default to unprocessed-only (with an `--all` for history). Minor tool fix — added to the Bucket-2 backlog spirit.

---

*Triage evidence: full per-flag tables in the 5 categorization-agent runs
(session 58f53c72, 2026-08-12). Active flag queue cleared (count=0) after this doc committed.*
