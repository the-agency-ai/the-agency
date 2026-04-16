---
allowed-tools: Read, Edit, Write, Glob, Grep, Bash(mkdir *), Bash(git branch *), Bash(git worktree *), Bash(git rev-parse *), Bash(bash scripts/worktree-bootstrap.sh *), Bash(bash */claude/tools/proto-module-scaffold *), Bash(pnpm --filter backend exec prisma generate*)
description: Scaffold a new prototype (BE module, Prisma file, FE route, design spec, registry entry, git worktree)
---

# Create Prototype

Create a new prototype — from requirements discussion through full scaffolding.

## Arguments

- $ARGUMENTS: The prototype name in kebab-case (e.g., `checkout-v2`, `smart-prescriptions`). Optionally followed by a path to a rough design doc to use as input.

## Instructions

### Step 0: Parse arguments

If `$ARGUMENTS` is empty:

1. Ask: "What's the prototype name? (kebab-case, e.g., `checkout-v2`)"

### Step 1: Validate the name

1. The name must be kebab-case (lowercase letters, numbers, hyphens only).
2. Check `docs/data-model/prototypes.md` — if the name already exists, abort with an error.

### Step 2: Create git branch, worktree, bootstrap, and cd into it

Do this FIRST — before any discussion or scaffolding. The user should be in the prototype context from the start.

1. `git branch proto/<name>` — create a dedicated prototype branch from the current HEAD.
2. `git worktree add .worktrees/<name> proto/<name>` — create an isolated worktree.
3. `bash scripts/worktree-bootstrap.sh .worktrees/<name>/` — configure Doppler, install deps, generate Prisma clients.
4. `cd .worktrees/<name>/` — switch the Bash working directory into the worktree. This makes all subsequent Bash commands run from the worktree.
5. `git merge master --no-edit` — pull in any recent master commits so the worktree is up to date.

**IMPORTANT — absolute paths after cd:** The Bash tool's working directory is now `.worktrees/<name>/`. But Read, Write, Edit, Glob, and Grep tools still use the original session root. For ALL non-Bash file operations after this point, use the absolute worktree path. Compute it once:

```
WORKTREE=$(git rev-parse --show-toplevel)  # now returns the worktree path
```

Use `$WORKTREE/` prefix for all Read/Write/Edit/Glob/Grep paths.

Tell the user:

> Worktree created at `.worktrees/<name>/` on branch `proto/<name>`.
> We are now working inside the worktree.

### Step 2.5: Detect engineer name

Detect the current engineer for sandbox docs placement:

1. Look at `usr/*/` directories in the worktree root — if exactly one, use it
2. Otherwise, use `git config user.name` (lowercased, first word only)
3. Store as `$ENGINEER` for subsequent steps

### Step 3: Choose track

Ask the user:

> How would you like to proceed?
>
> 1. **Discuss first** — Start a requirements and design discussion. We'll capture decisions as we go, then scaffold when ready.
> 2. **Scaffold now** — You already know what you're building. Let's scaffold the backend module, Prisma schema, frontend route, and design spec.

**If the user provided a rough design doc path in $ARGUMENTS**, default to Track 2 (scaffold) but still ask.

### Track 1: Discussion flow

Create living docs in the engineer's sandbox: `.worktrees/<name>/usr/$ENGINEER/docs/<name>/`

**`requirements.md`** — empty template:

```markdown
# <Name> — Requirements

**Status:** Draft
**Date:** <today>

## Goal

_What does this prototype validate or explore?_

## Success criteria

_How will we know it succeeded?_

## Scope

### In scope

### Out of scope

## Key interactions

_Main user flows or API interactions_

## Data model

_What entities and relationships are needed?_

## Open questions
```

**`design.md`** — empty, to be filled during discussion:

```markdown
# <Name> — Design

**Status:** Not started
**Date:** <today>

_Design will be captured during discussion._
```

Also create the shared docs directory `.worktrees/<name>/docs/prototype/<name>/` (for build-manifest.json and promoted docs later).

Then start the requirements discussion. Follow the Discussion Protocol strictly:

- **Break input into numbered threads.** If the user presents multiple topics, questions, or requirements at once, number them. Address item 1 first. Only move to item 2 after item 1 is resolved.
- **Resolve each item before moving to the next.** Don't mix concerns.
- **Capture decisions in `requirements.md` as they are made.** Don't wait until the end. After each decision, update the file immediately.
- **Periodic checkpoint:** After every 3-4 decisions, read `requirements.md` back to the user and ask: "Is this accurate? Anything to change before we continue?"
- **Do NOT enter plan mode** unless the user explicitly asks for it. Discussion is not a plan request.
- When the user is ready to scaffold, proceed to Track 2 steps.

