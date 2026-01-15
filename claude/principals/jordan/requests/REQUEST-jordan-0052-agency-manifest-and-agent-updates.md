# REQUEST-jordan-0052: Agency Manifest and Agent-Driven Updates

**Principal:** jordan
**Workstream:** housekeeping
**Agent:** captain
**Status:** Design
**Priority:** High
**Created:** 2026-01-15

---

## Core Principle

> "As much as possible, Agents vs. Principals should be doing the work of development."

- Don't ask the user to run a tool - run it
- Don't ask the user to configure something in a GUI - use CLI/API
- Don't ask the user to install dependencies - install them
- Only involve the principal when human judgment is required

---

## Problem Statement

Current state:
- `project-update` is a human-run tool
- Users must manually check for updates, run installation commands
- Services must be manually started
- No unified view of what's installed vs available

Desired state:
- Agents detect when updates are available
- Agents apply updates autonomously
- Agents install dependencies and start services
- Manifest tracks component state for agent awareness

---

## Design

### 1. Agency Manifest (`.agency/manifest.json`)

Central source of truth for project state:

```json
{
  "schema_version": "1.0",
  "project": {
    "name": "my-project",
    "created_at": "2026-01-14T10:30:00Z",
    "starter_version": "1.0.9"
  },
  "source": {
    "type": "github",
    "repo": "the-agency-ai/the-agency-starter",
    "branch": "main"
  },
  "components": {
    "core": {
      "description": "Tools, docs, and framework files",
      "version": "1.0.9",
      "status": "installed",
      "updated_at": "2026-01-14T10:30:00Z"
    },
    "agency-service": {
      "description": "Telemetry and logging service",
      "version": "1.0.0",
      "status": "installed",
      "path": "source/services/agency-service",
      "dependencies": "installed",
      "runtime": {
        "port": 3141,
        "auto_start": true
      }
    },
    "agency-bench": {
      "description": "Benchmarking desktop app",
      "version": "1.0.0",
      "status": "available",
      "path": "source/apps/agency-bench",
      "optional": true
    }
  },
  "starter_packs": {
    "node-base": { "status": "applied", "applied_at": "2026-01-14T..." },
    "react-app": { "status": "available" },
    "supabase-auth": { "status": "available" },
    "github-ci": { "status": "available" },
    "vercel": { "status": "available" },
    "posthog-analytics": { "status": "available" }
  }
}
```

### 2. Component Registry (Starter Side)

The starter defines available components in `registry.json`:

```json
{
  "schema_version": "1.0",
  "starter_version": "1.0.9",
  "components": {
    "core": {
      "description": "Tools, docs, and framework files",
      "version": "1.0.9",
      "required": true,
      "paths": ["tools/", "claude/", "CLAUDE.md", ".claude/"]
    },
    "agency-service": {
      "description": "Telemetry and logging service",
      "version": "1.0.0",
      "required": false,
      "path": "source/services/agency-service",
      "install": {
        "command": "pnpm install",
        "cwd": "source/services/agency-service"
      },
      "post_install": {
        "command": "./tools/service start"
      }
    },
    "agency-bench": {
      "description": "Benchmarking desktop app",
      "version": "1.0.0",
      "required": false,
      "path": "source/apps/agency-bench",
      "install": {
        "command": "pnpm install",
        "cwd": "source/apps/agency-bench"
      }
    }
  },
  "starter_packs": {
    "node-base": { "description": "Node.js foundation", "dependencies": [] },
    "react-app": { "description": "Next.js web app", "dependencies": ["node-base"] },
    "supabase-auth": { "description": "Authentication", "dependencies": ["node-base", "react-app"] }
  }
}
```

### 3. Agent-Driven Update Flow

#### On Session Start (myclaude)

```bash
# 1. Check if services should be running
if manifest says agency-service.runtime.auto_start == true; then
    if service not running; then
        start service
    fi
fi

# 2. Launch claude with update awareness
# Agent will check for updates as part of session
```

#### Agent Update Check (Automatic)

When an agent starts, it can check:

```bash
./tools/project-update --check --quiet
```

Returns JSON:
```json
{
  "current_version": "1.0.9",
  "latest_version": "1.1.0",
  "updates_available": true,
  "components": {
    "core": { "current": "1.0.9", "latest": "1.1.0", "action": "update" },
    "agency-service": { "current": "1.0.0", "latest": "1.0.1", "action": "update" }
  }
}
```

Agent decides whether to:
- Apply updates immediately (minor/patch)
- Inform principal about major updates
- Schedule update for session end

#### Agent Applies Update

```bash
# Agent runs this - not the user
./tools/project-update --apply --component=core
./tools/project-update --apply --component=agency-service
```

The tool:
1. Downloads/copies new files
2. Runs install commands from registry
3. Runs post-install hooks
4. Updates manifest
5. Reports success/failure

### 4. CLI Interface

```bash
# Check for updates (agent-friendly, returns JSON with --json flag)
./tools/project-update --check [--json]

# Apply all updates
./tools/project-update --apply

# Apply specific component
./tools/project-update --apply --component=agency-service

# Install new component
./tools/project-update --install agency-bench

# Apply starter pack
./tools/project-update --pack react-app

# Show manifest status
./tools/project-update --status [--json]

# Initialize manifest for existing project
./tools/project-update --init
```

### 5. myclaude Service Check

Immediate deliverable:

```bash
# In myclaude, before launching claude
check_services() {
    if [[ -f ".agency/manifest.json" ]]; then
        # Read auto_start services from manifest
        # Start any that should be running but aren't
    elif [[ -d "source/services/agency-service" ]]; then
        # Fallback: if service dir exists, try to start
        if ! ./tools/service status &>/dev/null; then
            ./tools/service start
        fi
    fi
}
```

---

## Implementation Phases

### Phase 1: Foundation
- [ ] Create manifest schema
- [ ] Create registry schema
- [ ] Update `project-new` to generate manifest
- [ ] Add `--init` to generate manifest for existing projects
- [ ] Add service check to `myclaude`

### Phase 2: Agent-Friendly Updates
- [ ] Add `--check --json` for agent consumption
- [ ] Add `--apply --component=X` for targeted updates
- [ ] Add install/post-install hook execution
- [ ] Manifest auto-update on changes

### Phase 3: Starter Packs Integration
- [ ] Track applied packs in manifest
- [ ] Add `--pack` command for applying packs
- [ ] Dependency resolution for packs

### Phase 4: Agent Automation
- [ ] Agent checks for updates on session start
- [ ] Agent applies minor/patch updates automatically
- [ ] Agent reports major updates to principal
- [ ] Update scheduling (session end, etc.)

---

## Success Criteria

- [ ] Manifest accurately tracks installed components
- [ ] `myclaude` starts required services automatically
- [ ] Agents can check for updates via `--check --json`
- [ ] Agents can apply updates without user intervention
- [ ] Install hooks run automatically (pnpm install, etc.)
- [ ] Principal only involved for major decisions

---

## Principles Embodied

1. **Agent Autonomy** - Agents do the work, principals make decisions
2. **CLI/API First** - No GUI configuration required
3. **Self-Aware System** - Manifest provides system introspection
4. **Progressive Enhancement** - Works without manifest, better with it

---

## Work Log

### 2026-01-15

- Created REQUEST
- Designed manifest and registry schemas
- Outlined agent-driven update flow
- Defined implementation phases
