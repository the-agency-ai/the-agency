# Create a REQUEST quickly

The user typed: `/agency-request $ARGUMENTS`

**Purpose:** Create a new REQUEST file quickly without breaking the user's flow.

## Behavior

1. If `$ARGUMENTS` is empty, show usage:
   ```
   Usage: /agency-request <summary>

   Example: /agency-request Add dark mode support to the dashboard
   ```
   Then stop - do not prompt for input.

2. If `$ARGUMENTS` is provided, use it as the request summary
3. Determine the principal (use `./tools/config get principal` or default to "jordan")
4. Get the next request number
5. Create the REQUEST file from template
6. Confirm creation with next steps

## Implementation

1. Get principal:
   ```bash
   ./tools/config get principal 2>/dev/null || echo "jordan"
   ```

2. Count existing requests to find next number:
   ```bash
   ls claude/principals/{principal}/requests/REQUEST-*.md 2>/dev/null | wc -l
   ```
   Add 1 and zero-pad to 4 digits.

3. Generate slug from summary (lowercase, spaces to hyphens, max 50 chars)

4. Create file using template at `claude/templates/REQUEST.md`

5. Replace template placeholders:
   - `{{PRINCIPAL}}` → principal name
   - `{{NUMBER}}` → zero-padded number (e.g., 0042)
   - `{{SUMMARY}}` → the summary from $ARGUMENTS
   - `{{REQUESTED_BY}}` → principal name
   - `{{AGENT}}` → "captain" (default)
   - `{{WORKSTREAM}}` → "housekeeping" (default)
   - `{{DATE}}` → today's date
   - `{{SUMMARY_DESCRIPTION}}` → the full summary

## Request File Location

`claude/principals/{principal}/requests/REQUEST-{principal}-{XXXX}-{slug}.md`

## Output Format

After creating the request:

```
REQUEST created: REQUEST-{principal}-{XXXX}
Location: claude/principals/{principal}/requests/REQUEST-{principal}-{XXXX}-{slug}.md

Next steps:
1. Fill in the Details section
2. Add Acceptance Criteria
3. Assign to an agent (default: captain)
```

## Notes

- Keep it fast - create the file, confirm, done
- User can fill in details later
- Default to housekeeping workstream and captain agent
