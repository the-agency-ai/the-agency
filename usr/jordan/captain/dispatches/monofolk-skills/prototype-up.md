---
allowed-tools: Read, Glob, Bash(pnpm prototype:up *)
description: Start a prototype's Docker dev stack (postgres, backend, frontends, nginx)
---

# Prototype Up

Start a prototype's full Docker dev stack with isolated ports.

## Arguments

- $ARGUMENTS: The prototype name (e.g., `checkout-v2`)

## Instructions

### Step 0: Parse arguments

If `$ARGUMENTS` is empty:

1. Read `docs/data-model/prototypes.md` and list active prototypes.
2. Ask: "Which prototype do you want to start?"

### Step 1: Start the stack

Run `pnpm prototype:up <name>`.

This will:

- Allocate ports (or reuse existing ones)
- Generate `.env.local` files for frontends
- Build and start all 7 Docker services
- Print the URLs for each service

### Step 2: Verify

After the stack starts, suggest: "Run `pnpm prototype:check <name>` to verify all services are healthy (wait ~30s for containers to warm up)."
