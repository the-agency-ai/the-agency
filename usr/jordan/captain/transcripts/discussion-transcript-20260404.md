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
- **Workstream:** `{repo}/{workstream}` → payload at `agency/workstreams/{workstream}/dispatches/`. Repo-level, no principal scoping — matches `agency/workstreams/{name}/` hierarchy.
- **Flag:** DB-only, same addressing, no payload location.
- Bare forms resolve from context; disambiguate by checking workstream dir first, then agent registration.

**Action:** Dispatch this to the ISCP agent as foundational input for /define.

---

## Item 3: mdpal bootstrap transcript mining findings

Mining results from mdpal-cli (session ac938883) and mdpal-app (session 41066ba7), plus presence-detect sessions. Key findings:

1. **Worktree/master path confusion is systemic** — mdpal-app used master paths 66 times vs worktree paths 13 times. #1 friction source.
2. **"Act on startup" doesn't work** — mdpal-cli said "Ready." and waited. Passive directives not treated as imperative.
3. **Principal resolution bug** — dispatch-create and handoff tools resolved to testuser in both sessions.
4. **Bootstrap chicken-and-egg** — agent registrations didn't reference handoffs, handoffs weren't on worktree yet.
5. **1B1 and transcript discipline broke repeatedly** — both agents blasted through items, summarized instead of capturing.
6. **No versioning convention communicated** — agent tried to overwrite PVR in-place.
7. **agency-init broken in the field** (presence-detect) — wrong principal mapping, tools not shipped, permissions not pre-approved.

Full findings written to `usr/jordan/iscp/seeds/mdpal-bootstrap-mining-20260404.md` as ISCP seed.

**Decision:** Findings inform ISCP design directly. Worktree/master path confusion is what ISCP+dropbox solves. Bootstrap issues feed back into agency-init improvements.

---

