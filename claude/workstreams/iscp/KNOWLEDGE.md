# ISCP — Workstream Knowledge

Inter-Session Communication Protocol: flag, dispatch, and agent-to-agent messaging.

## Patterns and Conventions

<!-- Accumulate patterns discovered during development -->

## Key Decisions

- Flag = agent-addressable, SQLite-backed outside repo, `/flag [agent] TEXT` syntax
- Dispatch = notification in DB + payload in git, full lifecycle (create→commit→propagate→fetch→notify)
- ISCP v1 = hook on defined events, checks DB for unread items, "you got mail" notification
- Code reviews are just a dispatch type, not a separate system
- DB pattern: SQLite with abstraction layer, outside git at `../{repo}/{TBD}/{database}`
- Cross-repo/cross-agency dispatch support planned (monofolk ↔ the-agency ↔ ghostty)
- Addressing: agent-based and workstream-based, using Agency addressing hierarchy
