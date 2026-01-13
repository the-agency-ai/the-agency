# REQUEST-jordan-0030: Starter Onboarding Fixes

**Principal:** jordan
**Workstream:** housekeeping
**Agent:** housekeeping
**Created:** 2026-01-10
**Status:** open

## Summary

Fix critical onboarding issues discovered during the-agency-starter v1.0.2/v1.0.3 rollout. Users experienced friction that required manual intervention (including nuking Claude Code installs) which is unacceptable.

## Issues

### 1. Claude Code Already Installed Conflict

**Problem:** When users already have Claude Code installed, the installer correctly skips installation, but the `/welcome` command doesn't work. We had to go through an involved process of nuking their Claude Code install - this is NOT an option going forward.

**Root Cause:** TBD - need to investigate why `/welcome` doesn't register when Claude Code pre-exists.

**Proposed Fix:**
- Investigate the slash command registration mechanism
- Ensure `.claude/commands/` is recognized regardless of install method
- Add verification step after install to confirm commands are available
- Provide fallback instructions if commands aren't working

### 2. Principal Hardcoded as "jordan"

**Problem:** Many places have "jordan" hardcoded as the principal. During onboarding, we don't ask who the principal is, so new users end up with references to "jordan" throughout their install.

**Affected Areas:**
- `claude/principals/jordan/` directory structure
- Request files referencing `jordan`
- Configuration files
- Potentially tool defaults

**Proposed Fix:**
- Create `./tools/setup-agency` script that runs OUTSIDE of Claude Code
- This script handles all pre-Claude setup including principal
- `myclaude` checks if setup is complete before launching

### 3. Environment Variable for Principal Name

**Problem:** We need a consistent way to reference the current principal across tools and scripts.

**Proposed Fix:**

**A. Setup Script (runs outside Claude Code):**
```bash
./tools/setup-agency
```
This script:
- Prompts for principal name (interactive, works in normal terminal)
- Sets `AGENCY_PRINCIPAL` in shell profile (`.bashrc`, `.zshrc`)
- Renames `claude/principals/jordan/` to `claude/principals/{name}/`
- Updates all references in config files
- Creates `.agency-config` file with settings
- Can be re-run to change settings

**B. myclaude Check:**
```bash
# In myclaude, before launching Claude:
if [ -z "$AGENCY_PRINCIPAL" ]; then
    echo "AGENCY_PRINCIPAL not set. Run ./tools/setup-agency first."
    exit 1
fi
```

**C. All tools use:**
```bash
PRINCIPAL="${AGENCY_PRINCIPAL:?AGENCY_PRINCIPAL not set. Run ./tools/setup-agency}"
```

**Key Insight:** Interactive prompts (like asking for principal name) must happen OUTSIDE Claude Code, in a normal terminal where stdin works.

### 4. AgencyBench Desktop Not Included + No Build Process

**Problem:** The pre-built desktop version of AgencyBench was not included in the starter. Users only get the source. The existing DMG is stale (1.0.0) and there's no documented build process that's actually followed.

**Current State:**
- `package.json` says version 0.7.0
- `tauri.conf.json` says version 1.0.0
- DMG in target/ is old and not distributed
- No release pipeline for AgencyBench

**Proposed Fix:**
1. Sync versions across package.json and tauri.conf.json
2. Document build process in `apps/agency-bench/BUILD.md`
3. Add `./tools/build-agency-bench` that:
   - Syncs versions
   - Runs `npm run tauri:build`
   - Outputs DMG/exe to known location
4. Add `./tools/release-agency-bench` that:
   - Builds fresh
   - Uploads to GitHub release
   - Updates download links
5. **Include AgencyBench build in `./tools/starter-release` checklist**
6. Upload DMG to GitHub releases for each starter version

**Build Process (to follow!):**
```bash
# 1. Bump version
npm pkg set version=X.Y.Z -w apps/agency-bench

# 2. Sync tauri version
# Edit apps/agency-bench/src-tauri/tauri.conf.json

# 3. Build
cd apps/agency-bench && npm run tauri:build

# 4. Verify DMG exists
ls src-tauri/target/release/bundle/dmg/

# 5. Upload to release
gh release upload vX.Y.Z ./src-tauri/target/release/bundle/dmg/*.dmg
```

