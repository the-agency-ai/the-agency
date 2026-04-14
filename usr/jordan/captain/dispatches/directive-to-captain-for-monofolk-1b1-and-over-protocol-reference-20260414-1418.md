---
type: directive
from: the-agency/jordan/captain
to: the-agency/jordan/captain
date: 2026-04-14T06:18
status: created
priority: normal
subject: "For monofolk: 1B1 and Over protocol reference"
in_reply_to: null
---

# For monofolk: 1B1 and Over protocol reference

## 1B1 (One-By-One) Discussion Protocol

All multi-item discussions use 1B1. One item at a time. Resolve before moving on.

### The Rules
1. Break the list into discrete threads
2. Number items explicitly
3. Address each item one at a time — not all at once
4. Resolve each item before moving to the next
5. Capture decisions as they are made

### The Resolution Cycle (per item)
Present → Feedback → Confirm Understanding → Revise → Iterate → Resolve → Confirm Resolution → Next

---

## Over / Over-and-Out Protocol

Adapted from radio communications (1860s Morse → WWII voice radio prowords). Controls turn-taking in all back-and-forth discussions.

### Signals

| Signal | Agent behavior |
|--------|---------------|
| *(streaming — no signal)* | Receive, parse, think. **Do NOT respond.** Principal is still transmitting. |
| **Over** | Principal's turn done. Agent: **mirror back** what you heard (rephrase). Discuss. Ask questions. **NO action taken.** |
| **Over and out** | Item resolved. Agent: state intended actions. Ask 'does that work?' Then execute per gate model. |

### Execution Gates

| Risk | Gate | Examples |
|------|------|----------|
| **Low risk** | Soft gate — proceed unless principal objects | Drafting, researching, updating transcripts, outline revisions |
| **High risk** | Hard gate — wait for explicit confirmation | Pushing to git, deleting files, sending dispatches, destructive ops |

### Key Rules
- **Until you receive 'Over,' do not respond.** Let the principal finish their thought.
- **On 'Over,' mirror first.** Rephrase what you heard before adding analysis. Catches misunderstandings early.
- **On 'Over and out,' state your plan.** Never silently execute. Say what you are going to do.

---

## Why These Matter

The 1B1 prevents the common failure mode where an agent tries to address 8 items at once, gets 3 wrong, and the principal has to untangle what was understood vs misunderstood.

The Over protocol prevents the agent from jumping to action before the principal has finished expressing their intent. It forces listening before acting.

Both are documented in claude/docs/DEVELOPMENT-METHODOLOGY.md and enforced by the multi-item-response-warn hookify rule.
