---
name: block-no-verify
enabled: true
event: bash
pattern: --no-verify
action: block
---

**Skipping hooks is not allowed.**

The `--no-verify` flag bypasses pre-commit hooks. If a hook fails, investigate and fix the underlying issue instead of skipping it.
