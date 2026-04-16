# Guide: CoS Session Briefing for the-agency Captain

**For:** the-agency Captain
**From:** CoS (monofolk session, 2026-03-29)
**Date:** 2026-03-29

---

## What Happened Today

The monofolk CoS session ported Agency 2.0 innovations into the-agency across two PRs (#1, #2) and several direct commits. This document gives you the full context of every decision made.

---

## 7-Step Tools Unification Plan

Decided in a 1B1 discussion. The goal: formalize the-agency's tool framework and unify tools across repos.

**The sequence:**
1. **Review** — study all three tool sets (legacy monofolk, next-gen monofolk, the-agency/tools). Understand what exists, what works, what the patterns are.
2. **Extract + formalize** — from the-agency's best tools, extract the framework spec. Output standard, logging, versioning, help, error handling — codify what's implicit.
3. **Gap analysis** — what does the-agency tool set need that it doesn't have? Not porting monofolk tools, but identifying holes.
4. **Update existing** — bring all the-agency/tools up to the formalized framework.
5. **Fill gaps** — build new tools to the framework.
6. **Port next-gen** — monofolk's Jordan-era tools get ported to the framework.
7. **Leave legacy alone** — legacy monofolk tools stay as-is.

**Key principles:**
- Framework formalization comes FIRST, preceded by review
- Step 3 is about filling gaps in the-agency, not migrating monofolk tools
- Step 4 exists because existing the-agency tools aren't all consistent
- The tools review report is at `usr/jordan/captain/devex-tools-unification-review-20260329.md` (copied from monofolk)

---

## /secret Skill Design

A pluggable secret management skill. Design completed in 1B1.

**Architecture:**
- `/secret` is the interface skill — defines verbs, handles conversation with principal
- Provider tools do the actual work: `tools/secret-vault` (renamed from `tools/secret`), `tools/secret-doppler` (new)
- Provider selected via `agency.yaml secrets.provider` + auto-detection

**Verbs:** set, get, list, delete, rotate, scan

**Key decisions:**
- Skills ASK the principal for what they need — no CLI flag gymnastics
- Doppler requires project + config scope; vault is flat. The skill adapts its questions to what the provider needs.
- `/secret scan` runs as part of QG at three levels:
  - Iteration: staged files + settings
  - Phase: all files in the project area
  - PR prep: full repo baseline (this is where leaked secrets get caught)
- The skill design is at `usr/jordan/captain/guide-secret-skill-design-20260329.md`

**Why this matters:** A Google BQ API key was found in monofolk's settings.local.json during QG. It had been there since PR #50. No QG caught it because QG reviews diffs, not baseline state. The `/secret scan` at PR prep level would have caught it.

---

## Starter Packs as Setup Skills

Starter packs evolve from static templates into executable setup skills. Example: `secret-doppler` isn't just a config file — it's a setup skill that installs Doppler CLI, creates doppler.yaml, wires scripts, and registers as the secrets provider.

Same pattern for: deploy (fly-deploy, vercel-deploy), preview (docker-preview), terminal (ghostty-setup, iterm-setup).

---

## myclaude Needs Replacement

`./tools/myclaude housekeeping captain` is deeply tied to Agency 1.0 (workstreams, agent names, session-backup, context-restore). Agency 2.0 needs a different session launch model. Design TBD — part of the agency init/update work.

---

## Multi-Project Worktrees (Open Design Question)

Can an agent have multiple projects on a specific workstream with multiple worktrees? Not resolved yet, but impacts forward design for agency init, worktree management, and agent session lifecycle.

---

## Guide Artifact Type

New artifact type established today. When an agent needs a principal (or another agent) to do something, it produces a step-by-step guide.

**Naming:** `guide-{project}-{slug}-YYYYMMDD.md` (guide prefix so they sort together)
**Quality bar:** Like the Doppler example — clear steps, alternatives explained, contextual advice, copy-pasteable commands, troubleshooting.

---

## the-agency Uses `main`, Not `master`

monofolk uses `master`. the-agency uses `main`. Don't mix them up. The branch-freshness hook has `base_branch` configurable for this reason.

---

## No Direct Push to Main

All changes go through PR branches. No exceptions. This was flagged after several commits went directly to main today during the initial contribution rush.

---

## What's Next

1. **MarkdownPal PVR/A&D** — seeds at `usr/jordan/markdown-pal/`. Use `/discuss`.
2. **MockAndMark PVR/A&D** — seeds at `usr/jordan/mock-and-mark/`. Use `/discuss`.
3. **Migrate principals** — move `claude/principals/jordan/` content to `usr/jordan/`. Build `tools/principal-migrate`.
4. **Agency init/update design** — 7 scenarios identified, needs 1B1 design session with transcript.
5. **Monofolk Demo plan** — EOB Tuesday deadline. Scope TBD.
6. **Tools unification step 2** — extract + formalize the framework spec from the-agency's best tools.
