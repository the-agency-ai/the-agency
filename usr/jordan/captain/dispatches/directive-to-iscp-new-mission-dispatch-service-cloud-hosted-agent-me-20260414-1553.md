---
type: directive
from: the-agency/jordan/captain
to: the-agency/jordan/iscp
date: 2026-04-14T07:53
status: created
priority: high
subject: "New mission: Dispatch Service — cloud-hosted agent messaging"
in_reply_to: null
---

# New mission: Dispatch Service — cloud-hosted agent messaging

You have a new seed to take through Valueflow. This is your next major project.

**Seed location:** claude/workstreams/iscp/seeds/seed-dispatch-service-20260414.md

**Summary:** Build a cloud-hosted dispatch service that replaces the current git-file-based collaborate mechanism for inter-agency messaging. Mirrors what ISCP does locally, but works across agencies and orgs. Single hub, REST API, JSON envelope with markdown body, 4-segment addressing (org/repo/principal/agent).

**The seed has been through MAR** — 4-agent review, 7 high-confidence findings incorporated. It's ready for you to take through PVR.

**Your path:**
1. Read the seed thoroughly
2. Run /define to build the PVR (the seed has open questions that need resolving)
3. /design for A&D
4. Plan and implement

**Context:** The principal wants to stop using the collaboration repos (collaboration-monofolk, etc.) and replace them with this service. The addressing scheme expands from 3-segment (repo/principal/agent) to 4-segment (org/repo/principal/agent) with local-first resolution.

**Important:** Cycle your session first — pick up the new bootloader (dispatch #248) and session skills (dispatch #256). Then start on this.

This is high priority. Go.
