---
type: pvr
project: scaffold
workstream: devex
date: 2026-04-14
status: draft
seeds:
  - dispatch #200 (SPEC:PROVIDER NestJS + React/Next.js scaffolding)
---

# PVR: scaffold — Application Scaffolding (SPEC:PROVIDER)

## 1. Problem Statement

Building real applications in the-agency repo — NestJS backends, React/Next.js frontends — requires manual project setup every time. Developers must hand-create directory structures, install dependencies, configure TypeScript/ESLint/testing, wire up CLAUDE.md for agent integration, and register the new app with the plan's test-scoper. This is slow, error-prone, and produces inconsistent results across workstreams.

**For whom:** Agents and principals creating new application workstreams.
**Why now:** Two concrete applications are queued — "This Happened!" (user issue reporting service) and "Breadcrumb" (distributed tracing) — and both need NestJS backends and React/Next.js frontends. Without one-command scaffolding, each app launch starts with 30+ minutes of boilerplate setup.

## 2. Target Users

| User | Role | Gets |
|------|------|------|
| Worktree agents | Feature implementation | `scaffold backend my-service`, `scaffold frontend my-app` |
| Captain | Workstream creation | Scaffold as part of `/workstream-create` |
| Principals | Prototyping | Quick app standup without framework knowledge |

## 3. Use Cases

### Backend scaffolding
- `scaffold backend my-service` -- scaffolds a NestJS service in `apps/my-service/`
- Produces: TypeScript project with ESLint, testing, standard module structure
- Integrates: CLAUDE.md in app directory, test-scoper mapping in plan

### Frontend scaffolding
- `scaffold frontend my-app` -- scaffolds a Next.js 14+ app in `apps/my-app/`
- Produces: App Router project with Tailwind CSS, TypeScript
- Integrates: CLAUDE.md in app directory, test-scoper mapping in plan

### Combined scaffolding
- Agent scaffolds both a backend and frontend for a new workstream in sequence
- Both apps share consistent conventions (TypeScript config, lint rules, testing approach)

## 4. Functional Requirements

### FR1: `claude/tools/scaffold` — SPEC:PROVIDER wrapper

Top-level dispatcher following the established pattern (secret, preview, deploy). Reads provider config from `agency.yaml`:

```yaml
scaffold:
  backend:
    provider: nestjs    # Default. Alternatives: express, fastify
  frontend:
    provider: nextjs    # Default. Alternatives: vite-react, remix
```

Verb contract:
- `scaffold backend <name>` -- reads `scaffold.backend.provider`, execs `scaffold-backend-{provider}`
- `scaffold frontend <name>` -- reads `scaffold.frontend.provider`, execs `scaffold-frontend-{provider}`
- `scaffold list` -- lists available providers for both backend and frontend

The wrapper has two dispatch keys (backend/frontend) rather than one, which is a slight extension of the single-provider wrappers (secret, preview, deploy). The first positional arg selects the facet, the second is the app name, and remaining args pass through.

### FR2: `claude/tools/scaffold-backend-nestjs` — NestJS provider

Scaffolds a NestJS service at `apps/<name>/` with:
- TypeScript strict mode
- ESLint with framework-consistent config
- Test runner (see Open Question OQ3)
- Standard NestJS module structure: `src/app.module.ts`, `src/main.ts`, `src/app.controller.ts`, `src/app.service.ts`
- `package.json` with scripts: `build`, `start`, `start:dev`, `test`, `lint`
- `.gitignore` for node_modules, dist, coverage

### FR3: `claude/tools/scaffold-frontend-nextjs` — Next.js provider

Scaffolds a Next.js 14+ app at `apps/<name>/` with:
- App Router (`app/` directory)
- Tailwind CSS configured
- TypeScript strict mode
- ESLint with framework-consistent config
- Test runner (see Open Question OQ3)
- Standard structure: `app/layout.tsx`, `app/page.tsx`, `app/globals.css`
- `package.json` with scripts: `build`, `start`, `dev`, `test`, `lint`
- `.gitignore` for node_modules, .next, coverage

### FR4: CLAUDE.md generation

Both providers create a `CLAUDE.md` in the app directory containing:
- App name and purpose (from `--description` flag or placeholder)
- Build/test/lint commands
- Directory structure summary
- Integration notes (how this app relates to the agency framework)

### FR5: Test-scoper integration

