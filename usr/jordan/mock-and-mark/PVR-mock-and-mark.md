# Mock and Mark — Product Vision Review (PVR)

**Date:** 2026-03-29
**Agent:** mock-and-mark
**Principal:** jordan
**Status:** In Progress
**Transcript:** `transcripts/PVR-transcript-20260329.md`

---

## Decisions

### 1. Product Name
"Mock and Mark" is the canonical name everywhere — agent, workstream, worktree, docs.

### 2. Target Platform
Primary target is Claude Code within the Claude App (Chat, Cowork, Code). Packet format optimized for Claude Code's coding workflow. No compromises for other targets.

### 3. Distribution Strategy
Graduated rollout: internal only (Xcode direct) → TestFlight → App Store. No App Store constraints imposed on early phases.

### 4. AI and Network Policy
No cloud AI APIs. On-device Apple AI (Vision, CoreML, etc.) encouraged. Core features work offline as a consequence. Network permitted for sync and delivery (iCloud, companion handoff).

### 5. Phase Roadmap
Phases in order, no fixed timelines — ship when ready:
1. **Mark** — iPad, annotate screenshots
2. **Mock** — iPad, sketch → lo-fi wireframes
3. **iCloud sync** — bidirectional iPad ↔ Mac (critical infrastructure)
4. **Flow diagrams** — multi-screen navigation flows
5. **Figma import** — TBD, see how it fits
6. **macOS app** — later, once iPad is solid

### 6. Collaboration
Out of scope. No current value seen. Solo developer tool.

### 7. Accessibility and Localization
Follow platform conventions. No anti-patterns. Take what SwiftUI gives. No special work for Apple Pencil accessibility. Same for localization. Assess when App Store time comes.

### 8. Export Packet Schema
*Pending*

### 9. Vision Framework Realism
*Pending*

### 10. Scope Guard for Phase 1
*Pending*
