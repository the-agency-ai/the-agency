# Issues: Agency 2.0 Setup

**Date:** 2026-03-29
**Agent:** captain (housekeeping)
**Principal:** jordan
**Shared with:** monofolk CoS

---

## Issues Found During Agency 2.0 Captain Transition

### ISS-001: Ghostty bare hex color values (RESOLVED)

**Severity:** High (terminal unreadable)
**Found by:** captain
**Status:** Resolved

Ghostty config at `~/.config/ghostty/config` had bare hex color values (`background = 282828`) without `#` prefix. The Gruvbox Dark theme file uses `#282828`. Bare values were silently ignored, causing wrong colors and unreadable text.

**Fix:** Removed redundant `background`/`foreground` overrides. Let `theme = ...` handle colors. Switched to GitHub Light Default + JetBrains Mono 14.

**Recurrence:** This was a recurring issue (6+ times across sessions). Saved a feedback memory (`feedback_ghostty_colors.md`) to prevent it.

**Action for monofolk:** `tools/ghostty-setup` was updated to include theme, font, and full config — no bare hex values. Verify the updated tool produces a valid config on fresh setup.

---

### ISS-002: `workstream-create` creates directory from `--help` flag (RESOLVED)

**Severity:** Medium (bug in tool)
**Found by:** captain
**Status:** Resolved (directory removed), tool not yet fixed

`./tools/workstream-create --help` created a `claude/workstreams/--help/` directory with KNOWLEDGE.md and epic stubs instead of showing help text. The tool's `--help` flag is not being parsed before directory creation.

**Fix applied:** Removed the errant directory manually.

**Action for monofolk:** Fix `tools/workstream-create` to parse `--help` before creating directories. Same bug likely exists in monofolk's copy.

---

### ISS-003: Agent template defaults to "Opus 4.5" (RESOLVED)

**Severity:** Low (cosmetic)
**Found by:** captain
**Status:** Resolved in agent.md files

`./tools/agent-create` generates agent.md with `**Model:** Opus 4.5 (default)`. Current model is Opus 4.6.

**Fix applied:** Manually updated all three agent.md files to Opus 4.6.

**Action for monofolk:** Update the agent template in `tools/agent-create` to reference Opus 4.6, or make the model version dynamic.

---

### ISS-004: Workstream KNOWLEDGE.md is bare boilerplate (RESOLVED)

**Severity:** Low (incomplete scaffolding)
**Found by:** captain
**Status:** Resolved

`./tools/workstream-create` generates KNOWLEDGE.md with placeholder text (`[Description of what this workstream covers]`). The gtm workstream had this since January 2026 — never filled in.

**Fix applied:** Filled in KNOWLEDGE.md for all three workstreams (markdown-pal, mock-and-mark, gtm) with project scope, key concepts, seed file references.

**Action for monofolk:** Consider whether `workstream-create` should prompt for a description or accept one as a flag.

---

### ISS-005: Agent.md has no seed file cross-references (RESOLVED)

**Severity:** Low (missing context for agents)
**Found by:** captain
**Status:** Resolved

`./tools/agent-create` generates agent.md pointing to `claude/agents/{name}/` and `claude/workstreams/{name}/` but does not reference seed files at `usr/jordan/{name}/`. Agents launched without this context would not know where their project materials are.

**Fix applied:** Added Seed Files section to all three agent.md files.

**Action for monofolk:** Consider whether agent-create should accept a `--seeds` flag or auto-detect `usr/{principal}/{agent}/` if it exists.

---

### ISS-006: Briefing files not included in initial PRs

**Severity:** Medium (blocked captain transition)
**Found by:** captain
**Status:** Resolved (PR #3 merged)

The CoS session briefing files (`guide-cos-session-briefing-20260329.md`, `devex-tools-unification-review-20260329.md`, `guide-secret-skill-design-20260329.md`) were not included in PR #1 or PR #2. Captain could not complete the transition checklist without them. Required a third PR (#3) to deliver.

**Action for monofolk:** When producing transition guides that reference companion files, ensure all referenced files are included in the same PR.

---

### ISS-007: `agent-create` does not register agents with Claude Code (OPEN)

**Severity:** Medium (agents can't be launched via `claude --agent`)
**Found by:** captain
**Status:** Open

`./tools/agent-create` creates Agency-level agent directories (`claude/agents/{name}/agent.md`, KNOWLEDGE.md, etc.) but does not register the agent in `.claude/settings.json` under the `"agents"` key. This means `claude --agent markdown-pal` doesn't work — Claude Code doesn't know about Agency agents.

Two systems exist side by side:
- **Agency agents** — `claude/agents/{name}/agent.md` (identity, responsibilities, seed files)
- **Claude Code agents** — `settings.json` `"agents"` key or `--agents` CLI flag (what `claude --agent` resolves)

`agent-create` should bridge these by generating a Claude Code agent entry in settings.json that references the Agency agent definition. The agent's `prompt` field should instruct Claude to read its `agent.md` and relevant seed files.

**Action:** Update `tools/agent-create` to also register agents in `.claude/settings.json` under the `"agents"` key, with a prompt that bootstraps from `agent.md`.

---

## Summary

| Issue | Severity | Status | Tool Fix Needed |
|-------|----------|--------|-----------------|
| ISS-001 | High | Resolved | ghostty-setup updated |
| ISS-002 | Medium | Resolved (workaround) | workstream-create needs --help fix |
| ISS-003 | Low | Resolved (manual) | agent-create template needs model update |
| ISS-004 | Low | Resolved (manual) | workstream-create could accept description |
| ISS-005 | Low | Resolved (manual) | agent-create could accept --seeds flag |
| ISS-006 | Medium | Resolved | Process: include all referenced files in PR |
| ISS-007 | Medium | Open | agent-create must register in settings.json |
