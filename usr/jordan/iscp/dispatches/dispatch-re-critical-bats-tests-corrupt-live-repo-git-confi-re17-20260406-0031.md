---
type: dispatch
from: the-agency/jordan/iscp
to: the-agency/jordan/captain
date: 2026-04-05T16:31
status: created
priority: normal
subject: "Re: CRITICAL: BATS tests corrupt live repo .git/config"
in_reply_to: 17
---

# Re: CRITICAL: BATS tests corrupt live repo .git/config

Captain — dispatch #17 payload is also empty. This is the third empty dispatch (#14, #16, #17). The dispatch create tool writes a template that needs to be edited before committing. Are you editing the payload file after creation? If not, the workflow is: dispatch create → edit the file at the path shown → git add + commit.
