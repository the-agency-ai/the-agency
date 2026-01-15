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

### 0. The Agency Hub

**Core Principle:** After the initial install, everything is done through Claude Code via agents.

The starter becomes a **hub** - a central place to manage The Agency and all projects created from it.

#### Installation (The Only Non-Agent Step)

```bash
curl -fsSL https://the-agency.ai/install | bash
```

This installs the starter and sets up the environment. **Everything after this is agent-driven.**

#### The Hub Command

```bash
cd ~/the-agency-starter
./agency
```

This launches Claude Code with the **Hub Agent** - a special agent that manages the starter and all projects.

#### What the Hub Agent Can Do

```
┌─────────────────────────────────────────────────────────────┐
│  The Agency Hub                                             │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  Welcome back! Here's the current state:                    │
│                                                             │
│  Starter: v1.0.9 (v1.1.0 available)                         │
│                                                             │
│  Your Projects:                                             │
│    1. my-awesome-app    ~/code/my-awesome-app    v1.0.9     │
│    2. client-project    ~/code/client-project    v1.0.8 ⚠️  │
│    3. side-hustle       ~/code/side-hustle       v1.0.9     │
│                                                             │
│  What would you like to do?                                 │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

**Hub Agent Capabilities:**

| Command | What Happens |
|---------|--------------|
| "Update the starter" | Pulls latest from GitHub, handles conflicts |
| "What's new?" | Shows changelog, new features, breaking changes |
| "Create a new project called X" | Runs project-new, sets up manifest |
| "Show my projects" | Scans for projects, shows versions and status |
| "Update all my projects" | Iterates through projects, applies updates |
| "Update my-awesome-app" | Updates specific project |
| "Launch into client-project" | Opens new terminal, runs myclaude in that project |
| "Check for issues" | Scans projects for common problems |

#### Project Registry

The hub maintains a registry of known projects in `.agency/projects.json`:

```json
{
  "projects": [
    {
      "name": "my-awesome-app",
      "path": "/Users/me/code/my-awesome-app",
      "created_at": "2026-01-15T10:00:00Z",
      "starter_version": "1.0.9",
      "last_seen": "2026-01-20T14:30:00Z"
    },
    {
      "name": "client-project",
      "path": "/Users/me/code/client-project",
      "created_at": "2026-01-10T08:00:00Z",
      "starter_version": "1.0.8",
      "last_seen": "2026-01-18T09:00:00Z"
    }
  ]
}
```

Projects are automatically registered when created via `project-new`. The hub can also scan for unregistered projects.

#### Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     THE AGENCY HUB                          │
│                  (the-agency-starter)                       │
│                                                             │
│   ./agency → Hub Agent                                      │
│     • Update starter                                        │
│     • Create projects                                       │
│     • Manage project registry                               │
│     • Batch updates                                         │
│                                                             │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│   ┌──────────────┐  ┌──────────────┐  ┌──────────────┐     │
│   │ my-awesome-  │  │ client-      │  │ side-        │     │
│   │ app          │  │ project      │  │ hustle       │     │
│   │              │  │              │  │              │     │
│   │ ./myclaude   │  │ ./myclaude   │  │ ./myclaude   │     │
│   │ → Captain    │  │ → Captain    │  │ → Captain    │     │
│   │ → Other      │  │ → Other      │  │ → Other      │     │
│   │   agents     │  │   agents     │  │   agents     │     │
│   └──────────────┘  └──────────────┘  └──────────────┘     │
│                                                             │
│                      PROJECTS                               │
│              (created from starter)                         │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

#### Example Interactions

**User:** "Update everything"

**Hub Agent:**
```
I'll update the starter and all your projects.

Updating starter...
  Fetching from GitHub...
  Current: v1.0.9 → Latest: v1.1.0
  ✓ Starter updated to v1.1.0

Updating projects...
  my-awesome-app (v1.0.9 → v1.1.0)
    ✓ Core updated
    ✓ agency-service updated
    ✓ Dependencies installed

  client-project (v1.0.8 → v1.1.0)
    ✓ Core updated
    ⚠️ tools/collaborate was modified - backed up
    ✓ agency-service updated
    ✓ Dependencies installed

  side-hustle (v1.0.9 → v1.1.0)
    ✓ Core updated
    ✓ Already up to date on services

