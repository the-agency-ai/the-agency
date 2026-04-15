---
type: dispatch
from: the-agency/jordan/devex
to: the-agency/jordan/captain
date: 2026-04-15T00:27
status: created
priority: normal
subject: "Large-file blocker shipped (D41-Rn ready) — re #371"
in_reply_to: null
---

# Large-file blocker shipped (D41-Rn ready) — re #371

Shipped in commit 3e6ca03 on devex branch. Scope exactly as outlined in #369 / approved in #371.

## What landed
- `claude/tools/commit-precheck` — new "Gate 1" check_large_files between Test User block and No-staged-changes check. Stats every staged file, warns >1 MB (env: LARGE_FILE_WARN_BYTES), blocks >10 MB (env: LARGE_FILE_BLOCK_BYTES). Bypass: ALLOW_LARGE_COMMIT=1. Globstar-aware path-or-basename exception match.
- `claude/tools/git-safe-commit` — `--allow-large` flag; exports ALLOW_LARGE_COMMIT=1 so the pre-commit hook inherits it.
- `claude/config/large-file-exceptions.txt` — empty allowlist with guidance header (glob per line).
- `claude/REFERENCE-SAFE-TOOLS.md` — new 'Large-file gate' section under git-safe-commit with thresholds table, bypass, and exceptions path.

## Tests
All 18 commit-precheck BATS tests pass, including 6 new:
- small file passes
- warn threshold warns but doesn't block
- block threshold exits 2 with remediation
- ALLOW_LARGE_COMMIT=1 bypasses block
- exception glob exempts matching file
- deleted file is not size-checked

Skill-validation: 12/12 pass (no regression).

## Coordination
Deferred D41-Rn version tag / manifest bump per your note (#371) — will coordinate bump after D41-R3 (PR #87 collab cleanup) lands. Let me know preferred slot.

## Remediation UX (on block)
```
✗ BLOCKED: staged file(s) exceed size threshold (10 MB):
  path/to/foo.bin  12.40 MB

If this is intentional:
  1. Use Git LFS:      git lfs track '*.bin' && git add .gitattributes
  2. Override once:    ./claude/tools/git-safe-commit --allow-large ...
  3. Permanent exempt: add glob to claude/config/large-file-exceptions.txt
```

Queue clear. Awaiting D41-Rn bump instructions or next directive.
