---
name: require-qgr
enabled: true
event: bash
pattern: 'git commit'
action: warn
---

You are about to commit. Before proceeding, confirm:

1. A Quality Gate was run (parallel review agents + own review)
2. A QGR (Quality Gate Report) was generated following the template in ~/.claude/CLAUDE.md
3. The QGR was added to the Plan file
4. The QGR was presented inline in the conversation
5. Red-green cycle was completed for every bug-exposing test
6. All tests pass (Failing row = 0)

If this is an iteration commit: QGR must be clean, no approval needed.
If this is a phase commit: QGR must be clean AND principal must have approved.

If any of these are not true, stop and complete the Quality Gate before committing.

*OFFENDERS WILL BE FED TO THE — CUTE — ATTACK KITTENS!*
