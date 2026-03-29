# Captain Handoff — the-agency

**Date:** 2026-03-29
**Branch:** `agency-2.0/monofolk-contribution`
**Context:** First Agency 2.0 contribution from monofolk. CoS session on monofolk prepared this.

## What Was Done (from monofolk CoS session)

### Agency 2.0 Contribution PR (committed, not yet pushed)
69 files on branch `agency-2.0/monofolk-contribution`:
- 8 agents (PM, 5 reviewers, CoS, captain merged)
- 6 hooks (ref-injector, session-handoff, quality-check, plan-capture, branch-freshness, tool-telemetry)
- 4 tools (worktree-create/list/delete, _path-resolve)
- 2 tools updated (add-principal, principal-create → usr/{principal}/ v2)
- 8 reference docs (QUALITY-GATE, DEVELOPMENT-METHODOLOGY, CODE-REVIEW-LIFECYCLE, FEEDBACK-FORMAT, PR-LIFECYCLE, TELEMETRY, CLAUDE-COVERAGE-CHECKLIST)
- 15 hookify behavioral rules
- /discuss skill, CLAUDE templates, principal-v2 template
- agency.yaml extended, registry.json updated, settings.json wired
- Hookify plugin enabled

### Principal Setup
- `usr/jordan/` scaffolded as first v2 principal
- `usr/jordan/conference/` — AIADLC papers, workshop materials, book research, transcripts
- `usr/jordan/markdown-pal/` — seed + analysis + original materials (chatlog, CLI spec, prompt)
- `usr/jordan/mock-and-mark/` — seed + analysis + original materials (chatlog, design doc)

### QG Fixes (second commit)
- 2 hookify rules fixed (wrong frontmatter schema → event/action)

## Push Blocked
`jordan-of` GitHub account doesn't have push access to `the-agency-ai/the-agency`. Need either:
- Push from `jordandm` account
- Or add `jordan-of` as collaborator on the-agency-ai org

## What's Next for the-agency Captain

### Immediate
1. Push the branch and create the PR
2. Review the contribution with a fresh eye — the captain knows this repo better than the monofolk CoS

### Tools Unification Review (Step 1)
The captain should audit the-agency's own tool set:
- How many of the 106+ tools fully follow the framework pattern?
- Which are the best examples?
- What gaps exist?
- This informs framework formalization (step 2)

### Principal Migration
- `claude/principals/jordan/` (v1) still exists alongside new `usr/jordan/` (v2)
- Build `tools/principal-migrate` to move existing principals
- Update any references in CLAUDE.md, agent files, tools

### MarkdownPal + MockAndMark
- Seeds and analysis are in `usr/jordan/markdown-pal/` and `usr/jordan/mock-and-mark/`
- Jordan wants to kick off PVR/A&D definition sessions for both
- These are companion tools for the-agency — they live here

### Decisions Made (monofolk CoS session, 2026-03-29)
- `usr/{principal}/` replaces `claude/principals/` (v2 convention)
- Worktree isolation is a first-class primitive
- Plugin slots for infrastructure, fixed conventions for methodology
- `/secret` skill: interface over providers (secret-vault, secret-doppler)
- `tools/secret` → `tools/secret-vault` (rename for clean separation)
- Starter packs evolve into executable setup skills
- Tools unification: 7-step plan (review → formalize → gap analysis → update existing → fill gaps → port next-gen → leave legacy)
- Secret scan becomes part of QG at all three levels (iteration, phase, PR prep)

## Reminders for Jordan
1. Fix GitHub push access (jordandm or org permission)
2. `doppler login` on the-agency laptop if needed
3. MarkdownPal + MockAndMark PVR sessions
4. Monofolk Demo plan — EOB Tuesday deadline
5. Call for papers — AIADLC + Adoption Case Study
