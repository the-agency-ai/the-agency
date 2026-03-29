# The Agency - Principal Guide

A guide for human stakeholders (principals) who direct work in The Agency.

For the agent constitution (rules agents must follow), see the root `CLAUDE.md`.

## What is The Agency?

The Agency is a convention-over-configuration system for running multiple Claude Code agents that collaborate on a shared codebase. It provides:

- **Workstreams** - Organized areas of work (features, infrastructure, etc.)
- **Agents** - Specialized Claude Code instances with context and memory
- **Principals** - Human stakeholders who direct work via instructions
- **Collaboration** - Inter-agent communication and handoffs
- **Quality Gates** - Enforced standards via pre-commit hooks

For detailed concept explanations, see `CONCEPTS.md`.

## Core Concepts

### Agents
Each agent has:
- `agent.md` - Identity, purpose, and capabilities
- `KNOWLEDGE.md` - Accumulated wisdom and patterns
- `WORKLOG.md` - Sprint-based work tracking
- `ADHOC-WORKLOG.md` - Out-of-plan work tracking

### Workstreams
Workstreams organize related work:
- Shared `KNOWLEDGE.md` across agents in the workstream
- Sprint directories for planned work
- Multiple agents can work on the same workstream

### Principals
Human stakeholders who provide direction:
- Requests (`REQUEST-principal-XXXX`) - Directed tasks
- Artifacts - Deliverables produced for principals
- Preferences - How they like to work

### Collaboration
Agents communicate via:
- `./tools/collaborate` - Request help from another agent
- `./tools/news-post` / `./tools/news-read` - Broadcast updates
- `./tools/nit-add` - Flag issues for later

## Directory Structure

```
CLAUDE.md                    # Agent constitution (rules agents follow)
claude/
  agents/                    # Agent definitions and context
    captain/                 # The captain - your guide (ships with The Agency)
    collaboration/           # Inter-agent messages
  workstreams/               # Workstream knowledge and sprints
    housekeeping/            # Default workstream
  principals/                # Human stakeholders
  docs/                      # Guides and reference
  logs/                      # Session and activity logs
  claude-desktop/            # Claude Desktop / MCP integration
tools/                       # CLI tools for The Agency
```

## Tools

**Session:**
- `./tools/myclaude WORKSTREAM AGENT` - Launch an agent
- `./tools/welcomeback` - Session restoration
- `./tools/session-backup` - Save session context

**Scaffolding:**
- `./tools/workstream-create` - Add a new workstream
- `./tools/agent-create` - Add a new agent
- `./tools/epic-create` - Plan major work
- `./tools/sprint-create` - Plan sprint work

**Collaboration:**
- `./tools/collaborate` - Request help
- `./tools/collaboration-respond` - Respond to requests
- `./tools/news-post` / `./tools/news-read` - Broadcasts

**Quality:**
- `./tools/commit-precheck` - Run quality gates
- `./tools/test-run` - Run tests
- `./tools/code-review` - Automated code review
- `./tools/review-spawn` - Generate review subagent prompts
- `./tools/install-hooks` - Install git pre-commit hooks

**Git:**
- `./tools/commit` - Create properly formatted commits
- `./tools/tag` - Tag work item stages (verifies tests pass)
- `./tools/sync` - Push with pre-commit checks

**GitHub:**
- `./tools/gh` - GitHub CLI wrapper (auto token injection + logging)
- `./tools/gh-pr` - PR operations (list, create, merge, etc.)
- `./tools/gh-release` - Release operations (list, create, view)
- `./tools/gh-api` - API operations (REST and GraphQL)

## Terminal Integration

Ghostty tab titles and background color tints update automatically via Claude Code hooks:
- **○ Circle** Available (ready for input, blue tint)
- **◑ Half-circle** Working (processing, green tint)
- **⚠ Triangle** Attention (needs user input, red tint)

These are triggered automatically by the `ghostty-status.sh` hook in `.claude/settings.json`.

See `TERMINAL-INTEGRATION.md` for setup and troubleshooting.

## Permissions

The Agency uses layered permissions:
- **`.claude/settings.json`** - Framework defaults (DO NOT EDIT - versioned with The Agency)
- **`.claude/settings.local.json`** - Your project permissions (gitignored - edit freely)

To add project-specific permissions (git, npm, domains):
```bash
cp .claude/settings.local.json.example .claude/settings.local.json
# Edit to add your permissions
```

See `PERMISSIONS.md` for the full model and examples.

## Secrets - First-Time Setup

If the vault is locked or uninitialized:
```bash
./tools/secret vault unlock    # Unlock for session
./tools/secret vault init      # First-time initialization
```

See `SECRETS.md` for complete reference (vault management, access control, audit logging, migration).

## Starter Packs

Starter packs provide framework-specific conventions:

- `claude/starter-packs/github-ci/` - GitHub CI/CD workflows
- `claude/starter-packs/node-base/` - Node.js base projects
- `claude/starter-packs/posthog-analytics/` - PostHog analytics integration
- `claude/starter-packs/react-app/` - React applications
- `claude/starter-packs/supabase-auth/` - Supabase authentication
- `claude/starter-packs/vercel/` - Vercel deployments

Each pack adds opinionated patterns and enforcement for that ecosystem.

## Starter Releases

**CRITICAL: When releasing updates to the-agency-starter, you MUST follow the documented release process.**

### Turnkey Principle

**The starter MUST be a complete, turnkey experience.** There are NO "advanced" or "optional" features that get excluded from the starter. Unless explicitly documented as internal-only (e.g., private principal data, work notes), ALL features, documentation, and agents ship with the starter.

When adding new features to the-agency:
1. Add the feature to `tools/starter-release` sync list
2. Ensure the feature works out-of-the-box
3. Include all necessary documentation

**Anti-pattern:** Excluding features because they "seem advanced" or "require extra setup"
**Correct approach:** Include everything; let users choose what to use

### Release Checklist

Before any starter release:
```bash
# 1. Run full test suite
./tools/starter-test --local

# 2. Verify installation
./tools/starter-verify --install

# 3. Compare files
./tools/starter-compare --install
```

All tests must pass and no unexpected differences before proceeding.

See `STARTER-RELEASE-PROCESS.md` for the complete workflow including:
- Pre-release checks
- Cutting releases with `./tools/starter-release`
- Post-release verification
- What gets synced and cleaned

## Getting Help

The captain is always available to help:

```bash
./tools/myclaude housekeeping captain "I need help with..."
```

For first-time users, try the interactive tour:
```bash
./tools/myclaude housekeeping captain
# Then type: /agency-welcome
```

## Reference Documentation

- `README.md` - User installation and getting started
- `QUICK-START.md` - Quick start guide
- `CONCEPTS.md` - Detailed concept explanations
- `TERMINAL-INTEGRATION.md` - Ghostty terminal integration
- `PERMISSIONS.md` - Permissions model and examples
- `SECRETS.md` - Complete secrets reference
- `TESTING.md` - Test service configuration and usage
- `PRINCIPALS.md` - Principal management
- `REPO-RELATIONSHIP.md` - How the-agency and the-agency-starter relate
- `STARTER-RELEASE-PROCESS.md` - Starter release workflow and tools
- `CI-TROUBLESHOOTING.md` - CI failure investigation and fixes

---

*The Agency - Multi-agent development, done right.*
