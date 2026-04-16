# Periodic Claude Code Message Check Mechanisms

**Created:** 2026-01-15
**Context:** REQUEST-0053 Phase A parallel agent coordination
**Related:** claude-code-startup-behavior.md, AGENTNIT-0002

---

## The Problem

Multiple Claude Code instances need to coordinate via messages. This requires them to periodically check for messages addressed to them.

## Key Finding

**Claude Code does not natively support idle polling or periodic background checks.** Sessions are turn-based - they wait for user input and cannot autonomously poll while idle.

---

## Native Limitations

- Sessions are fundamentally turn-based: wait for user input, cannot autonomously poll
- Hooks (like SessionStart) only fire at defined lifecycle events, not on a timer
- No built-in scheduler or background thread to wake agent for message checks

---

## Workarounds

### 1. File-Based Message Queue (AMQ)

[Agent Message Queue](https://github.com/avivsinai/agent-message-queue) - purpose-built for this:

- Maildir-style file-based messaging system
- Enables async coordination between Claude Code instances
- Works by injecting messages through tty
- Still requires trigger to check messages

### 2. MCP Server Approach

Claude Code can connect to MCP servers:

- Build custom MCP server with `check_messages` tool
- Pattern: Orchestrator → MCP Server → Message Queue → Claude instances
- Still needs trigger (user prompt or wrapper) to invoke the tool

### 3. Wrapper Script with Timer

```bash
#!/bin/bash
# Periodically send check prompt to Claude session via pty/expect
while true; do
  sleep 300  # 5 minutes
  # Send to Claude session: "Check the message queue for tasks addressed to you"
done
```

**Limitation:** Requires external process management

### 4. GitHub Actions Scheduler

- Queue tasks via GitHub issues that tag @claude
- Scheduled workflow creates issues after delays
- **Limitation:** Not real-time, relies on GitHub infrastructure

### 5. Todo-List Loop (Autonomous)

Use `/todo-all` pattern where one task is always "check message queue":

```
1. Do assigned work
2. Check message queue for new tasks
3. Repeat
```

**Limitation:** Agent must be actively running a task loop

### 6. File Watcher Daemon

```bash
# Use inotify/fswatch on message directory
fswatch -o /path/to/messages | while read; do
  # Poke Claude session when new messages arrive
done
```

**Limitation:** Requires external file-watcher daemon

---

## Recommended Pattern for The Agency

### Architecture

```
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│  Claude Code    │     │  Message Queue  │     │  Claude Code    │
│  (Agent A)      │────▶│  (news/collab)  │◀────│  (Agent B)      │
└─────────────────┘     └─────────────────┘     └─────────────────┘
        │                       ▲                       │
        │                       │                       │
        ▼                       │                       ▼
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│  SessionStart   │     │   Coordinator   │     │  SessionStart   │
│  Hook (check)   │     │   (captain)     │     │  Hook (check)   │
└─────────────────┘     └─────────────────┘     └─────────────────┘
```

### Implementation Layers

1. **Message Store:** Our existing `news-post`/`news-read` and collaboration system (git-based)

2. **Session Start Check:** Already implemented in `.claude/hooks/session-start.sh`:
   ```bash
   NEWS_OUTPUT=$("$REPO_ROOT/tools/news-read" --quiet 2>/dev/null)
   COLLAB_OUTPUT=$("$REPO_ROOT/tools/collaboration-pending" 2>/dev/null)
   ```

3. **Autonomous Task Loop:** Agents can be instructed to periodically check:
   ```
   "After completing each major task, run ./tools/news-read to check for messages"
   ```

4. **External Poke (Future):** Lightweight daemon that watches queue and injects prompts

---

## Current Implementation in The Agency

### What We Have

- `./tools/news-post` / `./tools/news-read` - Broadcast messages
- `./tools/collaborate` / `./tools/collaboration-respond` - Direct requests
- SessionStart hook checks both on startup

### What's Missing

- No periodic check during long-running work
- No idle-time polling
- Agents must be prompted to check

### Future Options (Choreography Service)

1. **MCP Integration:** Build MCP server for real-time message delivery
2. **agency-service WebSocket:** Push notifications to agents
3. **Task Loop Pattern:** Standard instruction to check after each task
4. **File Watcher:** Daemon that pokes agents when messages arrive

---

## References

- https://github.com/avivsinai/agent-message-queue (AMQ)
- https://www.anthropic.com/engineering/claude-code-best-practices
- https://www.ksred.com/claude-code-as-an-mcp-server/
- https://motlin.com/blog/claude-code-running-for-hours (todo-all pattern)
- https://code.claude.com/docs/en/mcp

---

## Related Knowledge

- `claude-code-startup-behavior.md` - SessionStart limitations
- AGENTNIT-0001: No auto-check on launch
- AGENTNIT-0002: Need message checking during work
