# Explore: Collaboration

**Time:** 4 minutes
**Goal:** Learn how agents work together

## Why Collaboration?

Sometimes work spans multiple areas:
- Frontend change needs API update
- Database migration needs app code changes
- Testing work needs dev support

Agents collaborate to coordinate across workstreams.

## Collaboration Tools

### Request Help: `./tools/collaborate`

When an agent needs help from another:

```bash
./tools/collaborate \
  --from web-agent \
  --to api-agent \
  --subject "Need API endpoint for user profile" \
  --message "Can you create a GET /api/users/:id/profile endpoint?"
```

This creates a collaboration request.

### Respond: `./tools/collaboration-respond`

The receiving agent sees pending requests:

```bash
./tools/collaboration-respond --list
```

And can respond:

```bash
./tools/collaboration-respond {request-id} \
  --message "Done! Endpoint created at /api/users/:id/profile"
```

### Dispatch: `./tools/dispatch-collaborations`

Automatically launch agents for pending collaboration requests:

```bash
./tools/dispatch-collaborations
```

## News System

Agents can broadcast updates:

### Post News
```bash
./tools/news-post "Deployed v2.0 to production"
```

### Read News
```bash
./tools/news-read
./tools/news-read --since yesterday
./tools/news-read --agent api-agent
```

## Collaboration Flow Example

Walk through a real scenario:

**Scenario:** Frontend needs new API

1. **Web agent** realizes it needs API support
   ```bash
   ./tools/collaborate --to api-agent --subject "Need endpoint"
   ```

2. **API agent** sees the request
   ```bash
   ./tools/collaboration-respond --list
   ```

3. **API agent** builds the endpoint and responds
   ```bash
   ./tools/collaboration-respond {id} --message "Built it!"
   ```

4. **Web agent** gets notification and continues work

## When to Collaborate

**DO collaborate when:**
- Work spans multiple workstreams
- You need expertise from another agent
- Coordinating related changes
- Requesting code review

**DON'T collaborate when:**
- Simple question (just ask in chat)
- Work is self-contained
- You can handle it yourself

## Demo: Try Collaboration

If they have multiple agents, do a quick demo:

1. Create a collaboration request
2. Show it in the system
3. Respond to it
4. Show the completion

## Key Takeaways

✓ Agents collaborate across workstreams
✓ `./tools/collaborate` for help requests
✓ News system for broadcasts
✓ Coordination without blocking

## Next Steps

Ask if they want to:
- Try creating something (new project or existing codebase)
- Learn more concepts (principals, workstreams, etc.)
- Start working on their own

## Track Progress

Update `onboarding.yaml`:
```yaml
completed_sections:
  - welcome
  - explore.collaboration
```
