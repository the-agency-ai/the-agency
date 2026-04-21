---
type: seed
workstream: agency
date: 2026-04-12
captured_by: the-agency/jordan/captain
principal: jordan
status: parked-for-iteration
---

# Seed: Three-Signal Protocol Evolution (Over / Over-and-Out / Over-and-Out-Execute)

## Current state (two-signal, shipped)

The Over / Over-and-Out protocol is captured in CLAUDE-CAPTAIN.md with a two-tier execution gate (soft gate for low-risk, hard gate for high-risk actions). This is the working protocol.

## Proposed evolution (three-signal)

Jordan explored adding a third signal during the April 12 mobile review session:

- **"Over"** — your turn to talk. Mirror back. Discuss. No action.
- **"Over and out"** — move to next item. Agent states plan. For soft-gate actions, proceeds. For hard-gate actions, waits.
- **"Over and out, execute"** — explicit authorization to proceed on the proposed action, regardless of risk level. Overrides the hard gate.

### Why this might be needed

The two-signal model with soft/hard gates works well, but there's a middle ground where the principal KNOWS the action is high-risk and wants to pre-authorize it in the same breath as closing the discussion:

> "Yes, go ahead and push that to origin. Over and out, execute."

Without "execute," the flow would be:
1. Principal: "Over and out"
2. Agent: "I plan to push to origin. Does that work?"
3. Principal: "Yes"
4. Agent pushes

With "execute," the flow collapses to:
1. Principal: "Over and out, execute"
2. Agent pushes

### When NOT to use this

The three-signal model should NOT be the default. "Over and out, execute" is a power-user shortcut for principals who:
- Know exactly what action the agent will take
- Have already decided to authorize it
- Want to save one round-trip of confirmation

For new users, the two-signal model with hard gates is safer. The three-signal model is a graduated trust feature.

### Relationship to hookify enforcement

The "execute" signal could theoretically override hookify-block level enforcement. This is dangerous and probably should NOT be allowed at the protocol level — hookify blocks exist for mechanical safety reasons (prevent `rm -rf /`, prevent force-push to main), and a voice command shouldn't override them. The "execute" signal should only collapse the human confirmation round-trip, not bypass the enforcement framework.

### Status

Parked. We shipped the two-signal version. We iterate toward three-signal as we learn where the boundaries feel right in practice. The seed captures the design intent for future reference.

### Conversation source

Jordan exploring the idea during the April 12 mobile review session (breakfast walk via remote control). Captain proposed the hookify alignment (warn = soft gate, block = hard gate). Jordan liked the pattern but noted "we need to work with this" before committing to three signals.
