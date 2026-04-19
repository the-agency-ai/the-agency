# WORKING-NOTE-0024: Captain Rename and Interactive Onboarding

**Date:** 2026-01-14
**Author:** Captain (formerly housekeeping agent)
**Related:** REQUEST-jordan-0049, REQUEST-jordan-0034
**Topic:** Agent identity evolution and first-launch experience design

---

## Context

This working note documents a significant evolution in The Agency: renaming the housekeeping agent to "captain" and implementing a comprehensive interactive onboarding system. This work addresses two key challenges:

1. **Identity misalignment:** The "housekeeping" name didn't reflect the agent's actual leadership role
2. **Onboarding gap:** New principals had no guided path to understand The Agency

## The Problem

### Agent Identity

The housekeeping agent had evolved beyond its original "meta-work" scope to become:
- The principal's guide and mentor
- Project manager coordinating multi-agent work
- Infrastructure specialist executing starter kits
- Framework expert maintaining The Agency itself

The name "housekeeping" undersold this leadership role and created confusion about the agent's purpose.

### Onboarding Experience

New principals faced a cold start problem:
- No guided introduction to The Agency concepts
- Unclear first steps after installation
- Framework documentation but no interactive learning
- Lost potential of the session context restoration system

## The Solution: Three-Phase Transformation

### Phase 1: Core Rename (housekeeping → captain)

**Why "captain"?**
- Maritime metaphor: The captain guides the ship and crew
- Leadership connotation: Authority without being dictatorial
- Approachable: "Captain" feels collaborative, not hierarchical
- Clear role: Obviously the one who shows you around

**Technical execution:**
- Used `git mv` to preserve history
- Updated 29 files across tools, configuration, and documentation
- Maintained workstream name as "housekeeping" (meta-work remains the same)
- New commit pattern: `housekeeping/captain: type: message`

**Key decision:** Keep workstream name unchanged. The workstream is about meta-work; the agent is the leader. This preserves backward compatibility while improving clarity.

### Phase 2: First-Launch Context Redesign

**The insight:** The session context restoration system could serve double duty as an onboarding mechanism.

**Old approach (theoretical):**
- Context would guide the principal
- "Here's what to do next"
- Principal-focused

**New approach (implemented):**
- Context guides the captain agent
- "Here's how to help this principal"
- Captain-focused, then captain guides principal

**Why this works:**
- Leverages existing restoration mechanism
- Captain has full context about their role
- Natural, conversational guidance
- Self-replacing (becomes actual work context after first session)

**Example first-launch context:**
```jsonl
{"timestamp":"...","type":"checkpoint","content":"Captain's first session - principal just installed The Agency"}
{"timestamp":"...","type":"checkpoint","content":"Your role: Guide this principal through their first steps"}
{"timestamp":"...","type":"append","content":"Suggest they try '/welcome' for interactive guided tour"}
```

### Phase 3: Captain's Tour (Interactive Onboarding)

**Design philosophy:** "Choose Your Own Adventure"

Not a linear walkthrough, but branching paths based on what the principal wants to accomplish.

**The five paths:**

1. **🚀 Start a new project from scratch**
   - For principals creating something new
   - Walks through project setup, first workstream, first agent
   - Hands-on: they actually create things
   - Time: 5 minutes

2. **📦 Set up The Agency in an existing codebase**
   - For principals with existing projects
   - Mapping workstreams to code areas
   - Creating agents for different parts
   - Time: 5 minutes

3. **🔍 Explore what The Agency can do**
   - Feature tour: agents, workstreams, tools, collaboration
   - Demo-style: see things in action
   - Breadth over depth
   - Time: 4 sub-paths, 3-4 min each

4. **🎓 Learn the core concepts first**
   - Theory before practice
   - Principals, agents, workstreams explained
   - Understanding the "why" behind the design
   - Time: 3 sub-paths, 2-3 min each

