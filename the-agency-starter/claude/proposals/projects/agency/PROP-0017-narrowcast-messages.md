# PROP-0017: Narrowcast Messages — Subscriptions Over Broadcast

**Status:** draft
**Priority:** medium
**Created:** 2026-01-06
**Author:** jordan + housekeeping
**Project:** agency

---

## Problem

Current NEWS system is broadcast-only:
- `./tools/post-news` broadcasts to ALL agents
- `./tools/read-news` shows ALL messages
- Agents read news that may not be relevant to them
- Token waste reading irrelevant updates
- Signal-to-noise ratio degrades as Agency scales

## Proposal

Replace broadcast with **narrowcast** — agents subscribe to relevant message streams.

### Message Addressing

```
# Current (broadcast)
./tools/post-news "Content Manager finished translation pipeline"

# Proposed (narrowcast)
./tools/post-news --to web,catalog "Translation pipeline ready for integration"
./tools/post-news --workstream agents "Agent-Manager API updated"
./tools/post-news --tag localization "New locale added: ja-jp"
```

### Agent Subscriptions

Each agent subscribes to:
1. **Direct messages** — Messages addressed to them by name
2. **Workstream messages** — Messages for their workstream
3. **Tagged messages** — Messages with tags they care about

```yaml
# In agent.md or agent config
subscriptions:
  direct: true  # Always receive @agent-name messages
  workstreams:
    - agents    # My workstream
    - web       # I collaborate with web often
  tags:
    - api
    - infrastructure
```

### Reading News

```bash
# Only shows subscribed messages
./tools/read-news

# Show all (broadcast mode, for housekeeping/coordination)
./tools/read-news --all

# Filter further
./tools/read-news --tag api
./tools/read-news --from web
```

## Benefits

| Aspect | Broadcast | Narrowcast |
|--------|-----------|------------|
| Token usage | Read all N messages | Read only relevant |
| Signal/noise | Degrades with scale | Stays focused |
| Agent focus | Context pollution | Clean context |
| Coordination | Everyone sees everything | Right info to right agent |

## Implementation

### Phase 1: Addressing
- Add `--to`, `--workstream`, `--tag` flags to `post-news`
- Store metadata in news file
- `read-news` filters by current agent's subscriptions

### Phase 2: Subscriptions
- Add subscription config to agent.md
- Tool reads agent config to determine what to show
- Default: direct + own workstream

### Phase 3: Message Queue (Optional)
- Move from file-based to proper queue
- Agents "consume" messages (mark as read)
- Delivery guarantees

## Relation to Token Efficiency

This directly supports the "Right Way = Fast Way" philosophy:
- Less reading = fewer tokens
- More relevant = better decisions
- Focused context = faster processing

## Open Questions

- [ ] Default subscriptions for new agents?
- [ ] How does housekeeping see everything for coordination?
- [ ] Archive/expiry for old messages?
- [ ] Priority levels (urgent vs normal)?

---

## Origin

From WORKING-NOTE-0021 discussion on token efficiency:

> **Q4: Versioning compiled knowledge?** When a convention changes, tools update. But what about agents mid-session with old assumptions?
>
> Jordan: "Broadcast messages. You could imagine a message queue to which an agent subscribes and it only gets what is there. For example, they only get messages addressed to them. Instead of broadcast news (that might not be applicable or helpful) they get focused, narrow cast!"

---

_Proposal for The Agency framework_
_Captured 2026-01-06_
