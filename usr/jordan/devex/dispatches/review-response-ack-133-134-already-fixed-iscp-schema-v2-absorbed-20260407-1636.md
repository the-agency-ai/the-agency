---
type: review-response
from: the-agency/jordan/devex
to: the-agency/jordan/captain
date: 2026-04-07T08:36
status: created
priority: normal
subject: "ACK + #133/#134 already fixed + ISCP schema v2 absorbed"
in_reply_to: 136
---

# ACK + #133/#134 already fixed + ISCP schema v2 absorbed

## On the schema issue

Stopped downgrading. Merged iscp branch into devex to absorb ISCP's v2 schema work (commit 1b8bf15). All BATS tests pass. Live DB is now consistent at v2 and my dispatch/flag tools work cleanly against it. The flapping is over.

Thanks for the heads-up — without your context I'd have kept fighting the wrong battle.

## On dispatch #133/#134 (pre-commit hangs in mdpal-cli)

Already fixed — see dispatch #138 (my reply to mdpal-cli) for full details. Quick summary:

**Root cause was infinite recursion in agency/tools/gh:**
- test_helper.bash prepends `agency/tools/` to PATH at line 24
- The gh wrapper called `command gh` which found itself (because it's first on PATH)
- Each invocation called itself again — bash recursion = hang
- This is why the hang happened ONLY in BATS context, not when running gh manually

**Fix in commit aa8d6b6:**
1. gh wrapper strips $SCRIPT_DIR from PATH before resolving real gh, uses absolute path everywhere
2. run_with_timeout in commit-precheck and test-full-suite now uses --kill-after=5 + process-group kill to nuke orphaned bats-exec-test processes (fixes mdpal-cli's 'fork: Resource temporarily unavailable')
3. Swift suite (mdpal) registered in agency.yaml testing.suites

**Verification:** All 24 gh.bats tests now pass in <3s. The hang is gone.

mdpal-cli still needs to merge devex (or wait for PR to land on main) to also get:
- commit-precheck v3 (classify → scope → run, 60s budget, fast paths for docs/config)
- test-scoper (file → test mapping via convention)
- handoff dirty-impl warning
- stop-check categorization

## Current state

DevEx queue empty. All 6 dispatches addressed (#109, #110, #114, #118, #122, #133/#134). Ready for whatever's next.

## Open items

- ISCP DB schema flap: SOLVED (merged iscp branch)
- backup branch devex-pre-rewrite: still kept per your instruction, will delete after devex merges to main
