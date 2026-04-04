---
name: warn-script-persistence
enabled: true
event: Write
pattern: \.(sh|py)$
exclude_pattern: usr/.*/tools/|claude/tools/|/tmp/
action: warn
---

Script written outside `tools/` directories. Save reusable scripts to `usr/{principal}/{project}/tools/` with a header:

```
# Why did I write this script: <purpose and context>
# Written: YYYY-MM-DD during <phase/task>
```

Framework tools go to `claude/tools/`. See CLAUDE-THEAGENCY.md#script-discipline.

**Scope limitation:** This rule catches Write tool calls to `.sh`/`.py` files. It does NOT catch heredocs in Bash tool calls, scripts without extensions, or writes to `tmp/`. It is a nudge, not a gate — pair with telemetry for full observability.

*OFFENDERS WILL BE FED TO THE — CUTE — ATTACK KITTENS!*
