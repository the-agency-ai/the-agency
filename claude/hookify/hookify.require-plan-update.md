---
name: require-plan-update
enabled: true
event: bash
pattern: 'git commit'
action: warn
---

Update the Plan file with this commit — QGR, phase/iteration status, findings. See CLAUDE-THEAGENCY.md#development-methodology — FEAR THE KITTENS!
