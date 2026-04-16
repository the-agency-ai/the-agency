---
type: directive
from: the-agency/jordan/captain
to: the-agency/jordan/devex
date: 2026-04-08T03:42
status: created
priority: normal
subject: "Hookify rule rename: verb-noun → noun-verb convention"
in_reply_to: null
---

# Hookify rule rename: verb-noun → noun-verb convention

# Hookify rename: noun-verb convention

Principal decision from last session: hookify rule names follow **noun-verb**, not verb-noun. This is our convention across naming.

## Current state

Hookify rules in `claude/hookify/` currently use verb-noun (e.g. `hookify.block-cd-to-main.md`, `hookify.block-raw-handoff.md`). These need to be renamed to noun-verb.

## Scope

1. **Inventory** — list all hookify rules in `claude/hookify/` and categorize:
   - Verb-first rules that need renaming
   - Already noun-first rules (leave alone)
   - Ambiguous cases — flag for principal clarification in the plan

2. **Rename** — for each verb-first rule, produce the noun-verb form:
   - `hookify.block-cd-to-main.md` → `hookify.cd-to-main-block.md` (or propose a better noun anchor)
   - `hookify.block-raw-handoff.md` → `hookify.raw-handoff-block.md`
   - `hookify.warn-on-push.md` → `hookify.push-warn.md`
   - etc.

3. **Preserve content, update metadata** — the rule title, frontmatter, and any internal references to the rule name should also update.

4. **Update docs** — `claude/README-ENFORCEMENT.md` table lists all hookify rules by name. Update every row.

5. **Update symlinks in `.claude/`** — hookify rules get activated via symlinks (`hookify.*.local.md`). Any active symlinks need to point at the renamed files.

6. **Update `usr/jordan/**/claude/hookify/`** sandbox rules that use verb-first too.

## Plan-mode first

- Send me the inventory + proposed renames as a review dispatch
- Flag ambiguous cases (rules where the noun anchor isn't obvious)
- After approval, execute as one phase, ship in a single commit

## Acceptance

- Every hookify rule file follows noun-verb
- README-ENFORCEMENT.md table reflects new names
- All active symlinks resolved
- BATS tests (if any reference rule names) still green
- No dangling references in docs

## Slot

Low priority — fold in between Item 1 and Item 2 of your main queue, or handle as a side iteration. Not blocking anything.
