# CLAUDE-MOCK-AND-MARK.md — mock-and-mark workstream

The **mock-and-mark** workstream builds **Mock and Mark** — an iPad-native visual communication tool for Claude Code. The idea: when a human wants to communicate a visual intent to an agent (a layout sketch, a mark-up on a screenshot, a diagram, a pointing arrow), they should be able to do it naturally on an iPad with a stylus, and the agent should get the image with context attached.

## Purpose

AIADLC lives in text but human visual thinking does not. A quick sketch on an iPad is often worth more than five paragraphs of description, especially for UI, architecture, and layout. Mock and Mark closes the gap: sketch on iPad, the image flows into the Claude Code session with the right context attached, the agent understands the visual intent without the human having to translate it into words.

## Scope

- **In scope:** iPad-native drawing surface, stylus support, screenshot markup, diagram templates, capture-and-send to Claude Code session, context packing (which session, which file, which line), round-trip integration with Claude Code.
- **Licensing:** Reference Source License per-directory. Not MIT like the framework.
- **Out of scope:** full-blown vector illustration (use a real illustration tool), general-purpose note-taking (Obsidian, Notability), non-iPad platforms for v1. Mock and Mark is specifically about the iPad-to-Claude-Code round trip.

## Agent

- **mock-and-mark** — the single agent for this workstream. Worktree status: dormant as of 2026-04-09 (see fleet health report). Requires reactivation before active development resumes.

## Conventions

- **Native iOS/iPadOS** — Swift, SwiftUI, PencilKit. No web wrapping.
- **Minimal surface, maximum fluency** — the entire value proposition is "sketch and send." Features that don't serve that round trip are deferred.
- **Claude Code session awareness** — every capture carries context (which session, which agent, which file the sketch is about). This is not just "take a photo and paste" — it's a first-class input channel for agents.

## Status

Workstream exists but dormant. Needs a reactivation decision: either formally resume development with a fresh PVR/A&D cycle, or archive and reclaim the slot. Surfaced in the 2026-04-09 fleet health report. Decision pending principal review.

## Related

- `claude/workstreams/mock-and-mark/LICENSE` — Reference Source License
- PVR, A&D, Plan at the workstream root (status unknown until reactivation review)

*OFFENDERS WILL BE FED TO THE — CUTE — ATTACK KITTENS!*
