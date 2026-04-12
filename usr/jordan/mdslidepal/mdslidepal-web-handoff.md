---
type: handoff
agent: the-agency/jordan/mdslidepal-web
workstream: mdslidepal
date: 2026-04-12
trigger: initial-setup
---

## Resume — mdslidepal-web Initial Handoff

### Immediate — Saturday Sprint

**Your mission:** Build mdslidepal-web Iteration 1 — a thin CLI wrapper over reveal.js that renders markdown slides in a browser. This is your ONLY deliverable. Target: working MVP by Saturday night.

### What to do FIRST

1. Read the plan: `claude/workstreams/mdslidepal/plan-mdslidepal-web-20260411.md` — this has your PVR, A&D, and phased plan. Follow it.
2. Read the contract: `claude/workstreams/mdslidepal/seed-mdslidepal-contract-20260411.md` (v1.3) — this is THE spec. Especially read the "MVP scope for web" section.
3. Look at Plan B: `claude/workstreams/mdslidepal/plan-b/` — your Iteration 1 builds ON TOP of this. The reveal.js template there is already vendored and working.
4. Look at the fixtures: `claude/workstreams/mdslidepal/fixtures/` — your MVP must pass fixtures 01, 02, 03, 04, 05, 08.

### Source tree

Create your code at `apps/mdslidepal-web/`. This is your implementation directory (RSL licensed).

### Tech stack (locked per plan)

- Node 20+ / TypeScript / pnpm
- reveal.js 5.2.x (vendored — copy from `plan-b/reveal.js/`)
- `sirv` for static serving, `open` for browser launch
- Raw `process.argv` (no CLI framework)
- ~50-line regex pre-processor for fixture 08 edge cases (Decision 1)

### Key constraints

- **Do NOT write a custom markdown parser.** Use reveal.js's native markdown plugin.
- **Do NOT exceed MVP scope.** No front-matter, no per-slide metadata, no speaker notes, no PDF export, no second theme. These are Phase 2.
- **Offline-first.** No CDN references. Vendor everything.
- **`file://` fallback.** Verify the output HTML works without a server.
- **One theme only:** `agency-default` (read from `claude/workstreams/mdslidepal/themes/agency-default.json`)

### Monday context

The Republic Polytechnic workshop is Monday 13 April 2026 at 9am. Jordan will present from this tool (or from Plan B if your work isn't ready). Saturday night is the real deadline — Sunday is buffer for Jordan's dry-run.

### Commit protocol

Use `/iteration-complete` at iteration boundaries. Commit to your branch (`mdslidepal-web`). Captain will review and merge via PR.
