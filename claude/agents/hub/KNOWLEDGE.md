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
cat .agency/projects.json | python3 -c "
import json, sys
data = json.load(sys.stdin)
for p in data.get('projects', []):
    print(f\"{p['name']}: {p['path']} (v{p['starter_version']})\")
"
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
cat /path/to/project/.agency/manifest.json | python3 -c "
import json, sys
manifest = json.load(sys.stdin)
print(f\"Project version: {manifest['project']['starter_version']}\")
"
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
