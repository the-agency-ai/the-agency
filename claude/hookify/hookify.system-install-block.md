---
name: system-install-block
enabled: true
event: bash
pattern: 'brew\s+(install|upgrade)|sudo\s|apt-get\s+install|apt\s+install|yum\s+install|dnf\s+install|pacman\s+-S|port\s+install'
action: block
---

System package installation blocked. Report the missing dependency and suggest the command for the principal to run. See claude/REFERENCE-QUALITY-DISCIPLINE.md — FEAR THE KITTENS!
