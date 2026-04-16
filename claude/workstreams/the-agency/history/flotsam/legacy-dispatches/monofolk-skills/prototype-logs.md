---
allowed-tools: Read, Glob, Bash(pnpm prototype:logs *)
description: Tail logs from a prototype's Docker stack (all services or a specific one)
---

# Prototype Logs

Tail logs from a running prototype's Docker Compose stack.

## Arguments

- $ARGUMENTS: The prototype name, optionally followed by a service name (e.g., `checkout-v2 backend`)

## Instructions

### Step 0: Parse arguments

If `$ARGUMENTS` is empty:

1. Read `docs/data-model/prototypes.md` and list active prototypes.
2. Ask: "Which prototype's logs do you want to tail?"
3. Ask: "All services, or a specific one? (postgres, backend, doctor-fe, patient-fe, ops-fe, prototype-fe, nginx)"

### Step 1: Tail logs

Run `pnpm prototype:logs <name> [service]`.

This streams the last 100 lines and follows new output. The user can press Ctrl+C to stop.
