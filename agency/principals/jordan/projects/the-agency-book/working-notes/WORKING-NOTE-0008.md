# THE-AGENCY-BOOK-WORKING-NOTE-0008

**Date:** 2026-01-03 23:40 SGT
**Participants:** jordan (principal), housekeeping/Opus 4.5 (agent)
**Subject:** Yak Shaving in Parallel - Day 3 Insights

---

## Discussion

### The Traditional Yak Shaving Problem

"Yak shaving" is a pejorative in software development. It describes the frustrating experience of wanting to accomplish Task A, but first needing to do Task B, which requires Task C, which depends on Task D... and before you know it, you're shaving a yak when all you wanted was a clean car.

The dependency chain:

```
Want: Clean car
Need: Hose
Need: Fix hose connector
Need: Go to hardware store
Need: Fix car to drive there
Need: Borrow neighbor's tools
Need: Return neighbor's pillow
Need: Find pillow
Need: ... shave a yak?
```

In solo development, this is a serial nightmare. Each dependency blocks progress. Context switching destroys flow. Hours pass, the car remains dirty.

### The Agency Flips the Script

With The Agency's multi-agent architecture, yak shaving becomes a superpower instead of a curse.

**The insight:** When you hit a dependency, don't context-switch yourself. Spawn an agent.

```
Principal: "I need to deploy this feature"
  |
  +---> Agent 1: Works on feature code
  |       |
  |       +---> Hits: "Need updated test fixtures"
  |               |
  |               +---> Agent 2: Updates test fixtures
  |
  +---> Agent 3: Prepares deployment tooling
          |
          +---> Hits: "Need CI green first"
                  |
                  +---> Agent 4: Fixes CI issues
```

All four yaks get shaved simultaneously. The principal orchestrates, agents execute in parallel.

### Today's Live Example

During this very session, I (housekeeping) was doing end-of-day cleanup:

- Staging files for commit
- Running pre-commit checks (which take ~20 seconds)

While my pre-commit was running, the **web agent** in another terminal:

- Committed the same gitignore fix I was working on
- Pushed the push-log update

When my commit tried to complete: `fatal: HEAD is at afe5aa6 but expected 36fdbf2`

The "failure" was actually a success - the work was done, just by a different agent. The Agency's parallel execution meant the yak was already shaved by the time I reached for the razor.

### Key Principles for Parallel Yak Shaving

1. **Spawn, don't switch** - When you hit a blocker, launch an agent to handle it rather than context-switching yourself.

2. **Loose coupling** - Agents work on separate files/concerns. Git handles the merge. Conflicts are rare because each agent owns their domain.

3. **News system for coordination** - Agents post NEWS when they complete significant work. Others pick it up asynchronously.

4. **Principal as orchestrator** - You're not doing the yak shaving. You're directing traffic, ensuring all the yaks get shaved in parallel.

5. **Embrace the race** - Sometimes two agents will work on the same thing. That's fine. First one wins, second one's work wasn't wasted (it validated the approach).

### The LinkedIn Post (Day 3 of 12 Days of Claude Gratitude)

> **Day 3: Yak Shaving in Parallel**
>
> You know that feeling when you want to do Task A, but first you need B, which requires C, which depends on D? Solo, it's a nightmare of context switching.
>
> With The Agency, I just spawn agents. "You handle B." "You fix C." "You figure out D." Then I orchestrate.
>
> Yesterday I had 4 agents running: one on deployment tooling, one on documentation, one fixing tests, one doing housekeeping. All the yaks got shaved simultaneously.
>
> The dependency chain that would've taken me hours of serial context-switching? Done in parallel while I directed traffic.

---

## Decisions Made

- Yak shaving in parallel is a core concept for The Agency book
- The metaphor transformation (pejorative → superpower) is powerful messaging
- Real examples from actual sessions make the concept concrete

---

## Action Items

- [ ] Include yak shaving chapter in book outline
- [ ] Collect more live examples of parallel yak shaving
- [ ] Create diagram showing serial vs. parallel dependency resolution

---

## Next Steps

- This note feeds into Chapter: "Multi-Agent Workflows" or "Parallel Execution Patterns"
- Consider: animated diagram for website showing yaks being shaved in parallel

---

_Working note for project: the-agency-book_
