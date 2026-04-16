# REQUEST-jordan-0041-housekeeping-the-agency-starter-public-release

**Status:** In Progress
**Priority:** High
**Requested By:** agent:housekeeping (on behalf of jordan)
**Assigned To:** housekeeping
**Created:** 2026-01-11
**Updated:** 2026-01-12

## Summary

Prepare the-agency-starter for public release on GitHub.

## Overview

**the-agency** = Private working project with real agents/principals doing work
**the-agency-starter** = Public platform/tooling/scaffolding for others to use The Agency

The build process generates the-agency-starter FROM the-agency, filtering out project-specific and sensitive content.

## Directory Structure

```
/Users/jdm/code/
├── the-agency/           # Private monorepo (source)
├── the-agency-starter/   # Public standalone repo (built from source)
└── test/                 # Testing directory
```

---

## Implementation Plan

### Step 1: Commit deletion in the-agency ✅ DONE
- [x] Move `the-agency/the-agency-starter/` to `code/the-agency-starter/`
- [ ] Commit the removal from the-agency monorepo

### Step 2: Scrub the-agency-starter
Remove sensitive/project-specific content from `/Users/jdm/code/the-agency-starter`:

**Delete entirely:**
- `claude/principals/jordan/` (~75 files) - entire directory
- `claude/agents/housekeeping/SESSION-*.md` (~7 files)
- `claude/agents/housekeeping/backups/` directory
- `claude/agents/collaboration/CODE-REVIEW-*.md`

**Keep:**
- `claude/agents/housekeeping/KNOWLEDGE.md` (general framework knowledge)
- `claude/agents/housekeeping/agent.md`

**Modify:**
- `claude/config.yaml` - Remove `jdm: jordan` mapping
- `claude/config/agency.yaml` - Remove `jdm: jordan` mapping
- Documentation - Replace `jordan`/`jdm` with generic examples
- `claude/agents/housekeeping/ADHOC-WORKLOG.md` - Reset to empty template

**Result:** `claude/principals/` should be empty (onboarding creates principal on first run)

### Step 3: Create Build Tooling

#### 3.1 Create Manifest (`claude/config/starter-manifest.yaml`)
YAML file defining what gets copied from the-agency to the-agency-starter:
```yaml
# What to include from the-agency
include:
  - tools/
  - apps/agency-bench/
  - services/agency-service/
  - claude/agents/housekeeping/agent.md
  - claude/agents/housekeeping/KNOWLEDGE.md
  - claude/templates/
  - claude/docs/
  - claude/starter-packs/
  - claude/integrations/
  # ... etc

# What to exclude (never copy)
exclude:
  - claude/principals/*/requests/
  - claude/principals/*/sessions/
  - claude/principals/*/notes/
  - claude/principals/*/observations/
  - claude/principals/*/ideas/
  - claude/principals/*/artifacts/
  - claude/principals/*/projects/
  - claude/principals/*/resources/secrets/
  - claude/agents/*/SESSION-*.md
  - claude/agents/*/backups/
  - "*.env"
  # ... etc

# Files to transform (replace patterns)
transform:
  - pattern: "jdm: jordan"
    replacement: "# your-username: your-principal-name"
  - pattern: "/Users/jdm/"
    replacement: "/path/to/your/project/"
```

#### 3.2 Create `starter-manifest` tool
Manage the manifest file:
```bash
./tools/starter-manifest list              # View all entries
./tools/starter-manifest add include path  # Add include path
./tools/starter-manifest add exclude path  # Add exclude pattern
./tools/starter-manifest remove path       # Remove entry
./tools/starter-manifest edit              # Open in editor
./tools/starter-manifest validate          # Check manifest is valid
```

#### 3.3 Create `starter-build` tool
Build the-agency-starter from the-agency:
```bash
./tools/starter-build                      # Build to code/the-agency-starter
./tools/starter-build --dry-run            # Preview what would be copied
./tools/starter-build --verbose            # Show detailed output
```
- Reads manifest
- Copies included files to the-agency-starter
- Excludes specified patterns
- Applies transformations
- Validates no sensitive content leaked

### Step 4: Create Release Tooling

