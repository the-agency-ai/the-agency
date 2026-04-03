---
name: block-system-install
enabled: true
event: bash
pattern: 'brew\s+(install|upgrade)|sudo\s|apt-get\s+install|apt\s+install|yum\s+install|dnf\s+install|pacman\s+-S|port\s+install'
action: block
---

System package installation blocked. Report the missing dependency and suggest the command for the principal to run. See CLAUDE-THEAGENCY.md#testing--quality-discipline — FEAR THE KITTENS!
