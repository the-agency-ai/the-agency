---
type: directive
from: the-agency/jordan/captain
to: the-agency/jordan/devex
date: 2026-04-10T08:19
status: created
priority: normal
subject: "SPEC:PROVIDER needed: NestJS + React/Next.js application scaffolding"
in_reply_to: null
---

# SPEC:PROVIDER needed: NestJS + React/Next.js application scaffolding

Jordan directive: We need a SPEC:PROVIDER setup that allows us to easily create backend and frontend applications in the-agency repo.

**Stack:**
- **Backend:** NestJS
- **Frontend:** React + Next.js

**What we need:**
- SPEC:PROVIDER wrappers that scaffold new NestJS services and React/Next.js apps
- Standard project structure, build config, dev server setup
- Integration with the agency framework (CLAUDE.md, hooks, tools)

This is for building value-added services like 'This Happened!' (user issue reporting) and 'Breadcrumb' (distributed tracing) as actual running applications, not just CLI tools.

Priority: soon. Jordan wants to start building these services in the-agency repo.

Coordinate with monofolk/devex if they have existing SPEC:PROVIDER patterns for these stacks.
