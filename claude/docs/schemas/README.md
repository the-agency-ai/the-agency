# Agency Schemas

This directory contains JSON Schema definitions for The Agency's data structures.

## Schemas

### manifest.schema.json

**Location in projects:** `.agency/manifest.json`

Tracks installed components, versions, and file states in each Agency project. Used by:
- `project-new` - creates initial manifest
- `project-update` - checks for updates, tracks modifications
- Agents - understand what's installed

### registry.schema.json

**Location in starter:** `registry.json` (root)

Defines available components in the-agency-starter. Used by:
- `project-new` - knows what to install
- `project-update` - knows what can be updated
- Hub Agent - understands available components

### projects.schema.json

**Location in starter:** `.agency/projects.json` (gitignored)

Tracks all projects created from this starter instance. Used by:
- Hub Agent - lists and manages projects
- `project-new` - registers new projects
- Batch update operations

## Usage

These schemas are used for:
1. **Documentation** - Understanding the data structures
2. **Validation** - Tools can validate against schemas
3. **Code Generation** - TypeScript types can be generated

## Example: Creating a Manifest

```bash
# In project-new, after copying files:
cat > .agency/manifest.json << EOF
{
  "schema_version": "1.0",
  "project": {
    "name": "$PROJECT_NAME",
    "created_at": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
    "starter_version": "$STARTER_VERSION"
  },
  "source": {
    "type": "local",
    "path": "$STARTER_DIR"
  },
  "components": {
    "core": { "version": "$STARTER_VERSION", "status": "installed" },
    "tools": { "version": "$STARTER_VERSION", "status": "installed" }
  },
  "files": {}
}
EOF
```

## Versioning

All schemas use `schema_version: "1.0"`. When schemas change:
- Minor changes: Add optional fields (backwards compatible)
- Major changes: Bump schema_version, provide migration
