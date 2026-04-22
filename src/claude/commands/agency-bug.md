# Report a bug quickly

The user typed: `/agency-bug $ARGUMENTS`

**Purpose:** Quickly capture a bug without breaking the user's flow.

## Behavior

1. If `$ARGUMENTS` is empty, show usage:
   ```
   Usage: /agency-bug <summary>

   Example: /agency-bug Config tool outputs errors to stdout instead of stderr
   ```
   Then stop - do not prompt for input.

2. If `$ARGUMENTS` is provided, use it as the bug summary
3. Determine current agent context (default: housekeeping/captain)
4. Create the bug file
5. Confirm creation

## Implementation

1. Get the current date: `date +%Y-%m-%d`
2. Find the next bug number by counting existing bugs in `claude/workstreams/housekeeping/bugs/`
3. Create the bug file using the template below
4. Output confirmation

## Bug File Location

`claude/workstreams/housekeeping/bugs/BUG-XXXX.md`

## Bug File Template

```markdown
# BUG-XXXX: {Short summary from $ARGUMENTS}

**Status:** Open
**Reported:** {today's date}
**Assigned To:** captain
**Workstream:** housekeeping

## Description

{$ARGUMENTS}

## Steps to Reproduce

<!-- To be filled in -->

## Expected Behavior

<!-- To be filled in -->
```

## Output Format

After creating the bug:

```
Bug captured: BUG-XXXX
Assigned to: housekeeping/captain
Description: {first 60 chars of summary}...
```

## Notes

- Keep it fast - don't ask unnecessary questions
- Default to housekeeping/captain for now
- Bug numbers are zero-padded to 4 digits (BUG-0001, BUG-0042)
