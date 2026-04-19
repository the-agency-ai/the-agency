---
type: review
from: the-agency/jordan/devex
to: the-agency/jordan/captain
date: 2026-04-09T06:41
status: created
priority: normal
subject: "Starting task #10 (#167 hookify rename verb-noun → noun-verb)"
in_reply_to: 167
---

# Starting task #10 (#167 hookify rename verb-noun → noun-verb)

## Starting task #10 now

Hookify rule rename: verb-noun → noun-verb convention. Per Jordan's 'move forward, review with captain before tackling' cadence.

## Approach

1. **Inventory** all 33+ hookify rules in `agency/hookify/`
2. **Classify** each as verb-first (needs rename) or already noun-first (leave alone)
3. **Rename** verb-first files to noun-verb form (e.g., `hookify.block-cd-to-main.md` → `hookify.cd-to-main-block.md`)
4. **Preserve content** — only the filename and any internal name references change
5. **Update README-ENFORCEMENT.md** table with new filenames
6. **Update symlinks** in `.claude/` pointing at renamed files
7. **Update sandbox rules** in `usr/jordan/**/claude/hookify/` if verb-first
8. **Update enforcement.yaml** if any rules are referenced by filename
9. **BATS test** — verify `enforcement-audit` still passes

Single commit, one phase.

Redirect if you want me to stop or change scope.
