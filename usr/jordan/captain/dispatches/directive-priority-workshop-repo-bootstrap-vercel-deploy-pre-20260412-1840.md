---
type: directive
from: the-agency/jordan/captain
to: the-agency/jordan/devex
date: 2026-04-12T10:40
status: created
priority: normal
subject: "PRIORITY: Workshop repo + bootstrap + Vercel deploy + pre-flight checklist — Monday deadline"
in_reply_to: null
---

# PRIORITY: Workshop repo + bootstrap + Vercel deploy + pre-flight checklist — Monday deadline

Captain to DevEx. New priority task for the Monday workshop at Republic Polytechnic.

## 1. Workshop Repo (the-agency-ai/the-agency-workshop)

This is NOT an agency repo. It is a materials and collaboration space for workshop participants.

Structure:
```
the-agency-workshop/
  README.md              — what this repo is, how to use it
  sessions/              — one directory per workshop session
    republic-poly-20260413/   — this Monday's session
      README.md          — session-specific info (date, location, schedule)
      participants/      — one directory per participant (collaboration space)
      materials/         — handouts, slides export, bootstrap script
      CLAUDE.md          — workshop-specific Claude Code instructions
```

The CLAUDE.md should make a captain workshop-aware: knows the curriculum, guides participants through Valueflow steps (Seed → PVR → A&D → Plan → Execute → Deploy), knows the schedule, knows the toy project spec (personal page + mini-blog with Next.js + Tailwind → Vercel deploy).

The repo already exists on GitHub (the-agency-ai/the-agency-workshop) — it's empty. Clone it, scaffold it, push.

## 2. Bootstrap Script

We have an existing bootstrap script at claude/workstreams/agency/seeds/workshop-bootstrap.sh. Review it, clean it up, make sure it works on Ubuntu. It should install: Chrome/Chromium, Node.js, Claude Code, GitHub CLI. Test it if possible.

Put the working version in the workshop repo at sessions/republic-poly-20260413/materials/bootstrap.sh.

## 3. Vercel Deployment Flow

Verify end-to-end: create a Next.js project → push to GitHub → connect Vercel → deploy → get a live URL. Document the exact steps. This is what participants will do in Part 4 (Guided Build).

## 4. Pre-flight Checklist Slide

Create a simple, direct checklist that goes at the beginning of the workshop (the setup phase, 09:00-10:00). It should be:
- Have you run the bootstrap script? ✓
- Is Claude Code installed? (run: claude --version) ✓
- Are you logged in? (run: claude login) ✓
- Can you launch two sessions with remote-control? ✓
- Can you connect from Claude Desktop Code tab? ✓
- Do you have a GitHub account? ✓

Simple. Direct. Clear. If any step fails, flag for help.

## Context

Read these for full context:
- Workshop outline v2: agency/workstreams/agency/seeds/workshop-outline-republic-poly-v2-20260412.md
- Workshop setup guide: agency/workstreams/agency/seeds/workshop-setup-guide-20260410.md
- Bootstrap script: agency/workstreams/agency/seeds/workshop-bootstrap.sh
- Workshop start script: agency/workstreams/agency/seeds/workshop-start.sh
- Slide deck (current): agency/workstreams/mdslidepal/workshop-deck.md
- Workshop content transcript: usr/jordan/captain/transcripts/workshop-content-planning-20260412.md

## Deadline

Monday 13 April 2026 at 09:00. Everything must be ready and tested by Sunday night.

— the-agency/jordan/captain
