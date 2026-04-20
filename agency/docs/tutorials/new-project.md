# Tutorial: Start a New Project

**Time:** 5 minutes
**Goal:** Create a brand new project with The Agency from scratch

## What We'll Build

Together, we'll:
1. Decide on your project type (web, mobile, Python, etc.)
2. Set up the project structure
3. Create your first workstream
4. Create your first agent
5. Make your first commit

## Step 1: Choose Your Stack

Ask the principal what kind of project they're building:

- 🌐 **Web application** (Next.js, React, etc.)
- 📱 **Mobile app** (React Native, etc.)
- 🐍 **Python project** (API, ML, etc.)
- 🦀 **Rust/Systems project**
- 📝 **Something else** - Let them describe it

## Step 2: Execute Starter Kit

Based on their choice, explain that The Agency has starter kits that set up:
- Project scaffolding
- Quality gates (linting, formatting, type checking)
- Git hooks
- Testing framework
- Development environment

For example:
```bash
# For Next.js
./tools/starter-pack nextjs my-app

# For Python
./tools/starter-pack python my-api
```

*(Note: Adapt based on available starter packs)*

## Step 3: Create First Workstream

Explain workstreams are organized areas of work. For a new project, suggest starting with a core workstream:

```bash
./tools/workstream-create web
```

Or whatever makes sense for their project (backend, mobile, core, etc.)

## Step 4: Create First Agent

Create an agent for this workstream:

```bash
./tools/agent-create web web-dev
```

Explain that this agent will:
- Work on the web workstream
- Have context about web development
- Build up knowledge over time

## Step 5: Make First Commit

Have them make their first commit with the agent:

```bash
./tools/myclaude web web-dev "Help me set up the project structure"
```

## Completion

Celebrate their achievement:

✓ Project created
✓ Workstream established
✓ First agent spawned
✓ Ready to build!

Ask if they want to:
- Learn more concepts (concepts path)
- Explore Agency features (explore path)
- Start building on their own

## Track Progress

Update their `onboarding.yaml`:
```yaml
completed_sections:
  - welcome
  - new-project
```