#### 4.1 Fix GitHub Remote
Current remote has embedded token (security issue):
```
origin: https://ghp_RUvW...@github.com/the-agency-ai/the-agency-starter.git
```
Fix to use `gh` CLI for authentication:
```bash
cd code/the-agency-starter
git remote set-url origin https://github.com/the-agency-ai/the-agency-starter.git
gh auth login  # If not already authenticated
```

#### 4.2 Create/Update `starter-release` tool
Release the-agency-starter to GitHub:
```bash
./tools/starter-release                    # Release current version
./tools/starter-release 1.0.1              # Release specific version
./tools/starter-release --dry-run          # Preview release
```
- Source: `code/the-agency-starter`
- Destination: `github.com/the-agency-ai/the-agency-starter`
- Uses `gh` CLI for push
- Creates version tag
- Updates CHANGELOG

### Step 5: Create Testing Tooling

#### 5.1 Create `starter-test` tool
End-to-end testing:
```bash
./tools/starter-test                       # Run full test suite
./tools/starter-test --install-only        # Just test install
./tools/starter-test --create-only         # Just test create-project
./tools/starter-test --verbose             # Detailed output
```
Tests:
1. Run local install to `code/test/the-agency-starter`
2. Compare `code/test/the-agency-starter` against `code/the-agency-starter`
3. Run `create-project` in `code/test/` → `code/test/test-agency-first-project`
4. Compare installed starter against new project (with expected differences)

#### 5.2 Create `starter-test-cleanup` tool
Clean up test directory:
```bash
./tools/starter-cleanup               # Remove test/ contents
./tools/starter-cleanup --keep-logs   # Keep logs for debugging
```

### Step 6: Add Onboarding to myclaude

Modify `tools/myclaude` to detect first run and prompt for principal:
```bash
# On first run, if no principal configured:
# 1. Prompt: "Welcome! What's your name (for principal)?"
# 2. Create claude/principals/{name}/
# 3. Create subdirectories (requests/, notes/, etc.)
# 4. Update config mapping
# 5. Continue with normal startup
```

### Step 7: Final Release

1. Run `starter-build` to generate clean the-agency-starter
2. Run `starter-test` to validate
3. Run `starter-release` to push to GitHub
4. Make repo public
5. Test public install: `curl -fsSL https://raw.githubusercontent.com/the-agency-ai/the-agency-starter/main/install.sh | bash`

---

## Tools Summary

| Tool | Purpose |
|------|---------|
| `starter-manifest` | Manage build manifest (view/add/remove/edit) |
| `starter-build` | Build the-agency-starter from the-agency |
| `starter-release` | Release to GitHub |
| `starter-test` | End-to-end testing |
| `starter-test-cleanup` | Clean test directory |

---

## Acceptance Criteria

- [ ] the-agency-starter removed from the-agency monorepo
- [ ] No sensitive content in the-agency-starter
- [ ] `claude/principals/` is empty in starter
- [ ] Manifest file created and populated
- [ ] `starter-manifest` tool works
- [ ] `starter-build` tool works
- [ ] `starter-release` tool works (with gh CLI)
- [ ] `starter-test` tool works
- [ ] `starter-test-cleanup` tool works
- [ ] myclaude onboarding creates principal on first run
- [ ] End-to-end test passes: install → create-project → run
- [ ] Public install from GitHub works
- [ ] Version is 1.0.1 (bump to 2.0.0 before announce)

---

## Notes

- KNOWLEDGE.md contains general framework knowledge - keep it
- GitHub remote needs token removed, use gh CLI for auth
- gh CLI needs `gh auth login`
- Manifest format: YAML (human/agent readable, supports comments)

---

## Activity Log

### 2026-01-11 - Created
- Request created by agent:housekeeping (on behalf of jordan)

### 2026-01-11 - Planning Complete
- Comprehensive security audit performed
- Identified files to delete/modify
- Initial implementation plan created

### 2026-01-12 - Plan Refined
- Moved the-agency-starter to code/the-agency-starter (Step 1 partial)
- Clarified build vs release process
- Defined tool naming: starter-build, starter-release, starter-test, starter-manifest
- Added onboarding requirement for myclaude
- Chose YAML for manifest format
- Identified gh CLI auth requirement
- Updated implementation plan with detailed steps