Both providers add the new app to the plan's test-scoper mappings so that changes in `apps/<name>/` trigger the correct test suite. The mapping is appended to `claude/config/agency.yaml` under the `testing.suites` section:

```yaml
testing:
  suites:
    my-service:
      command: "cd apps/my-service && npm test"
      description: "my-service NestJS tests"
```

### FR6: `/scaffold` skill

Skill at `.claude/skills/scaffold/SKILL.md` for agent discovery via `/scaffold`. The skill:
- Describes the verb contract (backend, frontend, list)
- Shows usage examples
- Triggers ref-injector for relevant docs

### FR7: agency.yaml default config

The scaffold section is added to agency.yaml with sensible defaults:

```yaml
scaffold:
  backend:
    provider: nestjs
  frontend:
    provider: nextjs
  target_dir: apps    # Where scaffolded apps land
```

## 5. Named Applications (Motivation)

These applications motivated this PVR and will be the first consumers:

| Name | Type | Purpose |
|------|------|---------|
| **This Happened!** | NestJS backend + Next.js frontend | User issue reporting service — structured feedback capture |
| **Breadcrumb** | NestJS backend + Next.js frontend | Distributed tracing for multi-agent sessions |

Both need identical scaffolding patterns, which is exactly the "two instances prove the abstraction" threshold for building a tool.

## 6. Non-Functional Requirements

- **Idempotent guards:** Refuse to scaffold if `apps/<name>/` already exists (no silent overwrite)
- **Offline-capable:** Scaffolding must work without network access (no `npx create-next-app` at runtime — templates are bundled)
- **Speed:** Scaffold completes in under 5 seconds (excluding `npm install`)
- **Dependency install:** Optional `--install` flag runs package manager after scaffold; default is scaffold-only

## 7. Constraints

- Ships on the devex branch (standard worktree workflow)
- Must not modify existing app directories
- Provider tools are Bash scripts in `claude/tools/` following the established pattern
- Template files live in `claude/templates/scaffold/` (new directory)
- Must work in worktrees and main checkout

## 8. Success Criteria

1. `scaffold backend foo` produces a runnable NestJS project at `apps/foo/`
2. `scaffold frontend bar` produces a runnable Next.js project at `apps/bar/`
3. Both projects build and pass their generated tests out of the box
4. CLAUDE.md is present and accurate in each scaffolded app
5. Test-scoper mapping is added to agency.yaml
6. `/scaffold` skill is discoverable and functional

## 9. Non-Goals

- **Not deploying** — that is `/deploy` (SPEC:PROVIDER already exists)
- **Not previewing** — that is `/preview` (SPEC:PROVIDER already exists)
- **Not managing dependencies post-scaffold** — that is the developer's job
- **Not a general-purpose project generator** — focused on NestJS + Next.js for agency apps
- **Not database migration scaffolding** — that is a separate concern for later
- **Not Docker/containerization** — that is `/preview` provider territory

## 10. Resolved Decisions (pending monofolk confirmation)

Captain approved proceeding with these defaults while monofolk RFI is in flight (#284):

### D1: Monorepo structure — **apps/ + packages/**
- `apps/` for user-facing applications (NestJS services, Next.js frontends)
- `packages/` for shared libraries (types, utils, UI components)
- Both managed as a pnpm workspace
- Rationale: monofolk already runs NestJS + Next.js in production with a monorepo — this matches the pattern. `packages/` starts empty and grows only when a shared lib is actually needed.

### D2: Package manager — **pnpm**
- Root `pnpm-workspace.yaml` lists `apps/*` and `packages/*`
- Consistent with the-agency-workshop repo
- Better workspace support than npm for monorepos
- Faster installs, strict node_modules isolation

### D3: Test runner — **Vitest**
- For both NestJS backends and Next.js frontends
- Faster than Jest, native ESM, compatible Jest API
- NestJS works fine with Vitest via `@nestjs/testing`
- Consistent tooling across backend + frontend reduces cognitive load

## 11. Pending monofolk confirmation

RFI sent via captain #284. If monofolk responds with different conventions, we will adjust:
- D1 alternatives: apps/ only (flatter), or nested service/app boundaries
- D2 alternatives: npm (if monofolk uses npm in production)
- D3 alternatives: Jest (if monofolk's existing test infrastructure is Jest-based)

Adjustment is low-cost pre-implementation — decisions are in agency.yaml config and template selection. PVR → A&D → Plan proceeds with D1/D2/D3 as the working assumption.
