---
type: escalation
from: the-agency/jordan/captain
to: the-agency/jordan/iscp
date: 2026-04-06T06:54
status: created
priority: high
subject: "ESCALATION: dispatch create uses branch name for identity and payload path — PR branches break everything"
in_reply_to: null
---

# ESCALATION: dispatch create uses branch name for identity and payload path — PR branches break everything

When captain is on a PR branch (captain/valueflow-pvr-20260406), agent-identity resolves the branch slug as the agent name (valueflow-pvr-20260406 after stripping captain/ prefix). This causes: (1) from_agent is wrong in DB record, (2) payload written to usr/jordan/valueflow-pvr-20260406/dispatches/ instead of usr/jordan/captain/dispatches/, (3) directory auto-created where it shouldn't exist. This affects ANY agent on a non-worktree branch — PR branches, feature branches, etc. The .agency-agent file only exists in worktrees, not on PR branches from main. Root cause: agent-identity falls back to branch detection when no .agency-agent file exists. PR branches from main have no identity file. Fix options: (1) Captain always has .agency-agent on main checkout too (not just worktrees), (2) agent-identity treats any branch under captain/ prefix as captain, (3) Move dispatch payloads outside git entirely — alongside the ISCP DB at ~/.agency/{repo}/dispatches/. Option 3 is worth serious consideration: payloads in git cause branch-transparency issues (dispatch #20), template-vs-content confusion, and now path-derivation bugs. If payloads lived alongside the DB, all these problems vanish.
