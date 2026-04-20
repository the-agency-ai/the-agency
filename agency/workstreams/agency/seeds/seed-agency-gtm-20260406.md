---
type: seed
date: 2026-04-06
from: the-agency/jordan/captain
subject: "Agency GTM — technical requirements for open source launch"
---

# Agency GTM Seed

## What This Is

Technical requirements tied to launching TheAgency as an open source platform.

## Requirements

### 1. Vouch Model (from Ghostty)

Adopt Ghostty's CONTRIBUTING and AI-POLICY model for AI contributions. Every AI-generated contribution must be vouched for by a human — reviewed, understood, and attested. Look at Ghostty's docs as starting points for our own.

- Reference: https://github.com/ghostty-org/ghostty/blob/main/CONTRIBUTING.md
- Reference: https://github.com/ghostty-org/ghostty/blob/main/AI-POLICY.md

### 2. Starter Repo Redirect

the-agency-starter is sunset. agency-init replaces it. Need to:
- Retarget everyone following/starred the-agency-starter to the-agency
- Archive the-agency-starter with a prominent redirect notice
- **Jordan action:** GitHub notification/redirect setup

### 3. X/Twitter Presence

@AgencyGroupAI account exists (premium). Technical work needed:
- **Jordan action:** Set up X developer account at developer.x.com, Basic tier for API read access
- Build X/Twitter MCP server or tool integration (post articles, read mentions, search)
- Captain monitoring of @AgencyGroupAI — community engagement
- Explore what we can do with X API for monitoring and engagement

### 4. Licensing

Open core model defined (MIT framework, source-available apps). Need:
- LICENSE files created in each directory (not yet done — see memory: project_license_files_todo.md)
- CONTRIBUTING.md with vouch model (item 1)
- AI-POLICY.md

### 5. Content Pipeline

Private repo the-agency-ai/the-agency-content exists. Articles, book, workshops. Agency model.
- "We Have To Talk" article seed exists in the-agency-group
- Need content workflow defined
