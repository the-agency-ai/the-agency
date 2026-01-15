# Hub Agent Knowledge

Accumulated operational procedures, patterns, and schema references for managing The Agency.

## Operational Procedures

### Updating the Starter

To update the-agency-starter to the latest version:

```bash
# 1. Fetch latest changes
git fetch origin

# 2. Check what's new
git log HEAD..origin/main --oneline

# 3. Review CHANGELOG
cat CHANGELOG.md

# 4. Pull updates
git pull origin main

# 5. Handle any conflicts
git status
# Resolve conflicts manually if needed
```

**Best Practice:** Always review CHANGELOG.md before pulling to understand what's changing.

### Listing Registered Projects

Projects are tracked in `.agency/projects.json`:

```bash
# View all registered projects
cat .agency/projects.json | python3 -c '
import json, sys
data = json.load(sys.stdin)
for p in data.get("projects", []):
    print(f"{p[\"name\"]}: {p[\"path\"]} (v{p[\"starter_version\"]})")
'
```

**Fields per project:**
- `name` - Project name
- `path` - Absolute path to project
- `created_at` - When project was created
- `starter_version` - Starter version at creation time
- `status` - current, outdated, modified, or unknown

### Showing What's New

To see what's changed in The Agency:

```bash
# Check current version
cat VERSION

# View changelog
cat CHANGELOG.md

# Compare with a project's version
cat /path/to/project/.agency/manifest.json | python3 -c '
import json, sys
manifest = json.load(sys.stdin)
print(f"Project version: {manifest[\"project\"][\"starter_version\"]}")
'
```

### Creating New Projects

Use `project-new` to create a project from the starter:

```bash
# Basic usage
./tools/project-new my-project

# Create at specific path
./tools/project-new ~/code/my-project

# Create without launching agent
./tools/project-new my-project --no-launch

# Verbose output
./tools/project-new my-project --verbose
```

**What happens:**
1. Copies starter files to new directory
2. Initializes git repository
3. Generates `.agency/manifest.json`
4. Registers project in starter's `.agency/projects.json`
5. Runs install hooks (e.g., `bun install` for agency-service)

### Updating Existing Projects

Use `project-update` to sync a project with the starter:

```bash
# Check version status
./tools/project-update --status

# Preview available updates
./tools/project-update --preview

# Apply updates
./tools/project-update --apply

# Use local starter instead of GitHub
./tools/project-update --from=/path/to/starter --apply
```

### Initializing Manifest for Legacy Projects

For existing projects without a manifest:

```bash
cd /path/to/existing-project
/path/to/starter/tools/project-update --init --from=/path/to/starter
```

**What happens:**
1. Creates `.agency/manifest.json`
2. Detects installed components from registry
3. Computes SHA256 hashes for tracked files
4. Detects modifications by comparing to starter
5. Registers project in starter's `.agency/projects.json`

### Pre-Update Verification

Before updating any project, verify these conditions are met:

**1. Git status is clean**
```bash
cd /path/to/project
git status --short
# Should return empty (no uncommitted changes)
```

**2. Check for local modifications**
```bash
# Review manifest for modified files
cat .agency/manifest.json | python3 -c '
import json, sys
manifest = json.load(sys.stdin)
modified = [f for f, info in manifest.get("files", {}).items() if info.get("modified")]
if modified:
    print("Modified files:")
    for f in modified:
        print(f"  - {f}")
else:
    print("No local modifications detected")
'
```

**3. Review what will change**
```bash
# Preview changes before applying
./tools/project-update --preview --from=/path/to/starter

# Or use --check for quick status
./tools/project-update --check --from=/path/to/starter

# For programmatic verification (scripts, CI)
./tools/project-update --check --json --from=/path/to/starter
```

**4. Identify breaking changes**
- Review CHANGELOG.md for breaking change markers
- Look for major version bumps
- Check if modified files will be affected

**Verification checklist:**
- [ ] Working tree is clean (`git status` shows nothing)
- [ ] No untracked files in framework paths
- [ ] Local modifications identified and noted
- [ ] Preview reviewed for unexpected changes
- [ ] Breaking changes understood

### Batch Updating All Projects

To update all registered projects at once:

**1. Read the project registry**
```bash
cat .agency/projects.json | python3 -c '
import json, sys
data = json.load(sys.stdin)
for p in data.get("projects", []):
    print(p["path"])
'
```

**2. Check each project's status**
```bash
# Get starter path
STARTER_DIR=$(pwd)

# Check all projects
cat .agency/projects.json | python3 -c '
import json, sys, subprocess, os

data = json.load(sys.stdin)
starter = "'"$STARTER_DIR"'"

for p in data.get("projects", []):
    path = p["path"]
    name = p["name"]

    if not os.path.exists(path):
        print(f"{name}: PATH NOT FOUND")
        continue

    # Check git status
    result = subprocess.run(["git", "status", "--short"],
                          cwd=path, capture_output=True, text=True)
    if result.stdout.strip():
        print(f"{name}: DIRTY (uncommitted changes)")
        continue

    print(f"{name}: OK (clean)")
'
```

