# WORKNOTE: Max Del Vita Meeting - The Agency Overview & Walk-Through

**Date:** 2026-01-15
**Attendees:** Jordan, Max Del Vita (Claude Code SG Meetup co-founder)
**Purpose:** The Agency overview and meetup presentation planning
**Transcript:** https://notes.granola.ai/t/e75a6518-ecd1-4854-9cbb-cfa81516c0d6-00demib2

---

## Context

Max is the co-leader and co-founder of the Claude Code SG meetup. Jordan will be presenting The Agency at the meetup next Friday.

---

## The Agency Framework Introduction

- Jordan's solo AI development framework built in 7 days during job interview process
- Open source (MIT license) with opinionated, convention-over-configuration approach
- Solves 4 core problems:
  1. Lack of SDLC for AI-augmented development
  2. Scattered tools requiring curation
  3. Context window pollution from tool outputs
  4. Balance between YOLO mode and approval fatigue

---

## Core Architecture & Services

- Service-oriented architecture with multiple integrated components
- **Secret Service:** Local encrypted token/API key management using SQLite
- **Knowledge Index:** Simple search service for agents to query documents
- **iTerm integration:** Color-coded window status (blue=available, green=working, red=attention)
- **Message queue system:** Coming for multi-agent coordination
- **Agency Bench:** Desktop app (built with Tauri) for document management and markup

---

## Development Workflow & Project Structure

- Two project types with structured breakdown:
  1. **Products:** Vision → Epics → Sprints → Iterations → Tasks
  2. **Projects:** Request → Phases → Tasks
- Collaborative authoring at vision/epic level, AI handles execution
- Sequential guided, sequential autonomous, or parallel execution modes
- Tool logging architecture maintains context across all interactions
- Built-in CI/CD, automated testing, and localization from start

---

## Frameworks Max Is Looking At

| Framework | Description | Link |
|-----------|-------------|------|
| **BMAD-METHOD** | Open source using YAML/MD files with orchestrator and specialized agents (UX researcher, etc.) | https://github.com/bmad-code-org/BMAD-METHOD |
| **Spec Kit** | GitHub's project using spec-driven development approach | https://github.com/github/spec-kit |
| **Claude Conductor** | Sequential agent-based development for greenfield projects | https://github.com/superbasicstudio/claude-conductor |

**Max's observation:** Some frameworks reinvent waterfall vs Jordan's disciplined agile approach

---

## Commercial Strategy & Launch Plans

- Announcement at upcoming meetup with E27 press coverage
- Free open source starter

---

## Max's Positive Reactions

### Overall / Agency concept
- "Very interesting."
- "No, I think. I think it's. It's a very interesting project, to be honest."
- "Super, super interesting."

### Opinionated, convention-over-configuration approach
- "It's a very interesting angle, to be honest. Like, it's like. It's, like, super. It's different and it's interesting."

### Secret Service (local encrypted secrets management)
- "Nice."
- "Very interesting."

### iTerm integration / tooling setup
- "Oh, very cool."

### Agency Bench desktop app (Tauri-based) and artifacts workflow
- "Wow."
- "That's interesting."
- "No, it's. It's super. I mean. Super, super interesting."

### Structured product/project workflow & AI-augmented SDLC
- "Clear."
- "Nice."
- "Makes sense. Makes sense."
- "Yeah, makes sense. Makes sense. Okay. Yeah, no, that's really cool."

### Mark & Mock iOS app for sketching/marking screenshots into Claude
- "Very interesting."

### FIGMA/design-system ingestion to boost fidelity
- "Yeah. So solving that whole problem there and that workflow problem."

### Open source + contributor model
- "So I think this stuff is super interesting, right, because it is a different point of view on this world…"

### Launch/meetup presence
- Encouraged Jordan to talk about:
  - How he built it with Claude
  - Disciplined, non-"vibe coding" approach
- "That's super, super interesting."

---

## Action Items

- [ ] Jordan to present The Agency at Claude Code SG meetup (next Friday)
- [ ] E27 press coverage coordinated for announcement
- [ ] Review competitor frameworks (BMAD-METHOD, Spec Kit, Claude Conductor)

---

*Captured from meeting notes - 2026-01-15*