All done! 3 projects updated.

Note: client-project had a modified file that was backed up.
You may want to review: ~/code/client-project/.agency/backups/
```

**User:** "Create a project for my new client Acme Corp"

**Hub Agent:**
```
I'll create a new project for Acme Corp.

Project name: acme-corp
Location: ~/code/acme-corp (default) or specify another?
```

**User:** "~/clients/acme-corp"

**Hub Agent:**
```
Creating project...
  ✓ Files copied
  ✓ Git initialized
  ✓ Manifest created (v1.1.0)
  ✓ Services installed
  ✓ Registered in hub

Project created at ~/clients/acme-corp

Would you like me to launch into it now?
```

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
- [ ] Create manifest schema (`.agency/manifest.json`)
- [ ] Create registry schema (`registry.json` in starter)
- [ ] Create project registry (`.agency/projects.json` in starter)
- [ ] Update `project-new` to generate manifest and register project
- [ ] Add `--init` to generate manifest for existing projects
- [ ] Add service check to `myclaude`

### Phase 2: The Hub
- [ ] Create `./agency` command in the-agency-starter
- [ ] Create Hub Agent (`claude/agents/hub/`)
- [ ] Hub Agent: starter update capability (git pull, conflict handling)
- [ ] Hub Agent: project listing and status
- [ ] Hub Agent: project creation via `project-new`
- [ ] Hub Agent: launch into project (open terminal + myclaude)

### Phase 3: Agent-Friendly Updates
- [ ] Add `--check --json` for agent consumption
- [ ] Add `--apply --component=X` for targeted updates
- [ ] Add install/post-install hook execution
- [ ] Hub Agent: batch update all projects
- [ ] Manifest auto-update on changes

### Phase 4: Starter Packs Integration
- [ ] Track applied packs in manifest
- [ ] Add `--pack` command for applying packs
- [ ] Hub Agent: recommend packs based on project type
- [ ] Dependency resolution for packs

### Phase 5: Full Automation
- [ ] Captain checks for updates on session start
- [ ] Captain applies minor/patch updates automatically
- [ ] Captain reports major updates to principal
- [ ] Hub Agent: scheduled health checks across projects
- [ ] Hub Agent: cross-project insights ("3 projects have outdated deps")

---

## Success Criteria

- [ ] After initial install, everything is agent-driven (no manual CLI commands)
- [ ] `./agency` launches Hub Agent in the-agency-starter
- [ ] Hub Agent can update starter, create projects, update projects
- [ ] Project registry tracks all projects created from starter
- [ ] Manifest accurately tracks installed components per project
- [ ] `myclaude` starts required services automatically
- [ ] Agents can check for updates via `--check --json`
- [ ] Agents can apply updates without user intervention
- [ ] Install hooks run automatically (pnpm install, etc.)
- [ ] Principal only involved for major decisions

---

## Principles Embodied

1. **Agent Autonomy** - Agents do the work, principals make decisions
2. **Hub Architecture** - Starter is the control center for all projects
3. **CLI/API First** - No GUI configuration required
4. **Self-Aware System** - Manifest provides system introspection
5. **Progressive Enhancement** - Works without manifest, better with it
6. **One Install, All Agent** - Only the initial curl command is non-agent

---

## User Flow: The Happy Path

### Step 1: User Installs The Agency Starter

```bash
curl -fsSL https://the-agency.ai/install | bash
```

Or manually:
```bash
git clone https://github.com/the-agency-ai/the-agency-starter.git
cd the-agency-starter
./install
```

**What the installer does:**
1. Clones the repo (if using curl)
2. Checks prerequisites (Node.js, pnpm, Claude Code)
3. Sets up the starter environment
4. Configures shell aliases (optional)

**What exists after install:**
- `registry.json` - defines available components
- `VERSION` - current starter version (e.g., "1.0.9")
- `./update` - script to update the starter itself
- All framework files, tools, services

### Step 2: User Creates Their Project

```bash
./tools/project-new my-awesome-app
```

**What happens:**
1. Files copied to `~/my-awesome-app/`
2. Git initialized with initial commit
3. **`.agency/manifest.json` created** with:
   - `starter_version: "1.0.9"`
   - Components marked as installed
   - File hashes recorded for modification detection
4. Services installed (`pnpm install` in agency-service)
5. `myclaude` launches, Captain greets them

**Manifest created:**
```json
{
  "schema_version": "1.0",
  "project": {
    "name": "my-awesome-app",
    "created_at": "2026-01-15T10:00:00Z",
    "starter_version": "1.0.9"
  },
  "source": {
    "path": "/Users/me/the-agency-starter"
  },
  "components": {
    "core": { "version": "1.0.9", "status": "installed" },
    "agency-service": { "version": "1.0.0", "status": "installed", "dependencies": "installed" }
  },
  "files": {
    "tools/collaborate": { "hash": "abc123...", "version": "1.0.9" }
  }
}
```

### Step 3: User Works on Their Project

Over weeks/months, they:
- Add their own principal in `claude/principals/jordan/`
- Create custom agents in `claude/agents/my-agent/`
- Add local tools in `tools/local/`
- Maybe modify `tools/collaborate` for their workflow
- Apply starter packs: `react-app`, `supabase-auth`
- Build features, ship code, love The Agency

**Manifest evolves:**
```json
{
  "starter_packs": {
    "react-app": { "status": "applied", "applied_at": "2026-01-20T..." },
    "supabase-auth": { "status": "applied", "applied_at": "2026-01-25T..." }
  }
}
```

### Step 4: The Agency Releases v1.1.0

New features:
- 10 new tools
- Updated Captain knowledge
- agency-service v1.0.1 with new endpoints
- New starter pack: `stripe-payments`
- Breaking change: `tools/foo` renamed to `tools/bar`

### Step 5: User Updates via The Hub

```bash
cd ~/the-agency-starter
./agency
```

**User:** "Check for updates"

**Hub Agent:**
```
Checking for updates...

