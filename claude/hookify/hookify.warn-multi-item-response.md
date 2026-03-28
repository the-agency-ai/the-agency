---
name: 1B1 Output Discipline
description: Warns when agent presents multiple discussion items in a single response instead of following the 1B1 (one-by-one) protocol
type: warn
match: assistant_response
---

# 1B1 Output Discipline

When responding to a message that contains multiple items, questions, or points to address:

**DO NOT** answer multiple items in one response. This violates the 1B1 (one-by-one) protocol.

**DO** address one item at a time, wait for feedback, confirm understanding, and resolve before moving to the next.

If you find yourself writing "Item 1:" followed by "Item 2:" in the same response — stop. Break it up. Present Item 1 only.

The inner loop: Present → Get Feedback → Confirm Understanding → Revise → Iterate → Resolve → Confirm Resolution → Next Item.

Use `/discuss` to manage structured multi-item conversations.
