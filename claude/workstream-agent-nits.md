# Workstream Agent Nits

A shared log of small issues, improvements, and observations from agents.

Use `./tools/nit-add "Category" "Description"` to add new nits.
Use `./tools/nit-resolve AGENTNIT-#### "Resolution"` to resolve nits.

---


## 2026-01-15

### AGENTNIT-0001: Agent Auto-Activation on Launch

**Category:** agent-onboarding, collaboration

Agents don't auto-check for pending collaborations on launch. Need either:
1. ONBOARDING.md prompt to check collaborations
2. myclaude hook that runs collaboration-pending on start
3. dispatch-collaborations to pass initial prompt

**Context:** Discovered during Phase A parallel agent work. Part of choreography service.

- **Status:** Open
- **Reported by:** captain
- **Date:** 2026-01-15

---

### AGENTNIT-0002: Agent Message Checking During Work

**Category:** agent-communication, collaboration, choreography

Agents need a mechanism to check for messages/updates at suitable points during work. Options:
1. Periodic check every N tool calls
2. Check before committing
3. news-read integration
4. Polling loop

**Context:** Part of choreography service - coordinating multiple agents, status updates, inter-agent communication. Related to AGENTNIT-0001.

- **Status:** Open
- **Reported by:** captain
- **Date:** 2026-01-15

### Agent identity confusion

**AGENTNIT-0003:** Tools (news-post, news-read, collaboration-respond) misidentify agent identity. foundation-alpha's actions attributed to foundation-beta. Likely AGENTNAME env var not set correctly when tools invoked. Discovered during Phase A parallel work - caused COLLABORATE-0001 response confusion.

- **Status:** Open
- **Reported by:** captain
- **Date:** 2026-01-15
