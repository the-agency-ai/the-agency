# Handoff: mdpal-cli

---
type: session-handoff
date: 2026-04-04
principal: jordan
agent: the-agency/jordan/mdpal-cli
workstream: mdpal
trigger: session-boundary
---

## Who You Are

You are **mdpal-cli**, a tech-lead agent owning the **core engine, CLI, and bundle management operations** for Markdown Pal. Read your role from `claude/agents/tech-lead/agent.md`. Read workstream knowledge from `claude/workstreams/mdpal/KNOWLEDGE.md`.

## Your Counterpart

**mdpal-app** owns the macOS native SwiftUI app. You share the `mdpal` worktree. Coordinate via dispatches in `usr/jordan/mdpal/dispatches/`.

## Status

**PVR: Complete (pending Jordan's final sign-off).** All 9 items resolved. mdpal-cli signed off on the post-MAR PVR. Waiting for principal approval.

**A&D: Kicked off.** mdpal-cli leads. Dispatch sent to mdpal-app requesting collaboration on engine API contract.

## What Was Done This Session

1. **Bootstrap:** Read all seed materials, agent registration, tech-lead role, workstream knowledge, both handoffs.
2. **`/discuss` session with Jordan** — three items resolved:
   - **Swift cross-platform:** Swift confirmed. macOS first, Linux second, Windows deferred.
   - **Structured editing vision:** Pluggable parser architecture in V1. Engine operates on abstract structural nodes. Markdown is first parser. Designed for any grammar-defined format.
   - **PVR Items 5-9:** All resolved (agent interface = engine + CLI, V1 scope, research comment triage, Agency infrastructure relationship, competitive landscape).
3. **Reviewed mdpal-app's PVR** (`pvr-mdpal-20260403-1447.md`) — signed off with 4 minor notes (slug disambiguation, `create` scope, parser validation exercise, r002 timing).
4. **Sent A&D kickoff dispatch** to mdpal-app with scope, questions, and proposed process.
5. **Added `review-prototype-20250310.jsx`** to workstream seeds.

## Key Decisions

- **Language:** Swift (shared with mdpal-app)
- **Platforms:** macOS 14+ primary, Linux second, Windows deferred
- **V1 product:** Engine library + CLI. MCP/LSP deferred.
- **Engine architecture:** Two-layer API — core (format-agnostic section ops) + bundle (Markdown Pal-specific)
- **Pluggable parsers:** V1 architecture, not bolt-on. Markdown first.
- **V1 essence:** Five symmetric capabilities (read, edit, comment, flag, diff) for agents and principals
- **Coordination:** Parallel with contract. mdpal-cli defines API in A&D, mdpal-app collaborates.
- **YAML handling:** YAML in fenced code block inside HTML comment boundaries. Not as hard as initially feared.

## Key Files

| File | What |
|------|------|
| `usr/jordan/mdpal/pvr-mdpal-20260403-1447.md` | PVR (post-MAR, pending principal sign-off) |
| `usr/jordan/mdpal/transcripts/discuss-swift-crossplatform-20260403.md` | This session's discussion transcript |
| `usr/jordan/mdpal/dispatches/dispatch-pvr-cli-signoff-20260403.md` | PVR sign-off dispatch |
| `usr/jordan/mdpal/dispatches/dispatch-ad-kickoff-20260404.md` | A&D kickoff dispatch to mdpal-app |
| `usr/jordan/mdpal/dispatches/dispatch-pvr-cli-response-20260403.md` | Earlier PVR response dispatch |
| `claude/workstreams/mdpal/seeds/` | All seed materials |
| `claude/workstreams/mdpal/KNOWLEDGE.md` | Workstream knowledge |

## Next Action

1. **Wait for Jordan's PVR sign-off** (or address any feedback)
2. **Read mdpal-app's response** to the A&D kickoff dispatch
3. **Start A&D draft** — prioritize engine API contract (unblocks mdpal-app)
4. **A&D items to resolve:** pluggable parser protocol, section addressing (incl. slug disambiguation), comment/flag data model, bundle operations, concurrent writes (r002), version bump enforcement (r008), CLI command spec

## Technical Notes for Next Session

- Sub-section granularity (paragraph:2, content matching) — likely defer to post-V1. V1 engine operates at section level.
- Engine state model — support both stateless (CLI) and stateful (app holds Document in memory). Probably a `Document` type that can be created from path or held.
- `swift-markdown` `HTMLBlock` nodes for metadata boundaries — need to verify parsing behavior in A&D prototyping.