### 5. Services Not Auto-Starting with myclaude

**Problem:** When Claude was launched via `./tools/myclaude`, services didn't start automatically. Users had to manually start them later, breaking the seamless experience.

**Affected Services:**
- Secret Service (vault, secrets management)
- Log Service (centralized logging)
- Messages Service (inter-agent messaging)
- Bug Service (bug tracking)
- Test Service (test history)

**Proposed Fix:**
- Update `./tools/myclaude` to auto-start `agency-service` if not running
- `agency-service` manages ALL embedded services as one process
- Add health check before launching Claude
- Provide clear error message if service fails to start
- Show service status in myclaude startup output

**Startup Sequence (services is FIRST step):**
```bash
# In myclaude - ORDER MATTERS:
1. CHECK/START SERVICES FIRST (before anything else)
   - Check if agency-service is running (curl health endpoint)
   - If not running, start it: ./tools/agency-service start
   - Wait for health check to pass (with timeout)
   - If fails, show error and offer to continue without services
2. Check dependencies (./tools/check-dependencies)
3. Check first-run / setup-agency
4. Check principal exists
5. Launch Claude
```

**Agent Responsibility:**
When an agent launches (via myclaude or any other method), the agent itself should:
1. Check if required services are running
2. If not, launch them automatically
3. Not require user intervention

This could be done via:
- A startup hook in agent.md
- A check built into myclaude that runs before Claude starts
- A `.claude/hooks/pre-session` script
- Instructions in agent.md that Claude follows on startup

**Key Principle:** The agent is responsible for its environment. If it needs services, it ensures they're running.

### 6. Installer Doesn't Install ANY Dependencies

**Problem:** The installer doesn't install ANY of our dependencies. It only clones the repo. Users have to manually discover and install each dependency, which completely breaks the onboarding experience.

