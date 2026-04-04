# Discussion Transcript: Ghostty, Flag/Dispatch/ISCP, mdpal mining

**Date:** 2026-04-04
**Mode:** discussion
**Branch:** main
**Participants:** Jordan (principal), Captain (agent)

---

## Item 1: Ghostty contribution — current state

**Decision:** Ghostty contribution understood. State: vouched, forked, agency-init'd on ~/code/ghostty. Three-file ~20-line AppleScript change to expose titleOverride. Serves triple purpose: (1) fixes tab naming pain point, (2) validates agency-init on external repo, (3) demonstrates the-agency value in OSS contribution workflows.

---

## Item 2: Flag, dispatch, and ISCP

**Decision:** Flag becomes agent-addressable with SQLite persistence outside repo. Dispatch lifecycle formalized (create handles commit+propagate, fetch notifies). Code reviews deprecated as separate concept — just a dispatch type. ISCP v1 = a hook that fires on defined events, checks DB for unread items for this agent, surfaces "You got mail" with pointer. Dispatches ARE the ISCP. Shared DB pattern: SQLite with abstraction, outside git at ../{repo}/{TBD}/{database}.

**Open:** Addressing scheme not finalized for flag/dispatch. CLAUDE-THEAGENCY.md hierarchy ({org}/{repo}/{principal}/{agent}) is the starting point but needs formal resolution for these use cases. Add as Item 4 to this discussion.

**Action:** This becomes the plan seed for the ISCP agent spinning up 2026-04-05.

---

## Item 4: Addressing scheme for flag/dispatch

**Decision:** Two target types:
- **Agent:** `{repo}/{principal}/{agent}` → payload at `usr/{principal}/{agent-project}/dispatches/`
- **Workstream:** `{repo}/{workstream}` → payload at `claude/workstreams/{workstream}/dispatches/`. Repo-level, no principal scoping — matches `claude/workstreams/{name}/` hierarchy.
- **Flag:** DB-only, same addressing, no payload location.
- Bare forms resolve from context; disambiguate by checking workstream dir first, then agent registration.

**Action:** Dispatch this to the ISCP agent as foundational input for /define.

---

