# Getting Started with The Agency

A step-by-step guide to setting up your first multi-agent development environment.

**Time to complete:** ~10 minutes

## Prerequisites

**Required:**
- [Claude Code](https://claude.ai/code) installed and working
- Git
- A project you want to AI-augment (or we'll create one)

**Recommended CLI Tools (macOS):**

The Agency works best with these tools installed:

```bash
# Essential (strongly recommended)
brew install jq gh tree

# Enhanced experience (optional)
brew install yq fzf bat ripgrep
```

| Tool | Purpose |
|------|---------|
| `jq` | Parse JSON (API responses, package.json) |
| `gh` | GitHub operations (PRs, issues, releases) |
| `tree` | Visualize project structure |
| `yq` | Edit YAML configs programmatically |
| `fzf` | Fuzzy search (try: `./tools/find-tool -l \| fzf`) |
| `bat` | Syntax-highlighted file viewing |
| `rg` | Lightning-fast code search |

Or run after installation: `./tools/setup-mac --all`

## Step 1: Fork and Clone

```bash
# Fork on GitHub first, then:
git clone https://github.com/YOUR_USERNAME/the-agency-starter.git my-project
cd my-project

# Make tools executable
chmod +x tools/*
```

## Step 2: Configure Your Identity

Edit `claude/config.yaml` to map your system username to your principal name:

```yaml
principals:
  # Map your system username to your principal name
  # Run `whoami` in terminal to get your system username
  your_username: YourName
  default: unknown

project:
  name: "My Project"
  timezone: "America/New_York"  # Your timezone
```

Test it:
```bash
./tools/principal
# Should output: YourName
```

## Step 3: Meet Your Housekeeping Agent

The housekeeping agent is your guide. Launch it:

```bash
./tools/myclaude housekeeping housekeeping
```

When it starts, it will:
1. Introduce itself
2. Ask what you're building
3. Help you set up your project structure

**Try saying:** "I'm building a Next.js web app. Help me set up The Agency for it."

## Step 4: Create Your First Workstream

Workstreams organize related work. Have housekeeping create one, or do it yourself:

```bash
./tools/create-workstream web "Web Application"
```

This creates:
```
claude/workstreams/web/
  KNOWLEDGE.md    # Shared knowledge for this workstream
```

## Step 5: Create Your First Agent

Agents are specialized Claude instances. Create one for your web work:

```bash
./tools/create-agent web web
```

This creates:
```
claude/agents/web/
  agent.md           # Agent identity and purpose
  KNOWLEDGE.md       # What this agent has learned
  WORKLOG.md         # Sprint-based work tracking
  ADHOC-WORKLOG.md   # Out-of-plan work
```

Edit `claude/agents/web/agent.md` to describe your agent's role:

```markdown
# Web Agent

**Workstream:** web
**Purpose:** Build and maintain the web application frontend

## Expertise
- Next.js 15
- React
- TypeScript
- Tailwind CSS

## Responsibilities
- Implement UI components
- Handle client-side state
- Optimize performance
```

## Step 6: Launch Your Agent

```bash
./tools/myclaude web web
```

Your agent will:
1. Read its identity from `agent.md`
2. Check for any active instructions
3. Ask what you want to work on

## Step 7: Your First Instruction

As a principal, you direct work via instructions. Create one:

```bash
./tools/capture-instruction -t "Add dark mode toggle" "Add a dark mode toggle to the settings page. It should persist the preference in localStorage."
```

This creates an instruction file that your web agent will see at session start.

## Step 8: Execute and Complete

Have your web agent implement the feature:

1. Agent sees the instruction at session start
2. Agent implements the feature
3. Agent marks instruction complete:
   ```bash
   ./tools/complete-instruction INSTR-0001 "Added dark mode toggle with localStorage persistence. See src/components/ThemeToggle.tsx"
   ```

## Step 9: Collaboration (Optional)

If you have multiple agents, they can collaborate:

```bash
# From web agent, request help from api agent
./tools/collaborate api "Need API endpoint for theme preference" "We need a GET/POST /api/user/preferences endpoint to sync theme across devices"
```

Launch the api agent to respond:
```bash
./tools/myclaude api api
# Agent sees collaboration request and handles it
```

## Step 10: Quality Gates

Before pushing, run quality checks:

```bash
./tools/pre-commit-check
```

This runs:
1. Formatting
2. Linting
3. Type checking
4. Unit tests
5. Code review

Push using the sync tool (runs quality gates automatically):
```bash
./tools/sync
```

---

## What's Next?

### Add More Agents

As your project grows, add specialized agents:
- `api` - Backend/API development
- `infra` - Infrastructure and DevOps
- `data` - Database and migrations
- `test` - Testing and QA

### Use Epics and Sprints

For larger initiatives:
```bash
./tools/create-epic 1        # Create epic001
./tools/create-sprint web 1 1  # Create web/epic001/sprint001
```

### Apply a Starter Pack

If you're using a specific framework:
```bash
# Copy Next.js conventions
cp -r claude/starter-packs/nextjs/* .
```

### Set Up Claude Desktop Integration

See `claude/claude-desktop/` for MCP server setup that lets Claude Desktop coordinate your agents.

### Check the Docs

- `CLAUDE.md` - The constitution (agents read this)
- `claude/docs/CONCEPTS.md` - Deep dive on all concepts
- `claude/docs/guides/` - Specific workflows

---

## Quick Reference

### Common Commands

```bash
# Launch an agent
./tools/myclaude {workstream} {agent}

# Create things
./tools/create-workstream {name} "{description}"
./tools/create-agent {workstream} {name}
./tools/capture-instruction -t "Title" "Content"

# Collaboration
./tools/collaborate {target-agent} "Subject" "Request"
./tools/post-news "Update message"
./tools/read-news

# Quality
./tools/pre-commit-check
./tools/sync

# Discovery
./tools/find-tool -l          # List all tools
./tools/find-tool "keyword"   # Search tools
```

### Directory Structure

```
claude/
  agents/{name}/        # Agent definitions
  workstreams/{name}/   # Work organization
  principals/{name}/    # Human stakeholders
  docs/                 # Guides and reference
  config.yaml           # Project configuration
tools/                  # CLI tools
```

### Naming Conventions

| Entity | Format | Example |
|--------|--------|---------|
| Agent | lowercase-hyphen | `web`, `agent-manager` |
| Workstream | lowercase | `web`, `agents` |
| Instruction | INSTR-XXXX | `INSTR-0001-jordan-web-web-dark-mode.md` |
| Artifact | ART-XXXX | `ART-0001-jordan-web-web-2026-01-01-report.md` |

---

## Troubleshooting

### "Permission denied" on tools
```bash
chmod +x tools/*
```

### Agent doesn't see my instruction
- Check the instruction's **To:** field matches `{workstream}/{agent}`
- Run `./tools/show-instructions` to verify

### Git push fails
- Use `./tools/sync` instead of `git push` directly
- Check for merge conflicts: `git status`

### Tools not found
- Make sure you're in the project root
- Check tool exists: `ls tools/`

---

## Getting Help

### Ask Housekeeping
Your housekeeping agent knows The Agency inside and out:
```bash
./tools/myclaude housekeeping housekeeping "How do I...?"
```

### Check Documentation
- `CLAUDE.md` - Quick reference
- `claude/docs/CONCEPTS.md` - All concepts explained
- `claude/docs/guides/` - Specific workflows

### Report Issues
https://github.com/jordandm/the-agency-starter/issues

---

*Welcome to The Agency. Build something amazing.*
