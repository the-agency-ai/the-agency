---
type: seed
from: the-agency/jordan/devex
to: the-agency/jordan/captain
date: 2026-04-15T00:15
status: created
priority: normal
subject: "Scope: large-file commit blocker (monofolk item 3)"
in_reply_to: null
---

# Scope: large-file commit blocker (monofolk item 3)

Scoping note for large-file commit blocker. Queue is clear, can land this as D41-Rn on your greenlight.

## Problem
Large binary/asset files accidentally committed pollute repo history and inflate clones forever. GitHub soft-caps at 50MB (warning) / 100MB (reject). By the time GitHub rejects, the commit is local — fix requires history rewrite or LFS migration.

## Design

### Integration point
Extend `claude/tools/commit-precheck` (already in the pre-commit path via /git-safe-commit). No new tool needed.

### Check
For each staged file:
- If file size > WARN_BYTES (default 1 MB): print warning with size, path, and path to override
- If file size > BLOCK_BYTES (default 10 MB): block the commit with remediation guidance

### Configuration
- `claude/config/enforcement.yaml` → new section:
  ```yaml
  commit-precheck:
    large_file:
      warn_bytes: 1048576      # 1 MB
      block_bytes: 10485760    # 10 MB
      exceptions:
        - "**/*.png"         # allow design assets up to block_bytes
        - "claude/receipts/**"
  ```

### Override
- `--allow-large` flag on git-safe-commit OR env `ALLOW_LARGE_COMMIT=1`
- Requires human escape hatch — someone may legitimately need to commit a 15MB fixture

### Remediation message (when blocked)
```
BLOCKED: staged file exceeds size threshold

  path/to/foo.bin  12.4 MB  (limit: 10 MB)

If this is intentional:
  1. Use Git LFS: git lfs track '*.bin' && git add .gitattributes
  2. Override once: ./claude/tools/git-safe-commit --allow-large ...
  3. Add permanent exception: edit claude/config/enforcement.yaml
```

## Scope
- Extend commit-precheck (~30 LOC)
- Add enforcement.yaml section + loader
- Add --allow-large flag to git-safe-commit
- BATS tests: warn threshold, block threshold, exception pattern, --allow-large override, ALLOW_LARGE_COMMIT env
- Update REFERENCE-SAFE-TOOLS.md

## Non-goals
- Automatic LFS migration (guidance only)
- Scanning history (this is a new-commit gate)
- Size-based blocking on non-commit paths (git-safe add stages but doesn't commit; check fires at commit time)

## Estimated
- 1 iteration, ~2h with tests. Single-tool addition.

Greenlight to proceed? Or defer pending other work?
