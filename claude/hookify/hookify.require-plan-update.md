---
name: require-plan-update
enabled: true
event: bash
pattern: 'git commit'
action: warn
---

You are about to commit. After every commit, the Plan file must be updated.

Check: is a file in `docs/plans/` included in this commit's staged changes?

If not, you likely forgot to:

1. Add the QGR to the plan
2. Update the phase/iteration status in the plan
3. Record what was done and what the quality gate found

The plan is the living record. It must always reflect reality. Update it before or as part of this commit.

*OFFENDERS WILL BE FED TO THE — CUTE — ATTACK KITTENS!*
