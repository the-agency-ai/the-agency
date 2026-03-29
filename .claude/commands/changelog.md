# Generate Claude Code Changelog

The user typed: `/changelog $ARGUMENTS`

**Purpose:** Generate a Claude Code changelog between two versions by fetching the official changelog, then summarizing and saving to a file.

## Behavior

### 1. Parse Arguments

Parse `$ARGUMENTS` to determine the version range:

- **No arguments:** From the last changelog's ending version to the current installed version
- **One argument** (e.g., `2.1.50`): From that version to the current installed version
- **Two arguments** (e.g., `2.1.50 2.1.60`): Explicit from/to range

Get the current version:
```bash
claude --version 2>&1 | awk '{print $1}'
```

Check the last changelog:
```bash
ls claude/CHANGELOG-*.md | tail -1
```

### 2. Fetch the Changelog

Fetch the official changelog directly from GitHub:

```
WebFetch URL: https://raw.githubusercontent.com/anthropics/claude-code/main/CHANGELOG.md
Prompt: Extract ALL changelog entries for versions {FROM} through {TO}. Include every single line item verbatim - features, bug fixes, performance changes, everything. Do not summarize or skip anything.
```

**This is a single WebFetch call.** Do NOT spawn a research agent, do NOT search npm, do NOT browse X.com or third-party sites. The official changelog at the URL above is the authoritative source.

If the WebFetch fails (rate limited, etc.), retry once, then try `gh api` as fallback:
```bash
gh api repos/anthropics/claude-code/contents/CHANGELOG.md --jq '.content' | base64 -d
```

### 3. Generate Changelog Document

Using the fetched entries, generate a markdown document following the format established in previous changelogs (see `claude/CHANGELOG-*.md` for examples). Include these sections as applicable:

```markdown
# Claude Code Changelog: v{FROM} → v{TO}

**Generated:** {YYYY-MM-DD}
**Current Version:** {TO}

---

## Major Features Overview
<!-- Each major feature with description, version introduced, and deep-dive analysis -->
<!-- Include "Agency relevance" notes for features that affect our workflow -->

## Stability & Bug Fixes
<!-- Grouped by theme: freezes, API, plugins, platform-specific, etc. -->

## Performance
<!-- Table format: Improvement | Version | Detail -->

## SDK/Type Changes
<!-- If any tool definitions or SDK types changed -->

## Actionable Items for The Agency
<!-- High/Medium/Low priority items we should act on -->
```

Adapt sections to what's actually in the changelog — don't include empty sections, and add sections if the changes warrant them.

### 4. Display Inline

Display the full changelog markdown directly to the user in the conversation.

### 5. Save to File

Save to `claude/` directory:
```
CHANGELOG-{YYYY-MM-DD}-{FROM}-{TO}.md
```

Example: `CHANGELOG-2026-03-08-2.1.70-2.1.71.md`

### 6. Output Confirmation

```
Changelog saved to: claude/CHANGELOG-{YYYY-MM-DD}-{FROM}-{TO}.md
Range: v{FROM} → v{TO}
```

## Important Notes

- **Do NOT spawn agents for this task.** It's a single fetch + write operation.
- The official GitHub changelog is the only source needed.
- If the changelog has gaps or missing versions, note them rather than guessing.
- Include "Agency relevance" analysis for features that affect our workflow.
- Previous changelogs for format reference:
  - `claude/CHANGELOG-2026-02-28-2.1.17-2.1.63.md`
  - `claude/CHANGELOG-2026-03-05-2.1.64-2.1.69.md`
  - `claude/CHANGELOG-2026-03-08-2.1.70-2.1.71.md`
