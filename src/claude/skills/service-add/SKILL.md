---
description: Add a backend service (NestJS prototype module) to an existing workstream using a SPEC-PROVIDER starter pack
---

# Service Add

Add a backend prototype module to an existing workstream. This fills the gap where a workstream exists but needs a new service added (second prototype, reusable service, etc.).

Uses the SPEC-PROVIDER pattern: the **SPEC** is the skill invocation (name + workstream), the **PROVIDER** is the starter pack at `claude/starter-packs/<type>/`.

## Arguments

- $ARGUMENTS: `<name>` — kebab-case service name. Followed by:
  - `--workstream <ws>` — existing workstream name (agency/workstreams/<ws>/) **[required]**
  - `--type <provider>` — starter pack [default: `nestjs-prototype`]
  - `--description <text>` — scaffold/registry description
  - `--owner <text>` — owner attribution in registry
  - `--dry-run` — preview all writes without making changes

## Examples

```
/service-add payments --workstream checkout --dry-run
/service-add ledger --workstream payments --description "transaction ledger"
/service-add billing-api --workstream billing --owner "Jordan & Claude"
```

## What it does

1. Validates name (kebab-case, not reserved), workstream (exists), starter pack (exists), no collision (`apps/backend/src/prototype/<name>/` must not exist)
2. Invokes the starter pack's `install.sh` which scaffolds the prototype module files
3. Updates `apps/backend/src/prototype/prototype.registry.ts` — adds the import + entry
4. Reports next steps (rebuild, test, run)

## What it does NOT do (v1)

- Does not add a new topology.yaml entry — v1 prototypes ride inside the existing `backend` compute service
- Does not create ORM models — add manually if the prototype needs DB access
- Does not create DTOs — add when endpoints need request validation beyond the stock three
- Does not change package.json or install dependencies
- Does not update agency.yaml

## Idempotency

- Safe to re-run on `--dry-run`
- Refuses to write over existing files (non-zero exit if `apps/backend/src/prototype/<name>/` exists)
- Registry patch is idempotent: skips import/entry if already present

## Available starter packs

- **nestjs-prototype** (v1 default) — NestJS module + controller + service + spec, manifest-backed (no DB dependency)

To add a new starter pack, see `claude/starter-packs/README.md`.

## Instructions

### Step 1: Parse and validate

Run `./agency/tools/service-add $ARGUMENTS` and relay the output.

The tool handles validation. If it fails, relay the error to the user verbatim.

### Step 2: Report

On success, the tool prints the "Next steps" block. Relay it to the user and ask if they want to proceed with step 1 (rebuild backend).

### Step 3: Report changed files

List the files the scaffold created/modified so the principal can review before committing. Do NOT auto-commit — commit policy is the principal's decision, consistent with `/workstream-create` which ends at a report + hand-off.

Changed files for a non-dry-run:

- `apps/backend/src/prototype/<name>/` (new directory, 4 files)
- `apps/backend/src/prototype/prototype.registry.ts` (modified — import + entry)
- `docs/prototype/<name>/build-manifest.json` (new file)

The principal decides whether to run `/iteration-complete` immediately, add follow-up changes (ORM schema, DTOs) first, or fold the scaffold into a larger iteration.
