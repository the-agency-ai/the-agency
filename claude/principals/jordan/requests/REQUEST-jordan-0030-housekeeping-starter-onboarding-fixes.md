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
5. **Include AgencyBench build in `./tools/release-starter` checklist**
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

**Startup Sequence:**
```bash
# In myclaude:
1. Check if agency-service is running (curl health endpoint)
2. If not running, start it: ./tools/agency-service start
3. Wait for health check to pass (with timeout)
4. If fails, show error and offer to continue without services
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
install.sh → clones repo → done
```

**Expected Behavior:**
```
install.sh → check deps → install missing → clone repo → verify all working → done
```

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

**Current State:**
- Some deps checked in install.sh
- Some deps installed ad-hoc in tools
- Some deps just assumed to exist
- No single source of truth
- No way to verify all deps are present

**Known Dependencies (to be consolidated):**
- `git` - version control
- `claude` - Claude Code CLI
- `bun` - JavaScript runtime for agency-service
- `node` / `npm` - for AgencyBench build
- `jq` - JSON processing in bash scripts
- `curl` - fetching resources
- `rsync` - file syncing (used by release tools)
- `tree` - directory visualization (already have brew install)
- `gh` - GitHub CLI (for releases)
- Rust/Cargo - for Tauri builds

**Proposed Fix:**
1. Create `claude/config/dependencies.yaml` as SINGLE SOURCE OF TRUTH
2. Each dependency entry includes:
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
- [ ] `claude/config/dependencies.yaml` - the source of truth
- [ ] `./tools/install-dependencies` - installs all from yaml
- [ ] `./tools/check-dependencies` - verifies all present
- [ ] Update `install.sh` to use these tools
- [ ] Update `myclaude` to check on startup
- [ ] Document in CLAUDE.md

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

**Proposed Fix:**
Integrate setup-agency as first-run detection in myclaude:

```bash
# In myclaude:
if [ ! -f ".agency-setup-complete" ]; then
    echo "First run detected. Running setup..."
    ./tools/setup-agency
    # setup-agency creates .agency-setup-complete when done
fi
# Continue to launch Claude
```

**Why This Works:**
- stdin works because Claude hasn't launched yet
- Single entry point for users
- Can't skip setup
- setup-agency still exists for re-running/updates

**User Experience:**
```
$ ./tools/myclaude housekeeping housekeeping

First run detected. Running setup...

What is your name? █
```

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
- [ ] `claude/templates/principal/` exists with template
- [ ] `./tools/add-principal` exists for joining existing projects
- [ ] setup-agency triggered on first myclaude run (new project)
- [ ] add-principal triggered when joining existing project
- [ ] myclaude detects new project vs joining existing
- [ ] `.agency-setup-complete` marker created after setup
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