5. **⚡ Quick setup - I know what I'm doing**
   - For experienced users
   - Minimal guidance, maximum speed
   - Creates basic structure and gets out of the way
   - Time: 2 minutes

**Implementation:**

Two Claude Code commands:
- `/welcome` - Main entry point, presents the five paths
- `/tutorial` - Navigation (resume, status, restart, skip)

Ten tutorial content files:
- 3 main paths (new project, existing codebase, quick setup)
- 4 explore sub-topics (agents, workstreams, tools, collaboration)
- 3 concept deep-dives (principals, agents, workstreams)

State tracking via YAML:
```yaml
# claude/principals/{name}/onboarding.yaml
started: 2026-01-14
completed_sections:
  - welcome
  - concepts.agents
current_path: explore.tools
preferences:
  experience_level: intermediate
```

**Key design decisions:**

1. **No dead ends:** Every path leads somewhere useful
2. **Learn by doing:** Principals run real commands, create real artifacts
3. **Easy exit:** They can stop any time, resume later
4. **Progress tracking:** Never lose their place
5. **Time-boxed:** Each section <5 minutes
6. **Interactivity:** Uses AskUserQuestion tool for choices

## Technical Architecture

### Commands as Documentation

The `/welcome` and `/tutorial` commands are implemented as markdown files in `.claude/commands/`:
- Not code, but structured instructions
- Captain reads them and interprets
- Uses Claude Code's command system
- Easily editable and version-controlled

### Tutorials as Content

Tutorial content lives in `claude/docs/tutorials/`:
- Not in `.claude/` (configuration)
- In `claude/docs/` (documentation)
- Treated as project documentation
- Part of the framework knowledge

### State as YAML

Onboarding state in `claude/principals/{name}/onboarding.yaml`:
- Human-readable
- Git-friendly (can track changes)
- Easy to inspect
- Per-principal (multiple principals = independent progress)

### Integration with Starter

The first-launch context ships with the-agency-starter:
```
claude/agents/captain/backups/latest/context.jsonl
```

On first launch, the SessionStart hook reads this file and displays guidance. The captain sees their role and knows how to help the principal.

## Implementation Metrics

**Development time:** ~4 hours (single session)

