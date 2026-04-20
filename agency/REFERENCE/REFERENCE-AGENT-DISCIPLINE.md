# Agent Discipline — Universal Rules

<!-- What Problem: Two agent-behavior policies were historically written as if
they applied only to captain (in usr/{principal}/captain/CLAUDE-CAPTAIN.md and
agency/agents/captain/agent.md): "The Two Standing Priorities" and the
"Over / Over-and-out" protocol. In practice every agent should follow them —
every agent reads dispatches, every agent drops current work when the
principal speaks, every agent in a 1B1 should use Over/Out.

How & Why: Relocated to the bootloader's reference-docs layer. The bootloader
references this doc; every agent already loads the bootloader at startup.
Ref-injector picks up the right skill-scoped sections on demand.

Written: 2026-04-15 during D41-R19 — issue #111 Option E class-doc relocation. -->

These rules apply to **every agent in the fleet**, not just captain. They override role-specific instructions.

## The Two Standing Priorities

Every agent has two standing priorities that override everything else, in this order:

### 1. Inquiries and communications from your Principal

**The principal does not contact you unless it is important.** When the principal sends a message, asks a question, or issues a directive, that is your top priority. Stop what you are doing. Listen first. Understand before you act. Confirm before you proceed.

This is not just about urgency — it is about respect for the principal's time. When they pull you out of background work to ask something, the cost of the interruption was already paid by them. Do not waste it by jumping to the next thing or asking them to wait while you finish something else. Address what they brought to you, completely, before returning to other work.

Rules:
- **When the principal asks for your attention, you give it.** Full stop. The current task waits.
- **When the principal asks a question, answer it.** Don't pivot to a different topic mid-response.
- **When the principal redirects you, follow.** Don't keep working on what you were doing.
- **When the principal corrects you, listen.** Acknowledge and adjust — don't defend.

### 2. Dispatches

**This is the team looking to you for support.** Peer agents and cross-repo collaborators communicate via dispatches. They send a dispatch when they need a decision, an approval, an unblock, or coordination. They are waiting for you.

Rules:
- **When you have a dispatch, read it.** People are waiting. Don't let dispatches sit unread.
- **Read on the iscp-check notification.** When the hook tells you mail is waiting, that is the signal to check immediately at the next natural break.
- **Process dispatches at session start, before other work.** Non-negotiable.
- **Reply or resolve in the same session.** Don't leave plans waiting for approval indefinitely.
- **Coordinate at the speed your team is working.** If an agent shipped a plan and is sitting waiting on you, your job is to unblock them.

### How they interact

If both happen at the same time — principal contacts you AND a new dispatch arrives — the principal's communication wins. Acknowledge the dispatch quickly ("dispatch from devex just landed, will read after we wrap this") but address the principal first.

An unread dispatch is a blocked person. An unaddressed principal message is an ignored principal. Neither is acceptable. Ever.

## Tool Discipline — USE THE TOOLS

**Never hand-craft files that a tool creates. Never run raw commands when a tool wraps them.** The framework has tools, skills, and hooks — **they exist for reasons**. Using them is not optional discipline; it's how the Enforcement Triangle works.

Canonical substitutions:

| Don't | Do | Why |
|---|---|---|
| `git commit` raw | `./agency/tools/git-safe-commit` (via `/git-safe-commit`, `/iteration-complete`, `/phase-complete`) | QG receipt check, provenance, commit-log hygiene |
| `git push` raw | `./agency/tools/git-push` (via `/sync`, `/release`) | Blocks main/master, requires PR path |
| `gh pr create` | `./agency/tools/pr-create` (via `/release`) | Requires RGR + version bump |
| `gh pr merge` | `./agency/tools/pr-merge` (via `/pr-merge`) | Refuses `--squash`/`--rebase`; enforces `--merge` + `--principal-approved` |
| Hand-written agent registration | `./agency/tools/agent-create` | Correct scaffolding, provenance, permissions |
| Hand-written workstream | `/workstream-create` | Directory structure, agent reg, worktree, sandbox |
| Hand-written worktree | `./agency/tools/worktree-create` | Branch wiring, settings copy, identity file |
| Hand-written handoff | `./agency/tools/handoff write` (via `/handoff`) | Archive + rotate + stamp |
| Hand-written dispatch | `./agency/tools/dispatch create` (via `/dispatch`) | DB record + git payload + addressing |
| Hand-written QGR receipt | `./agency/tools/receipt-sign` (via `/quality-gate`) | Five-hash chain of trust |

Hand-crafting a file that a tool creates is a **process violation**. It bypasses the consistency guarantees, skips provenance, and creates drift. If a tool gets in your way, fix the tool or flag the friction — don't route around it.

**Lesson captured 2026-04-12** (universal, not captain-only): Captain hand-crafted agent registration + handoff + workstream dirs for DesignEx instead of using `/workstream-create` + `agent-create` + `worktree-create`. Principal caught it: *"Use the tools! You are doing it manually! Spin up a workstream, an agent, a worktree with the tools!"* Fixed by removing manual files and redoing with tools. The rule applies to every agent: if a tool exists for the task, use the tool.

## Communication Protocol — Over / Over-and-Out

All back-and-forth discussions (1B1, `/discuss`, reviews, any conversation with the principal) follow the **Over / Over-and-Out** protocol, adapted from radio communications (1860s Morse procedural signs → WWII voice radio prowords).

### Signals

| Signal | Agent behavior |
|---|---|
| *(streaming — no signal yet)* | Receive, parse, think. **Do NOT respond.** The principal is still transmitting. |
| **"Over"** | Principal's turn is done. Agent: **mirror back** what you heard (rephrase/reframe). Discuss. Ask questions. **NO action taken.** |
| **"Over and out"** | Discussion item resolved. Agent: state intended actions. Ask **"does that work?"** Then execute per the gate model below. |

### Execution gates

| Action risk | Gate | Examples |
|---|---|---|
| **Low risk** | **Soft gate** — proceed unless principal objects | Drafting, researching, updating transcripts, outline revisions, launching research agents |
| **High risk** | **Hard gate** — wait for explicit confirmation before executing | Filing to external systems, pushing to git, deleting files/branches, sending dispatches, destructive operations |

The risk classification aligns with hookify levels: hookify-warn actions are soft-gate; hookify-block actions are hard-gate.

### Rules

- **Until you receive "Over," do not respond.** Batch-receive the principal's stream without interrupting their train of thought.
- **On "Over," mirror first.** Rephrase what you heard before adding your own analysis. This catches misunderstandings before they become wrong actions.
- **On "Over and out," state your plan.** Never silently execute after a discussion. Say what you're going to do. Ask "does that work?" For soft-gate actions, proceed after asking. For hard-gate actions, wait for explicit "yes."
- **Any 1B1 auto-starts a transcript** if one isn't already running.

---

*OFFENDERS WILL BE FED TO THE — CUTE — ATTACK KITTENS!*
