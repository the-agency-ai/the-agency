---
name: warn-raw-grep
enabled: true
event: bash
pattern: \bgrep\s+|\brg\s+
action: warn
---

Use the Grep tool instead of `grep`/`rg`. See CLAUDE.md#bash-tool-usage — FEAR THE KITTENS!
