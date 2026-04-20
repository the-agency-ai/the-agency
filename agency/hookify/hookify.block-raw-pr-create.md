---
name: block-raw-pr-create
enabled: true
event: bash
pattern: 'gh pr create'
action: block
---

BLOCKED: Raw `gh pr create` is not allowed. Use `/ship` or `./agency/tools/pr-create` instead.

Every PR requires a Quality Gate Report (QGR). The tools check for a QGR receipt before allowing PR creation. Run `/pr-prep` first, then `/ship`.

Flow: /pr-prep (runs QG → produces QGR) → /ship (creates PR with QGR proof)

OFFENDERS WILL BE FED TO THE — CUTE — ATTACK KITTENS!
