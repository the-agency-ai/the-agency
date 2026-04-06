# Handoff Spec — Day 31 Reboot

Write your handoff now. This is the document that will bootstrap you on your next startup — fresh session, no resume. Make it count.

## File Location

Write to your handoff file using the handoff tool:
```
bash ./claude/tools/handoff write --trigger reboot
```

Then edit the file at: `usr/jordan/{project}/{agent}-handoff.md`

## Structure

Use this exact structure. Fill in every section. No TODOs, no placeholders.

```markdown
---
type: handoff
agent: {your fully qualified address}
workstream: {your workstream}
date: 2026-04-06
trigger: reboot
---

## Identity

Who you are. Your fully qualified address, your workstream, your role in one sentence.

## Current State

What stage of work are you in? What phase/iteration? What was the last thing you did? What's the state of your artifacts (PVR, A&D, Plan, code)?

Be specific: commit hashes, file paths, dispatch IDs.

## Valueflow Context

The methodology you operate under:
- PVR: claude/workstreams/agency/valueflow-pvr-20260406.md
- A&D: claude/workstreams/agency/valueflow-ad-20260406.md
- MAR dispositions: claude/workstreams/agency/reviews/

Read the A&D on startup — it defines how you work.

## Active Work

What's in progress right now? What's blocked? What were you working on when you stopped?

List specific files you were editing, dispatches you were processing, reviews you were responding to.

## Key Decisions

Decisions made during your session that a fresh instance needs to know. Not everything — just the ones that would change how you approach the work.

## Open Items

What's unfinished? What needs attention on restart? Dispatches to respond to, reviews to complete, bugs to fix?

## Startup Actions

On your next startup, do these in order:
1. Set dispatch loop: /loop 5m dispatch check
2. Process unread dispatches: dispatch list
3. Process unread flags: flag list
4. Read the valueflow A&D: claude/workstreams/agency/valueflow-ad-20260406.md
5. Resume from [your specific next action]
```

## Rules

1. **Be specific, not general.** "Working on tests" is useless. "Implementing convention-based test scoping in claude/tools/commit-precheck, T1 tier with 60s budget" is useful.

2. **Include file paths.** A fresh instance doesn't know where things are. Give it paths.

3. **Include dispatch IDs.** If you have unprocessed dispatches, list the IDs.

4. **Don't dump your whole session.** This is a bootstrap document, not a transcript. What does a fresh instance need to pick up where you left off?

5. **Commit your handoff.** `git add` your handoff file and commit it to your branch before shutting down.

6. **Under 100 lines.** If it's longer, you're including too much. Summarize. Link to artifacts for detail.