Starter: v1.0.9 → v1.1.0 available

What's new in v1.1.0:
  • 10 new tools for workflow automation
  • Updated Captain knowledge
  • agency-service v1.0.1 (bug fixes)
  • New starter pack: stripe-payments

⚠️ Breaking changes:
  • tools/foo renamed to tools/bar

Your projects:
  • my-awesome-app (v1.0.9) - can be updated
  • client-project (v1.0.8) - can be updated

Would you like me to update the starter and your projects?
```

**User:** "Yes, update everything"

**Hub Agent:**
```
Updating starter...
  Fetching from GitHub...
  ✓ Starter updated to v1.1.0

Updating projects...

  my-awesome-app (v1.0.9 → v1.1.0)
    ✓ Core updated
    ✓ agency-service updated
    ✓ Dependencies installed

  client-project (v1.0.8 → v1.1.0)
    ✓ Core updated
    ⚠️ tools/collaborate was modified - backed up
    ✓ agency-service updated
    ✓ Dependencies installed

All done! Starter and 2 projects updated to v1.1.0.

Note: client-project had a modified file backed up to:
  ~/code/client-project/.agency/backups/

Would you like me to launch into one of your projects?
```

### Step 6: User Launches Into Their Project

**User:** "Launch into my-awesome-app"

**Hub Agent:**
```
Launching my-awesome-app...
Opening new terminal at ~/code/my-awesome-app
Starting Captain...
```

*(New terminal opens, myclaude launches)*

**Alternative: User goes directly to project**

```bash
cd ~/code/my-awesome-app
./tools/myclaude housekeeping captain
```

Either way, Captain is ready with all the new features and updated knowledge.

### Step 7: The Magic - What Actually Happens

```
┌─────────────────────────────────────────────────────────────┐
│                    UPDATE PROCESS                           │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  1. PRE-FLIGHT CHECKS                                       │
│     ├── Check git status (warn if uncommitted changes)      │
│     ├── Stop running services                               │
│     ├── Create backup of modified files                     │
│     └── Verify source starter is newer than project         │
│                                                             │
│  2. CORE UPDATE                                             │
│     ├── Copy new/updated tools (skip tools/local/)          │
│     ├── Copy new/updated docs (skip claude/principals/)     │
│     ├── Merge CLAUDE.md (preserve PROJECT sections)         │
│     ├── Update .claude/settings.json                        │
│     └── Update agent knowledge (preserve WORKLOGs)          │
│                                                             │
│  3. SERVICE UPDATES                                         │
│     ├── Copy new service files                              │
│     ├── Run pnpm install                                    │
│     ├── Run migrations if needed                            │
│     └── Restart services                                    │
│                                                             │
│  4. POST-UPDATE                                             │
│     ├── Update manifest with new versions                   │
│     ├── Record backup locations                             │
│     ├── Log what changed for agent awareness                │
│     └── Verify services healthy                             │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### Step 8: User Launches myclaude

