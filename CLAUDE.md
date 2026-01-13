# The Agency

A multi-agent development framework for Claude Code.

## What is The Agency?

The Agency is a convention-over-configuration system for running multiple Claude Code agents that collaborate on a shared codebase. It provides:

- **Workstreams** - Organized areas of work (features, infrastructure, etc.)
- **Agents** - Specialized Claude Code instances with context and memory
- **Principals** - Human stakeholders who direct work via instructions
- **Collaboration** - Inter-agent communication and handoffs
- **Quality Gates** - Enforced standards via pre-commit hooks

## Quick Start

```bash
# Launch the housekeeping agent (your guide)
./tools/myclaude housekeeping housekeeping

# Ask housekeeping to help you set up your project
```

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
- Instructions (`INSTR-XXXX`) - Directed tasks
- Artifacts - Deliverables produced for principals
- Preferences - How they like to work

### Collaboration
Agents communicate via:
- `./tools/collaborate` - Request help from another agent
- `./tools/news-post` / `./tools/news-read` - Broadcast updates
- `./tools/nit-add` - Flag issues for later

## Directory Structure

```
CLAUDE.md                    # This file - the constitution
claude/
  agents/                    # Agent definitions and context
    housekeeping/            # Your guide agent (ships with The Agency)
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
- `./tools/dispatch-collaborations` - Launch agents for pending work

**Quality:**
- `./tools/commit-precheck` - Run quality gates
- `./tools/test-run` - Run tests
- `./tools/code-review` - Automated code review

**Git:**
- `./tools/sync` - Push with pre-commit checks
- `./tools/doc-commit` - Commit documentation

**Secrets:**
- `./tools/secret` - Secret management CLI (see Secrets section below)

## Secrets

**All secrets MUST be stored in the Secret Service.** Do not store secrets in `.env` files, config files, or anywhere else in the codebase.

### Quick Start

```bash
# First time: Initialize the vault
./tools/secret vault init

# Unlock the vault (required after restart or 30-min timeout)
./tools/secret vault unlock

# Store a secret
./tools/secret create my-api-key --type=api_key --service=GitHub

# Fetch a secret (logged for audit)
./tools/secret get my-api-key
```

### Vault Management

The vault protects all secrets with a master passphrase using Argon2id key derivation and AES-256-GCM encryption.

```bash
./tools/secret vault init      # Initialize vault (first time only)
./tools/secret vault unlock    # Unlock for session (30-min timeout)
./tools/secret vault lock      # Lock vault immediately
./tools/secret vault status    # Check vault status
```

### Storing Secrets

```bash
# Basic secret
./tools/secret create my-token --type=token --service=GitHub

# With description
./tools/secret create api-key --type=api_key --service=Anthropic \
  --description="Claude API key for production"

# Secret types: api_key, token, password, certificate, ssh_key, generic
```

### Fetching Secrets

```bash
# Get secret value (logged for audit)
./tools/secret get my-token

# Show metadata only (not logged)
./tools/secret show my-token

# List all secrets
./tools/secret list

# Filter by service
./tools/secret list --service=GitHub
```

### Integration with Tools

Secrets can be tagged for use by specific tools:

```bash
# Tag secret for use by the gh CLI
./tools/secret tag github-token --tool=gh

# Tag for a local tool
./tools/secret tag my-secret --local-tool=./tools/myclaude

# Find secrets by tag
./tools/secret list --tool=gh
```

### Access Control

Secrets can be shared with specific agents or principals:

```bash
# Grant read access to an agent
./tools/secret grant my-secret --to=agent:housekeeping --permission=read

# Grant admin access to a principal
./tools/secret grant my-secret --to=principal:jordan --permission=admin

# Revoke access
./tools/secret revoke my-secret --from=agent:housekeeping

# List grants
./tools/secret grants my-secret
```

### Environment Variable Integration

```bash
# Export for shell use
eval $(./tools/secret env my-token MY_TOKEN)
# Results in: export MY_TOKEN=<secret-value>

# Use in scripts
MY_TOKEN=$(./tools/secret get my-token)
```

### Audit Logging

All secret access is logged for security:

```bash
# View access log for a secret
./tools/secret audit my-token