**3. Apply updates to clean projects**
```bash
STARTER_DIR=$(pwd)

cat .agency/projects.json | python3 -c '
import json, sys, subprocess, os

data = json.load(sys.stdin)
starter = "'"$STARTER_DIR"'"

for p in data.get("projects", []):
    path = p["path"]
    name = p["name"]

    if not os.path.exists(path):
        continue

    # Check if clean
    result = subprocess.run(["git", "status", "--short"],
                          cwd=path, capture_output=True, text=True)
    if result.stdout.strip():
        print(f"{name}: Skipping (dirty)")
        continue

    # Run preview first
    print(f"{name}: Checking for updates...")
    preview = subprocess.run(
        [f"{starter}/tools/project-update", "--preview", f"--from={starter}"],
        cwd=path, capture_output=True, text=True
    )

    if "up to date" in preview.stdout.lower():
        print(f"{name}: Already up to date")
    else:
        print(f"{name}: Updates available - run --apply to update")
'
```

**4. Report summary**
After batch operations, summarize:
- How many projects checked
- How many updated
- How many skipped (dirty)
- How many had errors

**Best Practice:** Always run in preview/check mode first before applying batch updates.

## Schema Reference

### manifest.schema.json

Located at: `claude/docs/schemas/manifest.schema.json`

Project manifest structure (`.agency/manifest.json`):
```json
{
  "schema_version": "1.0",
  "project": {
    "name": "project-name",
    "created_at": "ISO8601 timestamp",
    "starter_version": "1.0.0"
  },
  "source": {
    "type": "local|github",
    "path": "/path/to/starter",
    "repo": "owner/repo"
  },
  "components": {
    "component-name": {
      "version": "1.0.0",
      "status": "installed|available|modified|outdated",
      "dependencies": "installed|pending|none",
      "installed_at": "ISO8601 timestamp"
    }
  },
  "files": {
    "path/to/file": {
      "hash": "sha256 hash",
      "version": "1.0.0",
      "modified": false
    }
  }
}
```

### projects.schema.json

Located at: `claude/docs/schemas/projects.schema.json`

Project registry structure (`.agency/projects.json`):
```json
{
  "schema_version": "1.0",
  "projects": [
    {
      "name": "project-name",
      "path": "/absolute/path/to/project",
      "created_at": "ISO8601 timestamp",
      "starter_version": "1.0.0",
      "last_updated": "ISO8601 timestamp",
      "last_checked": "ISO8601 timestamp",
      "status": "current|outdated|modified|unknown"
    }
  ]
}
```

### registry.json

Located at: `registry.json` (starter root)

Component definitions:
```json
{
  "schema_version": "1.0",
  "starter_version": "1.0.0",
  "components": {
    "component-name": {
      "version": "1.0.0",
      "description": "What this component does",
      "files": ["glob/patterns/**/*"],
      "protected_paths": ["paths/never/updated/**/*"],
      "install_hook": "command to run after install",
      "dependencies": ["other-component"]
    }
  }
}
```

**Current components:**
- `core` - CLAUDE.md, docs, config, templates
- `tools` - CLI tools (myclaude, collaboration, etc.)
- `captain` - The Captain agent
- `housekeeping` - Default workstream
- `agency-service` - Backend service (requires bun install)
- `starter-packs` - Framework conventions
- `skills` - Agent skills (welcome, tutorial, etc.)

## Patterns & Best Practices

### Version Comparison

When checking if a project needs updates:
1. Read project's `.agency/manifest.json` for `starter_version`
2. Read starter's `VERSION` file
3. Compare versions (semver)
4. If different, run `--preview` to see changes

### Conflict Resolution

When `project-update --apply` encounters conflicts:
1. Files modified by user get backed up (`.backup-TIMESTAMP`)
2. New version is applied
3. User should review backup and merge changes

### Protected Paths

These paths are NEVER updated automatically:
- `tools/local/` - Project-specific tools
- `claude/principals/` - User's principals/requests
- `claude/agents/*/WORKLOG.md` - Agent work history
- `.agency/` - Local metadata
- Sprint directories

## Troubleshooting

### Project Not Registered

If a project doesn't appear in `.agency/projects.json`:
```bash
cd /path/to/project
/path/to/starter/tools/project-update --init --from=/path/to/starter
```

### Missing Manifest

If a project has no `.agency/manifest.json`:
```bash
./tools/project-update --init --from=/path/to/starter
```

### Outdated Components

If components show as "outdated" in manifest:
```bash
./tools/project-update --preview  # See what would change
./tools/project-update --apply    # Apply updates
```

---

*Knowledge grows with each project managed.*