**What Should Be Installed:**
- `git` - version control (check, prompt to install)
- `claude` - Claude Code CLI
- `bun` - JavaScript runtime for agency-service
- `jq` - JSON processing (used by many tools)
- Any other deps in our dependency list (see #9)

**Current Behavior:**
```
install.sh → clones repo → done (broken)
```

**Expected Behavior:**
```
install.sh:
1. Check/install BOOTSTRAP deps (git, curl) - minimum to clone
2. Clone repo
3. Run ./tools/install-dependencies - installs ALL required deps
4. Verify all working
5. Done
```

**Goal: Ready to build and develop after install.**

**ALL REQUIRED - NO OPTIONAL:**
| Dependency | Purpose |
|------------|---------|
| git | Version control |
| claude | Claude Code CLI |
| bun | agency-service runtime |
| jq | JSON processing |
| curl | Fetching resources |
| gh | GitHub CLI |
| tree | Directory visualization |
| node/npm | AgencyBench build |
| rsync | File syncing |
| yq | YAML processing |
| fzf | Fuzzy finder |
| bat | Better cat |
| ripgrep | Fast grep |
| Rust/Cargo | Tauri builds |

**They are ALL required. No optional. Install ALL of them.**

After install completes, user should be able to:
- Run `./tools/myclaude` immediately
- Build AgencyBench
- Use all tools without "command not found" errors

**Two Checkpoints:**
1. **Installer** - installs ALL required deps (ready to develop)
2. **myclaude** - verifies deps on every launch (catches drift)

**Proposed Fix:**
- Installer reads from `claude/config/dependencies.yaml` (see #9)
- For each dependency:
  - Check if installed
  - If missing, install it (platform-specific)
  - Verify installation succeeded
- Only proceed with clone after all deps are ready
- Final verification step confirms everything works

### 7. Terminal Indicators Not Working

**Problem:** Users are not getting terminal indicators - neither the colors nor the indicator icons are displaying. This makes the CLI experience feel broken and harder to parse.

**Proposed Fix:**
- Verify ANSI color codes are being output correctly
- Check if `TERM` environment variable is set properly
- Ensure indicator icons (unicode) have fallbacks for terminals that don't support them
- Add terminal capability detection
- Consider: `FORCE_COLOR=1` or `NO_COLOR` support

### 8. Vault Passphrase Input Broken

**Problem:** Users were prompted for a vault passphrase during secret service setup, but there was no way to actually input it. The prompt appeared but input was blocked or not captured.

**Root Cause:** TBD - likely related to how Claude Code handles stdin for interactive prompts.

**Proposed Fix:**
- Investigate stdin handling in Claude Code context
- Consider alternative input methods:
  - `--passphrase` flag for non-interactive use
  - Read from file: `--passphrase-file ~/.agency-vault-pass`
  - Environment variable: `AGENCY_VAULT_PASSPHRASE`
- Add clear error message when interactive input isn't available
- Fallback to `read -s` with explicit TTY handling

### 9. No Centralized Dependency Management (Root Cause of #6)

**Problem:** We don't have a single maintained list of dependencies. Dependencies are scattered across install.sh, various tools, and documentation. We already have SOME dependency installation code (like `brew install tree`) but it's scattered and inconsistent.

**TWO TYPES OF DEPENDENCIES:**

| Type | What | When Checked | When Installed |
|------|------|--------------|----------------|
| **Agency Dependencies** | Dependencies for The Agency framework | Install, Update | Install, Update |
| **Project Dependencies** | Dependencies for the specific project | Every myclaude launch | As needed |

---

**AGENCY DEPENDENCIES** (`claude/config/agency-dependencies.yaml`)

These are required to run The Agency itself. Checked at:
- Initial install
- Agency update (`./tools/update-agency`)

Must check **dependency AND version**.

| Dependency | Min Version | Purpose | Install |
|------------|-------------|---------|---------|
| `git` | 2.0 | Version control | xcode-select / apt |
| `claude` | latest | Claude Code CLI | claude.ai/install.sh |
| `bun` | 1.0 | agency-service runtime | bun.sh/install |
| `jq` | 1.6 | JSON processing | brew/apt install jq |
| `curl` | any | Fetching resources | Usually pre-installed |
| `gh` | 2.0 | GitHub CLI (PRs, releases) | brew/apt install gh |
| `tree` | any | Directory visualization | brew/apt install tree |
| `node` | 18.0 | AgencyBench build | brew/apt or nvm |
| `npm` | 9.0 | Package management | comes with node |
| `rsync` | any | File syncing (releases) | Usually pre-installed |
| `yq` | 4.0 | YAML processing | brew/apt install yq |
| `fzf` | any | Fuzzy finder | brew/apt install fzf |
| `bat` | any | Better cat | brew/apt install bat |
| `ripgrep` | any | Fast grep | brew/apt install ripgrep |
| `Rust/Cargo` | 1.70 | Tauri (AgencyBench) | rustup.rs |

**ALL 15 Agency dependencies are REQUIRED.**

---

**PROJECT DEPENDENCIES** (`project-dependencies.yaml` in project root)

These are specific to what the project is building. Checked at:
- Every myclaude launch

Examples:
- React project: node_modules up to date?
- Python project: venv activated? requirements installed?
- Go project: go mod tidy?

```yaml
# project-dependencies.yaml (example)
type: node  # or python, go, rust, etc.
check:
  - "npm ci"  # or "pip install -r requirements.txt"
```

---

**Already have setup scripts:**
- `./tools/mac-setup` - macOS setup (uses brew)
- `./tools/linux-setup` - Linux setup (apt/dnf/pacman)

**What's Missing:**
- These aren't called by installer
- No verification after install
- No unified check-dependencies tool
- No version checking

**Proposed Fix:**
1. Create `claude/config/agency-dependencies.yaml` - Agency deps with versions
2. Create `project-dependencies.yaml` template - Project deps
3. Each dependency entry includes:
   - Name
   - Required (true/false)
   - Min version
   - Check command
   - Install command (per platform)
   - What breaks without it
3. Create `./tools/install-dependencies` that reads this file and installs ALL
4. Create `./tools/check-dependencies` to verify all present
5. `install.sh` calls `./tools/install-dependencies`
6. `myclaude` calls `./tools/check-dependencies` on startup
7. When adding new deps to tools, ADD TO THE YAML FILE

**Example Format:**
```yaml
dependencies:
  - name: git
    required: true
    min_version: "2.0"
    check: "git --version"
    install:
      darwin: "xcode-select --install"
      linux: "apt-get install git"
    breaks: "version control, all git operations"

  - name: bun
    required: true
    min_version: "1.0"
    check: "bun --version"
    install:
      all: "curl -fsSL https://bun.sh/install | bash"
    breaks: "agency-service, secret service, log service"

  - name: tree
    required: false
    check: "command -v tree"
    install:
      darwin: "brew install tree"
      linux: "apt-get install tree"
    breaks: "directory visualization in some tools"
```

**Deliverables:**
- [ ] `claude/config/agency-dependencies.yaml` - Agency deps with versions
- [ ] `project-dependencies.yaml` template - Project deps
- [ ] `./tools/install-agency-deps` - installs Agency deps (with version check)
- [ ] `./tools/check-agency-deps` - verifies Agency deps + versions
- [ ] `./tools/check-project-deps` - verifies Project deps
- [ ] Update `install.sh` to call install-agency-deps
- [ ] Update `./tools/update-agency` to call check-agency-deps
- [ ] Update `myclaude` to call check-project-deps on startup
- [ ] Integrate with `setup-mac` and `setup-linux`
- [ ] Document in CLAUDE.md

**Checkpoint Summary:**
| When | What | Which Deps | Version Check? |
|------|------|------------|----------------|
| install.sh | Install | Agency | YES |
| update-agency | Update | Agency | YES |
| myclaude | Every launch | Project | NO (just present) |

### 10. Starter Contains Project-Specific Content + Multi-Principal Support

**Problem:** The starter is shipping with project-specific content that shouldn't be there:
- `claude/principals/jordan/` - personal principal directory
- Project-specific REQUESTs and artifacts
- Personal preferences and documents
- ANY "jordan" references (unless jordan is actually a principal)

New users get a copy of jordan's stuff instead of a clean slate.

**Three Distinct Use Cases:**

**A. the-agency-starter itself (the template repo)**
- MUST be a blank slate
- NO principals directory content
- NO project-specific documents from the-agency project:
  - No REQUEST files (REQUEST-jordan-*, etc.)
  - No WORKLOG entries
  - No ADHOC-WORKLOG entries
  - No artifacts (ART-*)
  - No agent KNOWLEDGE.md content (should be template)
  - No collaboration messages
  - No sprint content
  - No news posts
- NO hardcoded names anywhere
- Templates only, no actual work product

**Marker file to identify starter:**
- `.agency-starter` file exists ONLY in the-agency-starter repo
- When `./tools/project-new` creates a project, it REMOVES this file
- myclaude checks: if `.agency-starter` exists → "This is the starter template. Run ./tools/project-new to create a project."
- Prevents accidentally running setup-agency on the starter itself

**B. New project created from starter (fresh project)**
- Starts as blank slate
- First run of myclaude triggers setup-agency
- setup-agency creates first principal from template
- Clean starting point for new Agency

**C. Joining an existing Agency project (new principal added)**
- Project already has principals, agents, history
- New person clones the repo
- They run `./tools/add-principal` (or myclaude detects no local principal)
- Creates THEIR principal directory without affecting others
- Does NOT overwrite existing structure

**What Starter Should Have:**
- `claude/principals/.gitkeep` (empty directory)
- `claude/templates/principal/` with template structure
- NO actual principal directories
- NO project-specific documents
- ZERO hardcoded names

**Tools Needed:**
- `./tools/setup-agency` - first-time project setup (creates first principal)
- `./tools/add-principal` - add yourself to existing project
- `./tools/add-principal --name someone` - add another principal

**Proposed Fix:**
1. Create `claude/templates/principal/` with:
   - `preferences.md` (template)
   - `requests/.gitkeep`
   - `artifacts/.gitkeep`
   - `resources/.gitkeep`
2. Remove ALL `claude/principals/*` content from starter
3. Audit entire codebase for "jordan" references - remove all
4. Update `release-starter` to exclude project-specific content
5. setup-agency handles use case B (new project)
6. add-principal handles use case C (joining existing)
7. myclaude detects which case and routes appropriately

### 11. setup-agency Should Be First-Run in myclaude

**Problem:** Requiring users to know about and run `./tools/setup-agency` separately is friction. They'll forget or not know about it.

**COMPLETE FLOW - Install to First Launch:**

```
INSTALL (install.sh):
1. Check/install bootstrap deps (git, curl)
2. Clone repo
3. ./tools/install-dependencies → ALL 14 deps installed
4. Verify all working
5. Print: "Run ./tools/myclaude housekeeping housekeeping to start"

FIRST LAUNCH (myclaude):
0. Check if this is an Agency project?
   └─→ Look for .agency-project marker OR claude/config/agency.yaml
   └─→ NO: "Not an Agency project. Run this from an Agency project root
           created with ./tools/project-new" → EXIT

1. Check if .agency-starter exists?
   └─→ YES: "This is the starter template. Run ./tools/project-new first." → EXIT

2. Start services (FIRST!)

3. ./tools/check-project-deps (verify project dependencies)

4. Check .agency-setup-complete exists?
   └─→ NO: New project, run ./tools/setup-agency:
       a. "What is your name?" → AGENCY_PRINCIPAL
       b. Create claude/principals/{name}/ from template
       c. Set AGENCY_PRINCIPAL in shell profile
       d. "Set vault passphrase:" → init vault
       e. Create .agency-setup-complete
       → Continue to step 6

5. Check AGENCY_PRINCIPAL env var is set?
   └─→ NO: User is not yet a principal. Run ./tools/add-principal:
       a. "What is your name?" → name
       b. Set AGENCY_PRINCIPAL={name} in shell profile (.bashrc/.zshrc)
       c. Export AGENCY_PRINCIPAL={name} for current session
       d. Create claude/principals/{name}/ from template
       e. (vault already initialized by project owner)
       → Continue to step 6

6. Check claude/principals/$AGENCY_PRINCIPAL/ exists?
   └─→ NO: Directory missing, run ./tools/add-principal to create it
       → Continue to step 7

7. Launch Claude
8. /welcome runs (if first time for this principal)
```

**AGENCY_PRINCIPAL is an ENV variable:**
- Set in user's shell profile by setup-agency or add-principal
- If not set → user is not yet a principal → run add-principal
- Persists across sessions (in .bashrc/.zshrc)

**Decision Tree:**
```
Is this an Agency project? (.agency-project OR claude/config/agency.yaml)
├─ NO → BLOCK: "Not an Agency project"
└─ YES
    │
    .agency-starter exists?
    ├─ YES → BLOCK: "Use ./tools/project-new"
    └─ NO
        │
        .agency-setup-complete exists?
        ├─ NO → setup-agency (new project, creates first principal)
        └─ YES
            │
            AGENCY_PRINCIPAL env var set?
            ├─ NO → add-principal (sets env var + creates directory)
            └─ YES
                │
                principals/$AGENCY_PRINCIPAL/ exists?
                ├─ NO → add-principal (creates directory)
                └─ YES → Launch Claude
```

**Key Points:**
- setup-agency runs BEFORE Claude launches (stdin works!)
- Principal is created during setup-agency
- AGENCY_PRINCIPAL is set before Claude starts
- Vault passphrase captured during setup (not in Claude)

**User Experience:**
```
$ ./tools/myclaude housekeeping housekeeping

Starting services... ✓
Checking dependencies... ✓
First run detected. Running setup...

What is your name? alice
Creating principal directory... ✓
Set vault passphrase: ********
Confirm passphrase: ********
Vault initialized ✓

Setup complete! Launching Claude...
```

### 12. No Update Mechanism

**Problem:** There's no way to:
- Update a local the-agency-starter from the GitHub repo
- Update projects created from the-agency-starter
- Get new tools, fixes, templates without manual copying

Users are stuck on whatever version they installed.

**Update Scenarios:**

**A. Update the-agency-starter itself (local copy)**
```bash
cd the-agency-starter
./tools/update-starter
# Pulls latest from GitHub, preserves local changes
```

**B. Update a project from local the-agency-starter**
```bash
cd my-project
./tools/update-agency --from ~/the-agency-starter
# Syncs tools, templates, configs from local starter
```

**C. Update a project directly from GitHub**
```bash
cd my-project
./tools/update-agency --from github
# Pulls latest tools, templates, configs from GitHub
```

**What Gets Updated:**
- `tools/` - all CLI tools
- `claude/templates/` - templates for agents, principals, etc.
- `claude/config/` - default configurations
- `claude/docs/` - documentation
- `CLAUDE.md` - constitution (with merge strategy)

**What Does NOT Get Updated (preserved):**
- `claude/principals/` - user's principals
- `claude/agents/*/KNOWLEDGE.md` - agent knowledge
- `claude/agents/*/WORKLOG.md` - work history
- `claude/workstreams/` - workstream content
- `.agency-config` - local settings
- Any user modifications to tools (flagged for review)

**Tools Needed:**
- `./tools/update-starter` - updates the-agency-starter from GitHub
- `./tools/update-agency` - updates project from starter or GitHub
- Version tracking to know what needs updating

**Version Tracking:**
- `.agency-version` file in project root
- Compares against source version
- Shows changelog of what changed

## Additional Issues (TBD)

_Space reserved for additional issues as they're discovered._

---

## Acceptance Criteria

- [ ] Fresh install works on machine with existing Claude Code
- [ ] `/welcome` command works immediately after install
- [ ] `./tools/setup-agency` script exists and works
- [ ] Principal name collected via setup-agency (outside Claude)
- [ ] No hardcoded "jordan" references in fresh install
- [ ] `AGENCY_PRINCIPAL` set in shell profile by setup-agency
- [ ] `myclaude` checks for `AGENCY_PRINCIPAL` before launching
- [ ] AgencyBench DMG is built fresh for each release
- [ ] AgencyBench DMG is uploaded to GitHub release
- [ ] `./tools/build-agency-bench` exists and works
- [ ] AgencyBench build is part of `release-starter` process
- [ ] ALL services auto-start with myclaude (agency-service)
- [ ] Health check runs before Claude launches
- [ ] Service status shown in myclaude startup
- [ ] Agents check and launch required services on startup
- [ ] Bun is installed automatically by installer
- [ ] All dependencies installed without manual intervention
- [ ] Terminal colors and icons display correctly
- [ ] Vault passphrase can be entered (interactive or via flag/env)
- [ ] Single source of truth for dependencies exists
- [ ] `./tools/check-dependencies` validates all deps
- [ ] Installer installs ALL dependencies automatically
- [ ] Starter contains NO project-specific content (no jordan/)
- [ ] Starter contains ZERO hardcoded principal names
- [ ] Agency projects have `.agency-project` marker (or claude/config/agency.yaml)
- [ ] myclaude blocks if NOT an Agency project
- [ ] Starter has `.agency-starter` marker file
- [ ] myclaude blocks if `.agency-starter` exists (must use new-project)
- [ ] `./tools/project-new` removes `.agency-starter` marker
- [ ] `claude/templates/principal/` exists with template
- [ ] `./tools/add-principal` exists for joining existing projects
- [ ] setup-agency triggered on first myclaude run (new project)
- [ ] add-principal triggered when joining existing project
- [ ] myclaude detects new project vs joining existing
- [ ] `.agency-setup-complete` marker created after setup
- [ ] `./tools/update-starter` exists and works
- [ ] `./tools/update-agency` exists and works
- [ ] Version tracking via `.agency-version`
- [ ] Updates preserve user content (principals, knowledge, worklogs)
- [ ] End-to-end test of full onboarding flow passes

## Priority

**HIGH** - These are blocking issues for new user adoption.

## Process Issue: "Resolved" Items That Weren't

**Many of these issues were previously raised and marked as resolved, but were NOT actually fixed.**

This points to a deeper problem:
- Verbal/chat confirmation ≠ actually done
- No verification step before marking complete
- No end-to-end testing of the full user journey
- Changes made but not committed/pushed
- Changes made in one place but not synced to starter

**Proposed Process Fixes:**
1. Nothing is "resolved" until verified in a fresh install
2. Add `./tools/verify-onboarding` that runs full end-to-end test
3. Checklist before release: run installer on clean machine
4. "Done" means: coded, committed, pushed, synced to starter, AND verified
5. Track verification status separately from implementation status

## Notes

- Do NOT require users to nuke their Claude Code install
- Onboarding should be < 10 minutes with zero friction
- Every manual step is a potential dropout point
- **Trust but verify** - always test on fresh install before release
