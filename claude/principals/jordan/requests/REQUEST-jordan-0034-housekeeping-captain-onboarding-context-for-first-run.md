# REQUEST-jordan-0034-housekeeping-captain-onboarding-context-for-first-run

**Status:** Complete
**Priority:** High
**Requested By:** agent:housekeeping (on behalf of jordan)
**Assigned To:** housekeeping
**Created:** 2026-01-11
**Updated:** 2026-01-11

## Summary

Interactive "Choose Your Own Adventure" onboarding tutorial for new principals

## Details

When a new principal first runs `/welcome` or starts their first session with The Captain (housekeeping agent), they should experience an interactive, guided onboarding that adapts to their goals and experience level.

This is NOT a static walkthrough - it's a dynamic, branching tutorial that lets the user explore The Agency based on what they want to accomplish.

## The Tutorial Experience

### Opening Scene

```
Welcome to The Agency! I'm The Captain, your guide to multi-agent development.

Before we dive in, I'd like to understand what brings you here today.

What would you like to do?

1. 🚀 Start a new project from scratch
2. 📦 Set up The Agency in an existing codebase
3. 🔍 Explore what The Agency can do
4. 🎓 Learn the core concepts first
5. ⚡ Quick setup - I know what I'm doing
```

### Branch: Start a New Project

```
Great! Let's create something new together.

What kind of project are you building?

1. 🌐 Web application (Next.js, React, etc.)
2. 📱 Mobile app (React Native, etc.)
3. 🐍 Python project (API, ML, etc.)
4. 🦀 Rust/Systems project
5. 📝 Something else - I'll describe it
```

Then guide through:
- Project scaffolding
- First workstream creation
- First agent creation
- Making their first commit with an agent

### Branch: Existing Codebase

```
Let's integrate The Agency into your existing project.

First, tell me about your codebase:

1. What's the primary language/framework?
2. Do you use git? (Y/n)
3. Is this a monorepo or single project?
```

Then guide through:
- Where to place claude/ directory
- How to structure workstreams around existing code
- Creating agents for different areas of the codebase

### Branch: Explore

```
Let me show you around! The Agency has several key areas:

Where would you like to start?

1. 🤖 Agents - Meet the AI workers
2. 📋 Workstreams - How work is organized
3. 🔧 Tools - CLI utilities at your disposal
4. 💬 Collaboration - How agents work together
5. 🎯 REQUESTs - How work gets tracked
```

Each leads to an interactive demo of that feature.

### Branch: Learn Concepts

```
Smart choice! Understanding the fundamentals will help everything click.

The Agency is built on a few key ideas:

1. Principals - That's you! Humans who direct the work
2. Agents - AI instances with memory and context
3. Workstreams - Organized areas of focus
4. Collaboration - How agents help each other

Which concept would you like to explore first?
```

### Branch: Quick Setup

```
I like your style. Let's get you up and running fast.

I'll need a few things:
- Your name (for the principal directory): ___
- Primary workstream name: ___
- First agent name (or use 'dev'): ___

[Creates everything, shows summary]

You're all set! Here's what I created:
- claude/principals/[name]/
- claude/workstreams/[workstream]/
- claude/agents/[agent]/

Run ./tools/myclaude [workstream] [agent] to start working!
```

## Key Principles

### 1. No Dead Ends
Every path should lead somewhere useful. If the user makes an unexpected choice, gracefully redirect.

### 2. Learn by Doing
Don't just explain - have the user actually run commands, create things, and see results.

### 3. Celebrate Progress
After each section, acknowledge what they learned/created.

### 4. Easy Exit
User can always say "skip" or "I'll explore on my own" to exit the tutorial.

### 5. Remember Progress
Track what the user has seen/done so we don't repeat ourselves in future sessions.

## Technical Implementation

### State Tracking
```yaml
# claude/principals/{name}/onboarding.yaml
started: 2026-01-11
completed_sections:
  - welcome
  - concepts.agents
  - explore.tools
current_path: explore.collaboration
preferences:
  experience_level: intermediate
  primary_language: typescript
```

### Tutorial Content
```
.claude/commands/welcome.md          # Main entry point
.claude/tutorials/
  new-project.md                      # Branch: new project
  existing-codebase.md               # Branch: existing
  explore/
    agents.md
    workstreams.md
    tools.md
    collaboration.md
  concepts/
    principals.md
    agents.md
    workstreams.md
```

### Navigation Commands
- `/tutorial` - Resume tutorial from last point
- `/tutorial restart` - Start over
- `/tutorial skip` - Mark current section complete, move on
- `/tutorial status` - Show progress

## Acceptance Criteria

- [ ] Welcome flow presents 5 initial paths
- [ ] Each path leads to meaningful, interactive content
- [ ] User can create real artifacts (agents, workstreams) during tutorial
- [ ] Progress is tracked and persisted
- [ ] User can exit and resume at any point
- [ ] Tutorial adapts to user's stated experience level
- [ ] No section takes more than 5 minutes
- [ ] User ends with working knowledge of core concepts

## Deliverables

- [ ] `.claude/commands/welcome.md` - Main welcome flow
- [ ] `.claude/tutorials/` - All tutorial content
- [ ] Onboarding state tracking
- [ ] `/tutorial` command for navigation
- [ ] Progress visualization

## Notes

This is the user's first impression of The Agency. It should feel:
- **Welcoming** - Not overwhelming
- **Empowering** - They're in control
- **Productive** - They accomplish real things
- **Fun** - A bit of personality

The Captain should have a friendly, knowledgeable personality throughout.

---

## Activity Log

### 2026-01-11 - Created
- Request created by agent:housekeeping (on behalf of jordan)

### 2026-01-11 - Expanded
- Detailed "Choose Your Own Adventure" tutorial concept
- Defined 5 initial paths
- Specified technical implementation approach
- Added acceptance criteria and deliverables