**Code changes:**
- 8 commits
- 45 files changed
- 29 files in Phase 1 (core rename)
- 3 files in Phase 2 (documentation)
- 12 files in Phase 3 (Captain's Tour)
- 1 file for integration guide

**Content created:**
- 2 command files
- 10 tutorial files
- ~34 minutes of tutorial content across all paths
- 1 comprehensive integration guide

**Lines of content:**
- Captain's agent.md: 193 lines (from 66)
- Welcome command: 175 lines
- Tutorial command: 186 lines
- Tutorial content: ~1,600+ lines total

## Lessons and Patterns

### 1. Identity Matters

Agent names should reflect their actual role, not their initial conception. As agents evolve, their identity should evolve too.

**Pattern:** Let agent roles emerge through use, then codify them.

### 2. Leverage Existing Mechanisms

The session context system was already built. By making it serve double duty (restoration + onboarding), we avoided building a separate onboarding system.

**Pattern:** Look for existing mechanisms that can be extended rather than building new ones.

### 3. Guide the Guide

Rather than guiding principals directly, guide the captain who then guides principals. This creates a more natural, conversational experience.

**Pattern:** Meta-guidance - instruct the AI on how to guide, not the human on what to do.

### 4. Choose Your Own Adventure

Different users have different goals and learning styles. Branching paths respect this diversity.

**Pattern:** Multiple paths to the same outcome, optimized for different user contexts.

### 5. State Without Complexity

YAML file for state tracking is simple but sufficient. No database, no complex state machine.

**Pattern:** The simplest thing that could possibly work, version-controlled.

### 6. Content as Code

Tutorial content is markdown files in the repo. Easy to write, easy to maintain, easy to version.

**Pattern:** Treat tutorial content like documentation - in the repo, version-controlled, pull-request-able.

## For the Book

### Chapter: Agent Identity and Evolution

This work illustrates:
- How agent roles emerge through use
- When and how to refactor agent identity
- The relationship between naming and role clarity
- Managing agent evolution while preserving history

**Key quote for book:**
> "The housekeeping agent had grown into a leader. The name no longer fit the role. Renaming wasn't just cosmetic - it clarified purpose, set expectations, and enabled the next evolution: teaching the agent how to teach."

### Chapter: Onboarding Experience Design

This work demonstrates:
- Designing for different user goals
- Interactive vs. linear tutorials
- State management in multi-agent systems
- Leveraging existing systems for new purposes

**Key quote for book:**
> "We didn't build a separate onboarding system. We taught the captain how to welcome principals using the tools already available: commands, tutorials, and the session context system."

### Chapter: First-Launch Experience

This work shows:
- Using session context for initial guidance
- Guiding the guide (meta-instruction pattern)
- Progressive disclosure of complexity
- Self-replacing scaffolding

**Key quote for book:**
> "On first launch, the captain sees context from a 'previous session' that never happened. This context tells the captain who they are and how to help. After the first session, real work replaces this template. The scaffolding removes itself."

### Chapter: Tutorial Design

This work provides examples of:
- Branching tutorial structures
- Time-boxed learning paths
- Hands-on vs. conceptual learning
- Navigation commands for non-linear content

**Key quote for book:**
> "Five paths, all under five minutes each. The principal chooses based on their goal and experience level. No dead ends, no forced march through content they don't need."

## Related Work

**Completes:**
- REQUEST-jordan-0034 (Captain onboarding context - first run)
  - This was the original vision for interactive onboarding
  - Implemented here as part of captain rename

**Enables:**
- Better first-time principal experience
- Foundation for other agents to have role-specific onboarding
- Pattern for using commands + tutorials for guidance
- Model for other framework improvements

**Builds on:**
- Session context restoration system (REQUEST-jordan-0048)
- Tool ecosystem
- Command system (Claude Code slash commands)

## Questions for Further Work

1. **Should other agents have similar onboarding?**
   - Could each agent type have a `/welcome-{agent}` command?
   - Would agent-specific tutorials help?

2. **Should we auto-run /welcome on first launch?**
   - Pro: Ensures every principal sees it
   - Con: Assumes they want guided tour
   - Alternative: Display hint about /welcome in first-launch context

3. **How to measure onboarding effectiveness?**
   - Track completion rates via onboarding.yaml
   - Survey principals after onboarding?
   - A/B test different paths?

4. **Should principals be able to restart sections?**
   - Currently can restart entire tutorial
   - Should they be able to re-do individual sections?
   - Trade-off: flexibility vs. complexity

5. **How to keep tutorial content current?**
   - As framework evolves, tutorials need updates
   - Who maintains tutorial content?
   - How to test tutorials still work?

## Conclusion

The captain rename and Captain's Tour represent an evolution in The Agency's self-awareness. The framework now knows how to introduce itself, not through static documentation, but through an interactive, adaptive guide who meets principals where they are.

This wasn't just a rename - it was a recognition that the framework had matured enough to teach itself. The captain is both a leader and a teacher. The Tour is both onboarding and a demonstration of multi-agent patterns.

Most importantly, this work shows the value of reflexivity: The Agency can improve The Agency. The framework can evolve its own identity. The guide can learn to be a better guide.

That's the essence of a self-improving system.

---

**Implementation commits:**
- `a1f65e3` - First-launch documentation and .gitignore fix
- `5b99e3b` - REQUEST-jordan-0049 creation
- `f5964db` - Phase 1: Core rename
- `cb736e3` - Phase 2: Documentation updates
- `7e93522` - Phase 3: Captain's Tour implementation
- `7da869f` - Starter pack integration guide

**Status:** Complete, ready for the-agency-starter integration
**Book chapters:** Agent Identity, Onboarding Design, First-Launch Experience, Tutorial Design
