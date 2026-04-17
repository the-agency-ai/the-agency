---
description: Add a frontend app (Next.js) to an existing workstream using a SPEC-PROVIDER starter pack
---

# UI Add

Add a frontend app to an existing workstream. Fills the gap where a workstream exists but needs a new UI — a payment UI for the payments workstream, an admin panel for ops, etc.

Uses the SPEC-PROVIDER pattern: the **SPEC** is the skill invocation (name + workstream + port), the **PROVIDER** is the starter pack at `claude/starter-packs/<type>/`.

## Arguments

- $ARGUMENTS: `<name>` — kebab-case app name (becomes `apps/<name>/`). Followed by:
  - `--workstream <ws>` — existing workstream name **[required]**
  - `--type <provider>` — starter pack [default: `nextjs-app`]
  - `--port <num>` — host port [default: next free in 4100–4199]
  - `--base-path <path>` — Next.js basePath [default: `/<name>`]
  - `--dry-run` — preview all writes without making changes

## Examples

```
/ui-add payments-ui --workstream payments --dry-run
/ui-add admin --workstream ops --port 4150
/ui-add marketing --workstream marketing --base-path /mkt
```

## What it does

1. Validates name (kebab-case, not reserved), workstream (exists), starter pack (exists), no collision (`apps/<name>/` must not exist)
2. Allocates a free port in the frontend range (4100–4199) by scanning `docker-compose.dev.yml`, unless `--port` is provided
3. Invokes the starter pack's `install.sh` which scaffolds the app files
4. Updates `claude/config/topology.yaml` — adds a `frontend` service entry with `wires_from: [backend]`
5. Reports next steps (pnpm install, pnpm dev)

## What it does NOT do (v1)

- Does not edit `docker-compose.dev.yml` — add the service block manually if needed for the full stack
- Does not install deps (run `pnpm install` at repo root)
- Does not init shadcn/Tailwind (uses `@of/ui` workspace package instead)
- Does not wire Vercel / Fly.io (cloud providers are separate)
- Does not update agency.yaml

## Idempotency

- Safe to re-run on `--dry-run`
- Refuses to write over existing files (non-zero exit if `apps/<name>/` exists)
- Topology patch is idempotent: reports "already present" if the service is in topology.yaml with matching fields

## Available starter packs

- **nextjs-app** (v1 default) — Next.js 16 + React 19 + `@of/ui` workspace, Dockerfile, `basePath: /<name>`

## Instructions

### Step 1: Parse and validate

Run `./claude/tools/ui-add $ARGUMENTS` and relay the output.

The tool handles validation. If it fails, relay the error verbatim.

### Step 2: Report

On success, the tool prints a "Next steps" block. Relay it to the user.

### Step 3: Report changed files

List the files the scaffold created/modified so the principal can review before committing. Do NOT auto-commit — commit policy is the principal's decision, consistent with `/workstream-create` which ends at a report + hand-off.

Changed files for a non-dry-run:

- `apps/<name>/` (new directory, 9 files)
- `claude/config/topology.yaml` (modified — new frontend entry)

The principal decides whether to run `/iteration-complete` immediately, extend `docker-compose.dev.yml` to include the new app first, or fold the scaffold into a larger iteration.