```bash
./tools/myclaude housekeeping captain
```

**What happens:**
1. myclaude checks manifest for auto_start services
2. Starts agency-service if not running
3. Launches Claude Code
4. Captain has updated KNOWLEDGE.md with new tool info
5. User has all new features, agents know how to use them

**Yeah!** 🎉

---

## Edge Cases & How We Handle Them

### EC-1: User Modified a Framework Tool

**Scenario:** User customized `tools/collaborate` for their workflow.

**Detection:** Hash in manifest doesn't match current file hash.

**Handling:**
1. Backup modified file to `.agency/backups/tools/collaborate.1.0.9.backup`
2. Copy new version from starter
3. Log in manifest: `"tools/collaborate": { "backup": "...", "user_modified": true }`
4. Agent informs user: "Your changes to collaborate were backed up. Review and re-apply if needed."

### EC-2: Breaking Changes in Tools

**Scenario:** `tools/foo` renamed to `tools/bar`, or CLI args changed.

**Detection:** Registry includes `breaking_changes` section for the version.

**Handling:**
1. Registry defines migration: `{ "rename": { "tools/foo": "tools/bar" } }`
2. Update tool performs rename
3. Search codebase for references to old name
4. Agent updates any scripts/docs that reference old name
5. Update agent knowledge to use new name

### EC-3: New Service Requires Dependencies

**Scenario:** agency-service v1.0.1 needs new npm packages.

**Handling:**
1. Registry defines: `"install": { "command": "pnpm install" }`
2. Update tool runs install command automatically
3. Manifest updated: `"dependencies": "installed"`

### EC-4: Service Requires Database Migration

**Scenario:** New version adds tables/columns.

**Handling:**
1. Registry defines: `"migrate": { "command": "./tools/service migrate" }`
2. Update tool runs migration
3. If migration fails, rollback and report error

### EC-5: User Skipped a Service Initially

**Scenario:** User didn't install agency-service, now wants it.

**Handling:**
```bash
./tools/project-update --install agency-service
```
1. Copy service files from starter
2. Run install command
3. Run post-install (start service)
4. Update manifest

### EC-6: User Created Custom Agents

**Scenario:** User has `claude/agents/my-custom-agent/`.

**Handling:**
- Protected path - NEVER touched
- Only framework agents (`captain`, `templates/`) are updated
- User agents preserved completely

### EC-7: User Modified CLAUDE.md

**Scenario:** User added project-specific sections.

**Handling:**
1. CLAUDE.md uses markers:
   ```markdown
   <!-- AGENCY:START -->
   [Framework content - auto-updated]
   <!-- AGENCY:END -->

   <!-- PROJECT:START -->
   [User content - preserved]
   <!-- PROJECT:END -->
   ```
2. Update replaces AGENCY section, preserves PROJECT section

### EC-8: Starter is Older Than Project

**Scenario:** User forgot to `git pull` the starter.

**Detection:** Compare versions in registry vs manifest.

**Handling:**
```
Warning: Your starter (v1.0.8) is older than your project (v1.0.9).
Run: cd /path/to/starter && git pull
Then retry the update.
```

### EC-9: Network Unavailable (GitHub source)

**Scenario:** Can't fetch from GitHub.

**Handling:**
1. If local starter path exists, use that
2. If not, fail gracefully with clear message
3. Suggest: `--from=/path/to/local/starter`

### EC-10: Uncommitted Changes in Project

**Scenario:** User has unstaged/uncommitted changes.

**Handling:**
```
Warning: You have uncommitted changes.

  M src/app/page.tsx
  ? src/components/new-file.tsx

Options:
  1. Commit changes first: git add . && git commit -m "WIP"
  2. Stash changes: git stash
  3. Force update anyway: --force

Recommended: Commit your changes first.
```

