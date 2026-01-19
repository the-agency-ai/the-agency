# The Agency - Quick Start Guide

A multi-agent development framework for Claude Code.

## What is The Agency?

The Agency is an SDLC-style framework that coordinates **multiple AI agents + multiple human principals** instead of everyone using Claude Code individually. It provides:

- **Convention over Configuration** - Opinionated tooling that enforces disciplined workflows
- **Multi-Agent Coordination** - Run up to seven Claude Code agents in parallel, collaborating on a single project
- **Context Management** - Systematic saving and restoring of state so you can stop/restart without losing context
- **Quality Gates** - Pre-commit hooks enforce standards automatically

### Key Benefits

1. **Coordinated Development** - Multiple agents work in parallel with explicit patterns for collaboration
2. **Design System Integration** - Extract design systems from Figma and teach Claude consistent UI generation
3. **Instrumented Logging** - Agents don't flood context windows with raw stdout; they get success/failure and only necessary results
4. **Reduced "Mother May I"** - Safe read-only operations have pre-granted permissions

## Installation

### Prerequisites

- **macOS** - The Agency currently supports macOS only
- Everything else is installed automatically

### Step 1: Install The Agency

```bash
# Run the installer
curl -fsSL https://raw.githubusercontent.com/the-agency-ai/the-agency-starter/main/install.sh | bash
```

The installer automatically:
- Installs Claude Code (if not present)
- Downloads The Agency starter to `~/the-agency-starter`

### Step 2: Create Your Project

```bash
# Navigate to the starter
cd ~/the-agency-starter

# Create a new project
./tools/project-new my-awesome-project

# Navigate to your project
cd ~/my-awesome-project
```

### Step 3: Launch the Captain

```bash
./tools/myclaude housekeeping captain
```

On first launch, myclaude automatically:
- Installs Bun runtime (if needed)
- Installs service dependencies
- Starts the Agency Service

You'll see status for each:
```
✓ Bun runtime present
✓ Dependencies present
✓ Agency Service running
```

## First Session

When the captain launches, you'll see:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Launching: captain on workstream: housekeeping
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### Interactive Tour

Type `/welcome` to start the interactive tour. The captain will:
- Explain core concepts
- Show you the directory structure
- Walk through available tools

### Common Commands

```bash
# Launch an agent
./tools/myclaude WORKSTREAM AGENTNAME [prompt]

# Create a new workstream
./tools/workstream-create my-feature

# Create a new agent
./tools/agent-create my-feature my-agent

# Check tool version
./tools/myclaude --version
```

## Core Concepts

### Agents

Each agent has its own identity and context:
- `agent.md` - Identity, purpose, capabilities
- `KNOWLEDGE.md` - Accumulated wisdom and patterns
- `WORKLOG.md` - Sprint-based work tracking

### Workstreams

Organize related work:
- Shared knowledge across agents in the workstream
- Sprint directories for planned work
- Multiple agents can work on the same workstream

### Principals

Human stakeholders who provide direction:
- Instructions (`INSTR-XXXX`) - Directed tasks
- Artifacts - Deliverables produced for principals

## Agent Collaboration

Agents communicate through explicit tools:

```bash
# Request help from another agent
./tools/collaborate agent-name "I need help with X"

# Broadcast news to all agents
./tools/news-post "Released v1.0"

# Read news updates
./tools/news-read
```

## Secret Service

The Agency includes a built-in secret service for secure credential management.

### First-Time Setup

```bash
# Initialize the vault (creates master passphrase)
./tools/secret vault init

# You'll be prompted to create a master passphrase
# This encrypts all secrets - don't lose it!
```

### Common Operations

```bash
# Store a secret (e.g., API key)
./tools/secret create anthropic-api-key --type=api_key --service=Anthropic

# Retrieve a secret
./tools/secret get anthropic-api-key

# List all secrets
./tools/secret list

# Unlock vault (if locked after timeout)
./tools/secret vault unlock
```

### Security Model

- **Encryption:** AES-256-GCM with Argon2id key derivation
- **Session Tokens:** Auto-generated when launching agents
- **Audit Logging:** All secret access is logged
- **30-min Timeout:** Vault auto-locks for security

### Migration from .env Files

If you have existing secrets:

```bash
# Preview what will be migrated
./tools/secret-migrate --dry-run

# Run the migration
./tools/secret-migrate

# Remove .env files after migration
```

## Agency Service

The Agency Service provides backend infrastructure:

| Service | Purpose |
|---------|---------|
| **Secret Service** | Secure credential management |
| **Log Service** | Instrumented agent logging |
| **Message Service** | Inter-agent communication |
| **Request Service** | Work item tracking |

The service runs on port 3141 and is automatically started by `myclaude`.

### Manual Service Control

```bash
# Start the service
./tools/agency-service start

# Stop the service
./tools/agency-service stop

# Check status
./tools/agency-service status
```

## Quality Gates

Pre-commit hooks enforce standards automatically:

1. Code formatting
2. Linting
3. Type checking
4. Unit tests
5. Code review checks

Run manually with:

```bash
./tools/commit-precheck
```

## Session Context

Agents automatically save and restore session context:

```bash
# Save context manually
./tools/context-save --checkpoint "Completed feature X"

# Context auto-restores on next session start
```

## Directory Structure

```
CLAUDE.md                    # The constitution
claude/
  agents/                    # Agent definitions
    captain/                 # Your guide
  workstreams/               # Organized work areas
    housekeeping/            # Default workstream
  principals/                # Human stakeholders
  docs/                      # Guides and reference
tools/                       # CLI tools
source/
  services/
    agency-service/          # Backend services
```

## Next Steps

1. **Run the tour:** Type `/welcome` in your first session
2. **Create a workstream:** `./tools/workstream-create my-feature`
3. **Create an agent:** `./tools/agent-create my-feature my-agent`
4. **Start working:** `./tools/myclaude my-feature my-agent "Build feature X"`

## Troubleshooting

### /welcome Command Not Working

If `/welcome` doesn't work after installation:

1. **Always use myclaude to launch Claude:**
   ```bash
   ./tools/myclaude housekeeping captain
   ```
   Don't run `claude` directly - myclaude ensures proper directory context.

2. **Verify commands exist:**
   ```bash
   ls .claude/commands/
   # Should show: welcome.md  tutorial.md
   ```

3. **Restart Claude from project directory:**
   ```bash
   cd ~/your-project
   ./tools/myclaude housekeeping captain
   ```

### Dependencies Missing

If you see "command not found" errors:

```bash
# Check all dependencies
./tools/dependencies-check --verbose

# Install missing dependencies
./tools/dependencies-check --fix
```

### Services Not Starting

If agency-service fails to start:

```bash
# Check service status
./tools/agency-service status

# Restart the service
./tools/agency-service stop
./tools/agency-service start

# Check logs
./tools/log recent
```

## Getting Help

The captain is always available:

```bash
./tools/myclaude housekeeping captain "I need help with..."
```

---

*The Agency - Multi-agent development, done right.*
