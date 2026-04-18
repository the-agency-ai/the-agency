---
name: discuss
description: Structured 1B1 (one-by-one) discussion — resolve each item before moving to the next. Use when the user has multiple items, decisions, or questions to work through, or when they say "1B1", "one by one", "discuss these", "let's work through", or "walk me through". Especially useful when the principal is on remote-control (phone/tablet) and needs short focused exchanges. Also the default protocol for any extended decision discussion, not only when /discuss is explicitly invoked.
---

# /discuss

Structured discussion using the 1B1 (one-by-one) protocol. Each item gets its own resolution cycle. Multiple items? Present them numbered, work through one at a time, resolve, confirm, move on.

## When to use

- User has a list of items to decide (`/discuss "item 1" "item 2" "item 3"`)
- User said something with multiple decision points in one message — parse the items and present them numbered
- User on remote-control (phone/tablet) and needs small, focused exchanges
- Any conversation that would otherwise get tangled if addressed all at once

## Usage

```
/discuss "Item 1" "Item 2" "Item 3"     — start with explicit items
/discuss                                  — parse items from the user's last message
/discuss --from <file>                    — extract items from a document
```

## Behavior

### 1. Parse items

- Arguments provided: use them verbatim
- No arguments: extract numbered items, bullet points, or distinct topics from the user's most recent message
- `--from <file>`: read the file, extract items from headings or bullet points

### 2. Present the item list

Show all items numbered, first one highlighted as active:

```
## Discussion Items

-> 1. [First item — ACTIVE]
   2. [Second item]
   3. [Third item]

Starting with Item 1.
```

### 3. For each item — the 8-step resolution cycle

**Step 1 — Present.** Present the item clearly. State what you understand, what the options are, or what needs to be decided. **One item only.**

**Step 2 — Get feedback.** Wait for the principal's response. Do not proceed until they respond.

**Step 3 — Confirm understanding.** Reflect back what you heard. "So you're saying X because Y — is that right?" This is reflective listening. **Do NOT skip this step.** Do NOT jump to revising.

**Step 4 — Revise.** Based on confirmed understanding, update your position, proposal, or analysis.

**Step 5 — Iterate.** If the principal has more feedback, return to Step 2. Continue until alignment.

**Step 6 — Resolve.** State the resolution clearly: `Decision: [what was decided]` or `Action: [what will be done]`.

**Step 7 — Confirm resolution.** Ask: "Agreed on Item N? Ready to move to Item N+1?" Wait for confirmation.

**Step 8 — Next item.** Capture the decision. Move to the next item. Show the updated list with the next item highlighted.

### 4. On completion

Present a decisions summary:

```
## Decisions Summary

1. [Item 1]: [Decision]
2. [Item 2]: [Decision]
3. [Item 3]: [Decision]
```

## Rules

- **Never address multiple items in one response.** One item at a time. Always.
- **Never skip Step 3 (Confirm Understanding).** Agents skip this step most. Reflective listening prevents wasted revision cycles.
- **Never skip Step 7 (Confirm Resolution).** The principal must explicitly agree before moving on.
- **Keep responses short.** Especially on remote-control. 1B1 discipline is even more critical with small screens.
- **Capture decisions inline.** Don't wait until the end to summarize.
- If the principal says "skip" or "park", mark the item as skipped/parked and move on.
- If the principal adds new items mid-discussion, append them to the list.

## The 8-Step Protocol (reference card)

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

## Scope note

This protocol is the **default way agents present multi-item information to principals**, not only when `/discuss` is explicitly invoked. The skill exists so Claude can trigger into it cleanly when the situation calls for it.
