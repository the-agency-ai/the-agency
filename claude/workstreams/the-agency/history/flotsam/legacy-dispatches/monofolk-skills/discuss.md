---
allowed-tools: Read, Write, Edit, Glob, Bash(date *), Bash(git branch *), Skill
description: Structured 1B1 (one-by-one) discussion — resolve each item before moving to the next
---

# /discuss

Structured discussion tool using the 1B1 (one-by-one) protocol. Each item gets its own resolution cycle. Coupled with `/transcript` for automatic record-keeping.

## Usage

```
/discuss "Item 1" "Item 2" "Item 3"     — start with explicit items
/discuss                                  — parse items from the user's last message
/discuss --from <file>                    — extract items from a document
```

## Behavior

When invoked:

1. **Parse items.** If arguments provided, use them. If none, extract numbered items, bullet points, or distinct topics from the user's most recent message. If `--from <file>`, read the file and extract discussion items from headings or bullet points.

2. **Auto-start transcript.** Run `/transcript start "discuss: <first item summary>"` in dialogue mode. The discussion IS the record.

3. **Present the item list.** Show all items numbered, with the first one highlighted as active:

   ```
   ## Discussion Items

   → 1. [First item — ACTIVE]
     2. [Second item]
     3. [Third item]

   Starting with Item 1.
   ```

4. **For each item, follow the 8-step resolution cycle:**

   **Step 1 — Present.** Present the item clearly. State what you understand, what the options are, or what needs to be decided. One item only.

   **Step 2 — Get feedback.** Wait for the principal's response. Do not proceed until they respond.

   **Step 3 — Confirm understanding.** Reflect back what you heard. "So you're saying X because Y — is that right?" This is reflective listening. Do NOT skip this step. Do NOT jump to revising.

   **Step 4 — Revise.** Based on confirmed understanding, update your position, proposal, or analysis.

   **Step 5 — Iterate.** If the principal has more feedback, return to Step 2. Continue until alignment.

   **Step 6 — Resolve.** State the resolution clearly: "Decision: [what was decided]" or "Action: [what will be done]."

   **Step 7 — Confirm resolution.** Ask: "Agreed on Item N? Ready to move to Item N+1?" Wait for confirmation.

   **Step 8 — Next item.** Capture the decision in the transcript via `/transcript capture "Item N" "Decision: ..."`. Move to the next item. Show the updated list with the next item highlighted.

5. **On completion.** After all items resolved, present a decisions summary:

   ```
   ## Decisions Summary

   1. [Item 1]: [Decision]
   2. [Item 2]: [Decision]
   3. [Item 3]: [Decision]
   ```

   Stop the transcript via `/transcript stop`.

## Rules

- **Never address multiple items in one response.** One item at a time. Always.
- **Never skip Step 3 (Confirm Understanding).** This is the step agents skip most. Reflective listening prevents wasted revision cycles.
- **Never skip Step 7 (Confirm Resolution).** The principal must explicitly agree before moving on.
- **Keep responses short.** Especially when the principal is on remote-control (phone/tablet). 1B1 discipline is even more critical with small screens.
- **Capture decisions inline.** Don't wait until the end to summarize. Each resolved item gets captured immediately via `/transcript capture`.
- **If the principal says "skip" or "park",** mark the item as skipped/parked and move to the next one. Include it in the summary as "Parked: [reason]" or "Skipped."
- **If the principal adds new items mid-discussion,** append them to the list and acknowledge: "Added Item N+1: [description]."

## The 8-Step Protocol (Reference)

```
1. Present       — one item, clearly stated
2. Get feedback  — wait for principal
3. Confirm       — reflect back ("So you're saying...")
4. Revise        — update based on confirmed understanding
5. Iterate       — back to 2 if more feedback
6. Resolve       — state the decision
7. Confirm       — "Agreed? Next?"
8. Next item     — capture decision, move on
```

This protocol applies to ALL structured discussions, not just when `/discuss` is explicitly invoked. The 1B1 protocol is the default way agents present information to principals.