### EC-11: Services Running During Update

**Scenario:** agency-service is running when update starts.

**Handling:**
1. Detect running services
2. Stop them gracefully
3. Perform update
4. Restart services
5. Verify healthy

### EC-12: Starter Pack Updates

**Scenario:** User applied `react-app` pack, new version has updates.

**Handling:**
1. Manifest tracks: `"react-app": { "status": "applied", "version": "1.0.0" }`
2. Update detects pack version changed
3. Offers to re-apply pack updates (non-destructive)
4. User can skip pack updates if desired

### EC-13: Update Fails Midway

**Scenario:** Network drops during file copy.

**Handling:**
1. All updates staged to temp directory first
2. Only after successful staging, files are moved
3. If move fails, restore from backup
4. Manifest not updated until success
5. Clear error message with recovery steps

### EC-14: Manifest Schema Changes

**Scenario:** New version uses manifest v2 schema.

**Handling:**
1. Schema version in manifest: `"schema_version": "1.0"`
2. Update tool detects old schema
3. Migrates manifest to new schema
4. Preserves all user data

### EC-15: New Required Component

**Scenario:** v1.1.0 makes agency-service required (was optional).

**Handling:**
1. Registry marks component as `"required": true`
2. Update detects missing required component
3. Prompts user: "agency-service is now required. Install? [Y/n]"
4. Installs if confirmed

### EC-16: Conflicting Starter Packs

**Scenario:** User wants `vercel` but already has `cloudflare-deploy`.

**Handling:**
1. Registry defines conflicts: `"vercel": { "conflicts": ["cloudflare-deploy"] }`
2. Tool detects conflict
3. Prompts: "vercel conflicts with cloudflare-deploy. Remove cloudflare-deploy first?"

### EC-17: Starter Update Fails

**Scenario:** User runs `./update` but git pull fails (merge conflict, no network).

**Handling:**
```
┌─────────────────────────────────────────────────────────────┐
│  The Agency Starter - Update                                │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ❌ Update failed: merge conflict                           │
│                                                             │
│  You have local changes that conflict with upstream.        │
│                                                             │
│  Options:                                                   │
│    1. Reset to upstream (discard local changes):            │
│       ./update --reset                                      │
│                                                             │
│    2. Keep local changes and skip update:                   │
│       (no action needed)                                    │
│                                                             │
│    3. Manually resolve:                                     │
│       git status                                            │
│       git merge --abort  (or resolve conflicts)             │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### EC-18: User Has No Starter Locally

**Scenario:** User deleted their starter, or cloned project from elsewhere.

**Handling:**
1. `project-update` checks manifest for source
2. If source was GitHub, offer to clone fresh:
   ```
   No local starter found at /Users/me/the-agency-starter

   Options:
     1. Clone fresh: ./tools/project-update --clone-starter
     2. Specify path: ./tools/project-update --from=/other/path
     3. Use GitHub directly: ./tools/project-update --github
   ```

---

## Protected Paths (NEVER Modified)

| Path | Reason |
|------|--------|
| `tools/local/*` | User's custom tools |
| `claude/principals/*` | User's principals, requests, instructions |
| `claude/agents/*/WORKLOG.md` | Agent work history |
| `claude/agents/*/ADHOC-WORKLOG.md` | Adhoc work history |
| `claude/workstreams/*/sprints/*` | Sprint work |
| `claude/agents/<user-created>/*` | User's custom agents |
| `.agency/*` | Local metadata (except manifest updates) |
| `.git/*` | Git repository |
| `node_modules/*` | Dependencies (managed by pnpm) |

---

## Work Log

### 2026-01-15

- Created REQUEST
- Designed manifest and registry schemas
- Outlined agent-driven update flow
- Defined implementation phases
- Added comprehensive user flow documentation
- Documented 16 edge cases with handling strategies
- **Added Hub concept** - starter as control center for all projects
- **Added `./agency` command** - launches Hub Agent
- **Added project registry** - tracks all projects created from starter
- **Updated user flow** - everything after install is agent-driven
- Added 2 more edge cases (EC-17, EC-18)
- Updated implementation phases (now 5 phases including Hub)
- Added "One Install, All Agent" principle
