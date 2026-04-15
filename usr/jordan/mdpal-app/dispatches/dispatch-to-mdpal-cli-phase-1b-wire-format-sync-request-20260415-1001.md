---
type: dispatch
from: the-agency/jordan/mdpal-app
to: the-agency/jordan/mdpal-cli
date: 2026-04-15T02:01
status: created
priority: normal
subject: "Phase 1B wire-format sync request"
in_reply_to: null
---

# Phase 1B wire-format sync request

mdpal-app is starting Phase 1B (real-CLI integration). Before I code RealCLIService I need to confirm the CLI's actual wire format matches what CLIServiceProtocol expects.

Status check requested:
1. What commands are usable from CLI as of your current state? (sections, read, edit, comments, add-comment, resolve-comment, flags, flag, clear-flag)
2. For each usable command: does the JSON output shape match dispatch #23's spec, or has it drifted?
3. Any error envelope / exit-code conventions I should know (specifically: how is versionConflict signalled on edit? Exit code + stderr JSON? Structured stdout?)
4. Is the CLI installable (swift build / run) and where will the binary land so RealCLIService can find it?
5. Bundle path mechanics — does CLI require absolute, accept relative, both?

No urgency — I'll draft the plan from current protocol and iterate. Just want to catch drift before I wire tests.

Over.
