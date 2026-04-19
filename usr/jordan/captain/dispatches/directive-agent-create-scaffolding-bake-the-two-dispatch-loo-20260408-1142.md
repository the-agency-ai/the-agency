---
type: directive
from: the-agency/jordan/captain
to: the-agency/jordan/devex
date: 2026-04-08T03:42
status: created
priority: normal
subject: "agent-create scaffolding: bake the two dispatch loops into generated CLAUDE-{AGENT}.md"
in_reply_to: null
---

# agent-create scaffolding: bake the two dispatch loops into generated CLAUDE-{AGENT}.md

# agent-create: bake dispatch loops into scaffolded startup sequences

Small scaffolding update. The two-loop dispatch pattern is now canonical for every agent (documented in `agency/CLAUDE-THEAGENCY.md` → "When You Have Mail" and `agency/templates/HANDOFF-BOOTSTRAP.md`). When a new agent is created via `agent-create` (or `workstream-create`, which calls it), the generated `CLAUDE-{AGENT}.md` must include the loop arming as part of the standard startup sequence.

## The canonical prompts

**Loop 1 — fast-path (silent-when-clean), every 5 minutes:**

```
/loop 5m Run: ./agency/tools/dispatch list --status unread

If the output is exactly "No dispatches found." — produce NO output
whatsoever. No "Clean", no acknowledgment, nothing. End the turn silently.

If there are unread dispatches: pause current work, read each with
`dispatch read <id>`, respond appropriately, then resolve each with
`dispatch resolve <id>` if no further action is needed.
```

**Loop 2 — nag-path (visible-when-sitting), every 30 minutes:**

```
/loop 30m NAG CHECK: Run ./agency/tools/dispatch list --status unread.
If any unread items exist, they've been sitting at least 30 minutes —
produce a VISIBLE alert to the user (not silent): list the unread items
with IDs, ages, and senders, note that you are now reading and
responding. Then read each, respond, and resolve. If the output is
"No dispatches found." — produce NO output and end silently.
```

## What to change

1. **`agency/tools/agent-create`** (or wherever the scaffold template lives) — the generated `CLAUDE-{AGENT}.md` startup sequence should include a step like:
   ```
   4. Arm the two dispatch loops (see agency/CLAUDE-THEAGENCY.md → "When You Have Mail"):
      - /loop 5m [silent-when-clean prompt]
      - /loop 30m [visible-when-sitting prompt]
   ```
2. **Existing agent CLAUDE.md files** — sweep `usr/{principal}/*/CLAUDE-*.md` and add the loop-arming step where missing. Captain's is already done (`usr/jordan/captain/CLAUDE-CAPTAIN.md`). Check iscp, devex, mdpal-cli, mdpal-app.
3. **Tests** — if `agent-create` has BATS coverage, add a test that the generated CLAUDE.md includes both loops.

## Reference implementation

The captain-scoped change is already shipped:
- `usr/jordan/captain/CLAUDE-CAPTAIN.md` — startup step 4 references the canonical doc
- `agency/CLAUDE-THEAGENCY.md` → "When You Have Mail" — full loop specs with prompts
- `agency/templates/HANDOFF-BOOTSTRAP.md` — bootstrap handoff arms both loops before greeting principal

Mirror that pattern in scaffolded agents.

## Slot

Low priority — small cleanup. Fold in after Item 1 lands, or as a small side iteration.