# View all access logs
./tools/secret audit --all
```

### Migration from .env Files

If you have existing secrets in `.env` files, migrate them:

```bash
./tools/secret-migrate --dry-run  # Preview what will be migrated
./tools/secret-migrate            # Run the migration
```

### Service Configuration

The Secret Service runs as part of agency-service on port 3141:

```bash
# Start the service
cd services/agency-service && bun run dev

# Environment variables
SECRET_SERVICE_URL=http://localhost:3141/api/secret
AGENCY_USER=principal:jordan  # or agent:housekeeping
```

## Conventions

### Naming
- Agents: lowercase, hyphenated (`agent-manager`, `web`)
- Workstreams: lowercase (`agents`, `web`, `analytics`)
- Instructions: `INSTR-XXXX-principal-workstream-agent-title.md`
- Artifacts: `ART-XXXX-principal-workstream-agent-date-title.md`

### Git Commits
```
workstream/agent: type(scope): message

[body]

Generated with [Claude Code](https://claude.com/claude-code)
Co-Authored-By: Claude <noreply@anthropic.com>
```

### API Design (Explicit Operations)
All API endpoints use explicit operation names. Do NOT rely on HTTP verb semantics.

**Pattern:**
```
POST /api/resource/create      # Create
GET  /api/resource/list        # List with filters
GET  /api/resource/get/:id     # Get single
POST /api/resource/update/:id  # Update
POST /api/resource/delete/:id  # Delete
POST /api/resource/action/:id  # Specific actions (approve, archive, etc.)
GET  /api/resource/stats       # Statistics
```

**Why explicit operations:**
- Self-documenting URLs
- Clear intent without needing to know HTTP semantics
- Easier to grep/search for operations
- Consistent across all services

**Anti-patterns (do NOT use):**
```
POST   /api/resource           # Ambiguous - is this create?
PATCH  /api/resource/:id       # Relies on verb semantics
DELETE /api/resource/:id       # Relies on verb semantics
GET    /api/resource/:id       # Ambiguous - use /get/:id
```

### Quality Gates
Pre-commit hooks enforce:
1. Code formatting
2. Linting
3. Type checking
4. Unit tests
5. Code review checks
6. API design patterns

## Work Items

Work in The Agency is tracked through REQUEST files. Each REQUEST goes through defined stages.

### Work Item Types
- `REQUEST-principal-XXXX` - Work requested by a principal
- `BUG-XXXX` - Bug fixes (can be addressed individually or via REQUEST)
- `ADHOC-` - Agent-initiated work (logged in ADHOC-WORKLOG.md)

### REQUEST Stages
```
impl     → Implementation complete, tested locally
review   → Code review complete, fixes applied
tests    → Test review complete, improvements applied
complete → All phases done, ready for release
```

### Tagging Convention
```bash
./tools/tag REQUEST-jordan-0017 impl      # REQUEST-jordan-0017-impl
./tools/tag REQUEST-jordan-0017 review    # REQUEST-jordan-0017-review
./tools/tag REQUEST-jordan-0017 tests     # REQUEST-jordan-0017-tests
./tools/tag REQUEST-jordan-0017 complete  # REQUEST-jordan-0017-complete
./tools/tag release 0.6.0                 # v0.6.0
```

### Tools
```bash
./tools/tag REQUEST-xxx stage   # Create stage tag
./tools/commit "message" ID     # Create formatted commit
./tools/release 0.7.0           # Cut a release
```

## Development Workflow

**The working tree should ALWAYS be clean.**

### Breaking Work into Iterations

Large REQUESTs should be broken into **phases** or **iterations**. Each iteration:
- Has a clear, testable deliverable
- Includes tests for the new functionality
- Goes through the full review cycle
- Is tagged independently (e.g., `REQUEST-xxx-phase1-impl`)

### Iteration Workflow

Each iteration follows this cycle:

#### 1. Implement + Tests
- Build the feature/fix
- Write tests alongside the implementation
- Run tests locally, iterate until **GREEN**
- Commit and TAG: `REQUEST-xxx-phaseN-impl`
- Document work completed and tag in the REQUEST file

#### 2. Code Review
- Conduct code review with **two subagents**
- Consolidate review findings into a single list
- Apply changes from the review
- Modify and expand tests as needed
- Run tests locally, iterate until **GREEN**
- Commit and TAG: `REQUEST-xxx-phaseN-review`
- Document work completed and tag in the REQUEST file

#### 3. Test Review
- Conduct test review with **two subagents**
- Consolidate test review findings
- Apply test improvements
- Run tests locally, iterate until **GREEN**
- Commit and TAG: `REQUEST-xxx-phaseN-tests`
- Document work completed and tag in the REQUEST file

#### 4. Release (Final Phase Only)
- Tag REQUEST complete: `./tools/tag REQUEST-xxx complete`
- Cut release: `./tools/release X.Y.Z --push --github`

### Workflow Summary
```
For each iteration/phase:
  1. Build feature + tests
  2. Run tests → iterate until GREEN
  3. Commit & TAG (REQUEST-xxx-phaseN-impl)
  4. Document in REQUEST
  5. Code review (2 subagents) → consolidated changes
  6. Apply changes, expand tests
  7. Run tests → iterate until GREEN
  8. Commit & TAG (REQUEST-xxx-phaseN-review)
  9. Document in REQUEST
  10. Test review (2 subagents) → consolidated improvements
  11. Apply test changes
  12. Run tests → iterate until GREEN
  13. Commit & TAG (REQUEST-xxx-phaseN-tests)
  14. Document in REQUEST

Final phase: TAG complete + release
```

### Key Principles
- **Clean working tree**: Always commit before moving on
- **Small commits**: Each commit should be a logical unit
- **Tags for milestones**: Tag after each stage (impl, review, tests)
- **Collaborative review**: Two subagents provide multiple perspectives
- **Consolidated changes**: Don't apply changes piecemeal - gather all feedback first
- **Tests are mandatory**: Every iteration includes tests
- **Document as you go**: Update REQUEST after each commit/tag

## Starter Packs

Starter packs provide framework-specific conventions:

- `claude/starter-packs/nextjs/` - Next.js projects
- `claude/starter-packs/react-native/` - React Native apps
- `claude/starter-packs/python/` - Python projects

Each pack adds opinionated patterns and enforcement for that ecosystem.

## Development Dependencies

Some tools require external dependencies:

### AgencyBench Icon Generation
To regenerate icons from `apps/agency-bench/public/logo.svg`:

```bash
# Install librsvg (provides rsvg-convert)
brew install librsvg

# Generate PNG icons
cd apps/agency-bench/src-tauri/icons
rsvg-convert -w 32 -h 32 ../../public/logo.svg > 32x32.png
rsvg-convert -w 128 -h 128 ../../public/logo.svg > 128x128.png
rsvg-convert -w 256 -h 256 ../../public/logo.svg > 128x128@2x.png

# Create iconset and .icns for macOS
mkdir -p icon.iconset
rsvg-convert -w 16 -h 16 ../../public/logo.svg > icon.iconset/icon_16x16.png
rsvg-convert -w 32 -h 32 ../../public/logo.svg > icon.iconset/icon_16x16@2x.png
rsvg-convert -w 32 -h 32 ../../public/logo.svg > icon.iconset/icon_32x32.png
rsvg-convert -w 64 -h 64 ../../public/logo.svg > icon.iconset/icon_32x32@2x.png
rsvg-convert -w 128 -h 128 ../../public/logo.svg > icon.iconset/icon_128x128.png
rsvg-convert -w 256 -h 256 ../../public/logo.svg > icon.iconset/icon_128x128@2x.png
rsvg-convert -w 256 -h 256 ../../public/logo.svg > icon.iconset/icon_256x256.png
rsvg-convert -w 512 -h 512 ../../public/logo.svg > icon.iconset/icon_256x256@2x.png
rsvg-convert -w 512 -h 512 ../../public/logo.svg > icon.iconset/icon_512x512.png
rsvg-convert -w 1024 -h 1024 ../../public/logo.svg > icon.iconset/icon_512x512@2x.png
iconutil -c icns icon.iconset -o icon.icns
rm -rf icon.iconset
```

## Getting Help

Your housekeeping agent is always available:

```bash
./tools/myclaude housekeeping housekeeping "I need help with..."
```

## Contributing

See `CONTRIBUTING.md` for how to:
- Submit starter packs
- Improve core tools
- Report issues

---

*The Agency - Multi-agent development, done right.*
