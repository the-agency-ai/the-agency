---
name: changelog
description: Generate or watch the Claude Code changelog. Use `/changelog` (no args) to generate from the last captured version to current. Use `/changelog <from> [<to>]` to generate for a specific range. Use `/changelog watch` to start a background monitor that streams new releases as they land. Triggers on "changelog", "what's new in claude code", "recent claude releases", "monitor claude code", "watch changelog", or when the user asks about new Claude Code features.
---

# /changelog

Two modes for staying current with Claude Code releases:

- **Generate** (default) — one-shot changelog between two versions, saved to `claude/CHANGELOG-*.md`
- **Watch** — background monitor that streams new releases as they land

## When to use

### Generate mode
- After a Claude Code update, to see what's new
- Catching up after time away
- Preparing a release-notes section that references upstream changes
- User asks "what changed in Claude Code recently?"

### Watch mode
- At session start for continuous awareness
- When tracking specific upcoming features (e.g., Monitor tool, remote control)
- Pairs with `monitor-dispatches` for full situational awareness

## Usage

```
/changelog                      — from last captured version to current
/changelog 2.1.50               — from 2.1.50 to current
/changelog 2.1.50 2.1.60        — explicit from/to range
/changelog watch                — start background monitor (persistent)
/changelog watch --interval N   — custom poll interval (default 30 minutes)
```

## Generate mode — behavior

### Step 1: Parse arguments

- **No arguments:** from the last `claude/CHANGELOG-*.md`'s ending version to the current installed version
- **One argument** (e.g., `2.1.50`): from that version to current
- **Two arguments** (e.g., `2.1.50 2.1.60`): explicit from/to range

Get current version:
```bash
claude --version 2>&1 | awk '{print $1}'
```

Check last captured changelog:
```bash
ls claude/CHANGELOG-*.md | tail -1
```

### Step 2: Fetch the changelog

Fetch directly from GitHub:

```
WebFetch URL: https://raw.githubusercontent.com/anthropics/claude-code/main/CHANGELOG.md
Prompt: Extract ALL changelog entries for versions {FROM} through {TO}. Include every single line item verbatim — features, bug fixes, performance changes, everything. Do not summarize or skip anything.
```

**This is a single WebFetch call.** Do NOT spawn a research agent. Do NOT search npm, X.com, or third-party sites. The official changelog is authoritative.

Fallback if WebFetch fails (rate limit, etc.):
```bash
gh api repos/anthropics/claude-code/contents/CHANGELOG.md --jq '.content' | base64 -d
```

### Step 3: Generate the changelog document

Write a markdown doc in this format (adapt sections to what's actually in the range — omit empty sections, add new ones when warranted):

```markdown
# Claude Code Changelog: v{FROM} → v{TO}

**Generated:** {YYYY-MM-DD}
**Current Version:** {TO}

---

## Major Features Overview
<!-- Each major feature with description, version introduced, deep-dive analysis -->
<!-- Include "Agency relevance" notes for features that affect our workflow -->

## Stability & Bug Fixes
<!-- Grouped by theme: freezes, API, plugins, platform-specific, etc. -->

## Performance
<!-- Table format: Improvement | Version | Detail -->

## SDK / Type Changes
<!-- If tool definitions or SDK types changed -->

## Actionable Items for The Agency
<!-- High / Medium / Low priority items we should act on -->
```

### Step 4: Display inline

Show the full changelog markdown in the conversation.

### Step 5: Save to file

```
claude/CHANGELOG-{YYYY-MM-DD}-{FROM}-{TO}.md
```

Example: `CHANGELOG-2026-03-08-2.1.70-2.1.71.md`

### Step 6: Confirm

```
Changelog saved to: claude/CHANGELOG-{YYYY-MM-DD}-{FROM}-{TO}.md
Range: v{FROM} → v{TO}
```

## Watch mode — behavior

Use the Monitor tool to run the changelog-monitor script in the background:

```
Monitor the Claude Code changelog for new releases. Run ./claude/tools/changelog-monitor in the background. When a new version is detected, summarize what changed and flag anything relevant to our workflow.
```

The script:
- Polls `https://raw.githubusercontent.com/anthropics/claude-code/main/CHANGELOG.md` every 30 minutes (configurable with `--interval N`)
- Only outputs when the changelog actually changed (completely silent otherwise)
- Extracts the latest entry automatically
- State persisted in `~/.agency/changelog-monitor/` (survives session restarts)

### When a watch event arrives

1. Read the changelog entry
2. Evaluate relevance to TheAgency:
   - New tools or features we should adopt?
   - Breaking changes that affect our hooks / tools?
   - Performance improvements we benefit from?
   - Bug fixes for issues we've reported?
3. If relevant: flag to the principal, capture a seed if it warrants adoption
4. If not relevant: note silently — no output needed

### Example discoveries this pattern catches

- Monitor tool (v2.1.98) — we adopted it within minutes of discovery
- Remote Control improvements
- Hook lifecycle changes
- New MCP capabilities
- Token pricing changes

## Rules (both modes)

- **Do NOT spawn research agents** for generate mode. It's a single fetch + write.
- Official GitHub changelog is the only source.
- If the changelog has gaps, note them rather than guessing.
- Include "Agency relevance" analysis — bare feature lists aren't useful; what matters is how it affects our work.

## Reference changelogs

- `claude/CHANGELOG-2026-02-28-2.1.17-2.1.63.md`
- `claude/CHANGELOG-2026-03-05-2.1.64-2.1.69.md`
- `claude/CHANGELOG-2026-03-08-2.1.70-2.1.71.md`

These are format exemplars — match their structure when generating new ones.
