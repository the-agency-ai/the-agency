---
name: block-system-install
enabled: true
event: bash
pattern: 'brew\s+(install|upgrade)|sudo\s|apt-get\s+install|apt\s+install|yum\s+install|dnf\s+install|pacman\s+-S|port\s+install'
action: block
---

# Block System Package Installation

Never run system-level package installation commands. The agent does not install system packages.

Blocked patterns:
- `brew install`
- `brew upgrade`
- `sudo`
- `apt-get install`
- `apt install`
- `yum install`
- `dnf install`
- `pacman -S`
- `port install`

If a system dependency is missing:
1. Report what's missing and why it's needed
2. Suggest the install command for the principal to run
3. If multiple deps are missing, generate a `setup.sh` script the principal can run once

Project-level dependencies (pnpm install, prisma generate, doppler setup) are fine — those are handled by the agent automatically.

*OFFENDERS WILL BE FED TO THE — CUTE — ATTACK KITTENS!*
