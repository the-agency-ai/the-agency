# Tutorial: Integrate with Existing Codebase

**Time:** 5 minutes
**Goal:** Add The Agency to an existing project

## Overview

We'll integrate The Agency into your existing codebase by:
1. Understanding your project structure
2. Creating appropriate workstreams
3. Creating agents for different areas
4. Setting up quality gates

## Step 1: Understand the Codebase

Ask the principal about their project:

**Questions to ask:**
- What's the primary language/framework?
- Is this a monorepo or single project?
- What are the main areas of the codebase? (frontend, backend, mobile, etc.)
- Do you use git? (Should be yes, but verify)

## Step 2: Map Workstreams to Code Areas

Explain that workstreams should map to logical areas of the codebase.

**Example for a full-stack app:**
- `web` - Frontend code
- `api` - Backend API
- `database` - Database migrations and schema
- `infrastructure` - DevOps, deployment

**Example for a monorepo:**
- `packages` - Shared packages
- `apps` - Individual applications
- `tools` - Build tools and utilities

Have them decide on 2-3 initial workstreams:

```bash
./tools/workstream-create web
./tools/workstream-create api
```

## Step 3: Create Agents

Create at least one agent per workstream:

```bash
./tools/agent-create web frontend
./tools/agent-create api backend
```

Explain that each agent will:
- Focus on their workstream
- Learn patterns specific to that area
- Build up specialized knowledge

## Step 4: Configure Quality Gates

The Agency can add quality gates to existing projects:

```bash
# Add pre-commit hooks
./tools/commit-precheck --setup

# Configure linting, formatting, type checking based on their stack
```

## Step 5: First Multi-Agent Task

Give them a sample multi-agent workflow:

```bash
# Frontend agent
./tools/myclaude web frontend "Add a new user profile page"

# Backend agent (if needed)
./tools/myclaude api backend "Create API endpoint for user profile"
```

Show how agents can collaborate via `./tools/collaborate`.

## Integration Tips

**For existing teams:**
- One principal per team member
- Agents can be shared or personal
- Use REQUESTs to coordinate work

**For solo developers:**
- Create agents for different hats you wear
- Let agents specialize in different areas
- Use collaboration when changes span areas

## Completion

Celebrate:

✓ Workstreams mapped to codebase
✓ Agents created for key areas
✓ Quality gates configured
✓ Ready for multi-agent development!

Ask if they want to:
- Explore collaboration features
- Learn more about workstreams
- Start working with their agents

## Track Progress

Update their `onboarding.yaml`:
```yaml
completed_sections:
  - welcome
  - existing-codebase
```
