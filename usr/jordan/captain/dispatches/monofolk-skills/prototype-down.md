---
allowed-tools: Read, Glob, Bash(pnpm prototype:down *)
description: Stop a prototype's Docker dev stack and clean up .env.local files
---

# Prototype Down

Stop a prototype's Docker containers and clean up generated files.

## Arguments

- $ARGUMENTS: The prototype name (e.g., `checkout-v2`)

## Instructions

### Step 0: Parse arguments

If `$ARGUMENTS` is empty:

1. Read `docs/data-model/prototypes.md` and list active prototypes.
2. Ask: "Which prototype do you want to stop?"

### Step 1: Stop the stack

Run `pnpm prototype:down <name>`.

This will:

- Stop all Docker containers for this prototype
- Remove `.env.local` files from frontend apps

### Step 2: Confirm

Report that the stack has been stopped and cleaned up.