### Track 2: Scaffold flow

#### Step 4: Determine target frontend

Ask the user:

> Which frontend does this prototype target?
>
> 1. Standalone (prototype portal only — UI in prototype-fe)
> 2. doctor-frontend (feature prototype — UI in doctor app)
> 3. patient-frontend (feature prototype — UI in patient app)
> 4. ops-frontend (feature prototype — UI in ops app)

#### Step 5: Create design spec

Create `.worktrees/<name>/usr/$ENGINEER/docs/<name>/design.md` (if not already created in Track 1).

If the user provided a rough doc path, read it and use as input. If coming from Track 1, use `requirements.md` as input. Otherwise, ask the user to describe what this prototype validates. The spec should include:

- **Goal**: What this prototype validates or explores (1-2 sentences)
- **Success criteria**: How we'll know the prototype succeeded
- **Scope**: What's in and out of scope
- **Key interactions**: The main user flows or API interactions
- **Open questions**: Anything unresolved

Also create **`plan.md`** in the sandbox docs directory (`.worktrees/<name>/usr/$ENGINEER/docs/<name>/plan.md`):

- **Data model**: Tables/models the prototype needs
- **Backend**: API endpoints and services
- **Frontend**: Pages and key UI components
- **Sequence**: Suggested implementation order

#### Step 6: Scaffold backend module + Prisma schema + build manifest

Run the scaffold tool from the worktree:

```bash
bash $WORKTREE/claude/tools/proto-module-scaffold <name> --description "<description from design spec>" --owner "$ENGINEER"
```

This generates:
- `apps/backend/src/prototype/<name>/` — module, controller, service, DTOs, controller spec
- `apps/backend/prisma/proto_<snake_name>.prisma` — Prisma schema with Build model (UUID7)
- `docs/prototype/<name>/build-manifest.json` — initial build manifest

The tool prints next steps for registry registration.

Read the prototype CLAUDE.md for conventions: `apps/backend/src/prototype/CLAUDE.md`

#### Step 7: Register the module

Follow the scaffold tool's output. In `.worktrees/<name>/apps/backend/src/prototype/prototype.registry.ts`:

- Import the new module
- Add a `PrototypeEntry` to the `PROTOTYPE_REGISTRY` array

In `.worktrees/<name>/apps/backend/src/prototype/prototype.module.ts`:

- Import the new module
- Add it to the `imports` array

#### Step 8: Create frontend route

**If standalone (prototype-fe):**

Create `.worktrees/<name>/apps/prototype-fe/app/<name>/page.tsx` with a basic page that:

- Shows the prototype name as a heading
- Imports from `@/lib/prototype-api` with the prototype name pre-configured
- Has a placeholder for the prototype UI

Create `.worktrees/<name>/apps/prototype-fe/app/<name>/layout.tsx` with:

- A layout that renders `<PrototypeBanner label="<Name>" />`
- Wraps `{children}`

**If feature prototype (doctor-frontend, patient-frontend, or ops-frontend):**

Create `.worktrees/<name>/apps/<target-app>/app/prototype/<name>/page.tsx` and `layout.tsx` as above.

Also create a link page in prototype-fe:

- `.worktrees/<name>/apps/prototype-fe/app/<name>/page.tsx` — redirect page saying "This prototype lives in `<target-app>`" with a link to `/<target-app-basePath>/prototype/<name>/`

#### Step 9: Update the registry

Add a row to `.worktrees/<name>/docs/data-model/prototypes.md` with:

- Name, Status (Active), Owner (ask the user), Created (today's date), Target app, Tables, Frontend path

#### Step 10: Update the index page

Add the new prototype to the `prototypes` array in `.worktrees/<name>/apps/prototype-fe/app/page.tsx`.

#### Step 11: Summary

Print a summary of:

- All created files
- **Prototype type**: standalone or feature prototype targeting `<target-app>`
- Living docs: `usr/$ENGINEER/docs/<name>/` (requirements, design, plan — sandbox during development)
- Build manifest: `docs/prototype/<name>/build-manifest.json` (shared artifact)
- Git branch: `proto/<name>`
- Worktree: `.worktrees/<name>/`
- **Frontend route**: where the UI lives (`/prototype/<name>/` or `/<app>/prototype/<name>/`)
- **Next steps in the developer journey:**
  1. Review the design spec and plan
  2. Start building: `cd .worktrees/<name>/ && claude`
  3. Run the stack: `/preview local` (auto-detects prototype context)
  4. Share with team: `/preview dev`
  5. Ready to ship: `/prototype promote <name>`
