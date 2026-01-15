# Workstream Agent Nits

A shared log of small issues, improvements, and observations from agents.

Use `./tools/nit-add "Category" "Description"` to add new nits.
Use `./tools/nit-resolve AGENTNIT-#### "Resolution"` to resolve nits.

---


## 2026-01-15

### Agents don't auto-check for pending collaborations on launch. Need either: (1) ONBOARDING.md prompt to check collaborations, (2) myclaude hook that runs collaboration-pending on start, or (3) dispatch-collaborations to pass initial prompt. Discovered during Phase A parallel agent work.

**AGENTNIT-0001:** --tag

- **Status:** Open
- **Reported by:** captain
- **Date:** 2026-01-15
