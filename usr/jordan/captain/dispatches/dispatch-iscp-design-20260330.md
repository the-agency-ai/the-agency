# Dispatch: Design Intra-Session Communication Protocol (ISCP)

**Date:** 2026-03-30
**From:** CoS (monofolk)
**To:** Captain (the-agency)
**Priority:** High

---

## Directive

Design and build an Intra-Session Communication Protocol (ISCP) for The Agency.

## Background

Agency 1.0 attempted agent-to-agent communication via a local SQLite database (agency-service) with tools: `msg`, `dispatch`, `message-read`, `message-send`, `news-post`, `news-read`, `collaborate`, `collaboration-respond`.

**It didn't work.** The agency-service dependency was fragile, the message model was too complex, and agents didn't reliably use it. All v1 messaging tools are scrapped.

Agency 2.0 currently has file-based artifacts (dispatches, handoffs, reviews) for cross-agent communication, but these are asynchronous and one-directional. There is no real-time or near-real-time communication between running sessions.

## Requirements

### Must Have
1. **Intra-agency communication** — agents within the same Agency installation can send and receive messages during active sessions
2. **Cross-session** — agent A in one Claude Code session can communicate with agent B in another session
3. **Lightweight** — no heavy infrastructure (no database server, no API service that must be running)
4. **Reliable delivery** — messages are not lost if the recipient session is busy or temporarily unavailable
5. **Token-efficient** — receiving a message should not flood the recipient's context window
6. **Works with Claude Code hooks** — integrates with the existing hook system (UserPromptSubmit, PostToolUse, etc.) for message checking

### Should Have
7. **Message types** — at minimum: direct (agent-to-agent), broadcast (one-to-many), dispatch (directive with acknowledgement)
8. **Priority levels** — urgent (interrupt current work) vs normal (check at natural boundaries)
9. **Acknowledgement** — sender can know if recipient received/read the message
10. **Thread support** — related messages can be grouped

### Could Have
11. **Cross-agency communication** — agents in different Agency installations (different repos, different machines) can communicate
12. **Principal-to-agent messaging** — a human can send a message to a running agent session without switching to that terminal
13. **Message persistence** — conversation history survives session restarts

## Constraints

- Must not require agency-service or any running daemon
- Must work within Claude Code's hook/tool model
- Must follow the token-conservation pattern (minimal context impact)
- File-based approaches are fine if they're fast enough
- Should integrate with the handoff system (unread messages noted in handoff)

## Prior Art to Study

- **Agency 1.0 messaging** — what went wrong (tools/ msg, dispatch, etc. in this repo)
- **gstack session tracking** — `~/.gstack/sessions/$PPID` file-touch pattern for detecting active sessions
- **File-based IPC** — named pipes, file watches, lock files
- **Claude Code hooks** — what events can trigger message checks without adding latency

## Scrapped Tools (for reference, do not rebuild)

`msg`, `dispatch`, `dispatch-request`, `message-read`, `message-send`, `news-post`, `news-read`, `collaborate`, `collaboration-respond` — all Agency 1.0, all deprecated.

## Deliverables

1. ISCP design document (PVR + A&D)
2. Prototype implementation
3. Integration with handoff (unread messages in handoff)
4. Integration with hooks (message checking at natural boundaries)
