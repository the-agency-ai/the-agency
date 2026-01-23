# Add a nit quickly

The user typed: `/agency-nit $ARGUMENTS`

**Purpose:** Quickly capture a minor issue or observation without breaking the user's flow.

## Behavior

1. If `$ARGUMENTS` is empty, show usage:
   ```
   Usage: /agency-nit <category> <description>

   Example: /agency-nit "Documentation" "README missing install prereqs"
   ```
   Then stop - do not prompt for input.

2. If `$ARGUMENTS` is provided, parse it:
   - If it looks like `"Category" "Description"` (two quoted strings), use those
   - Otherwise, use "General" as category and the full argument as description

3. Call the nit-add tool: `./tools/nit-add "<category>" "<description>"`

4. Confirm creation

## Implementation

Run the tool:
```bash
./tools/nit-add "<category>" "<description>"
```

## Output Format

After adding the nit:

```
Nit captured: <category>
Description: <first 60 chars of description>...
```

## Notes

- Keep it fast - don't ask unnecessary questions
- Nits go to `claude/workstream-agent-nits.md` (shared file for all agents)
- Use for minor issues that don't warrant a full BUG or REQUEST
