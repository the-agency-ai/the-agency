---
title: 'DevEx Service Composition Architecture'
slug: devex-service-composition-architecture
date: 2026-04-01
status: draft
version: 0.1.0
branch: proto/devex
worktree: devex
authors:
  - Jordan Dea-Mattson (principal)
  - Claude Code (Opus 4.6)
tags: [Mono, DevEx]
---

# DevEx Service Composition Architecture

> **Note for The Agency reviewers:** This document is a customer use case for what will become an Agency feature — service composition, provisioning, and deployment as skills and tools. The MonoFolk-specific details (app names, providers, topology) illustrate how the feature would be applied in practice. Please review both the specific application and the general design pattern: what should be framework-level (reusable across any Agency project) vs. what is project-specific configuration?

## Problem

MonoFolk needs to describe, provision, and deploy sets of services across multiple environments (local, dev preview, PR preview, staging, production). Today this is done ad-hoc: Docker Compose files for local, manual Fly/Vercel commands for cloud, no shared model between them. Adding a new service means editing multiple files in multiple places. There's no way to deploy a subset (e.g., just Folio) or a single service without hand-editing config.

## Vision

A unified service composition model where you define your topology once and deploy it anywhere — local Docker, cloud preview, staging, production — by swapping provider bindings. The model handles the full lifecycle: provider setup, service provisioning, code deployment, teardown.

## Core Abstraction

```
Topology + Provider Bindings + Environment = Concrete Infrastructure
```

- **Topology:** Declares the services and their dependencies. "I have a compute service, a database, 5 frontends, a gateway."
- **Provider Bindings:** Maps service types to concrete providers per environment. "In local, db = Docker postgres. In cloud, db = Fly postgres."
- **Environment:** A named deployment target (local, dev, pr, staging, production) that selects which bindings to use.

## Architecture

### Three-Layer Lifecycle

Every service goes through up to three lifecycle stages:

```
Provider Setup  →  Provision  →  Deploy
(one-time)         (per-env)     (per-push)
```

1. **Provider Setup** — One-time: set up the provider itself. Create accounts, generate API tokens, configure org/team, store credentials in Doppler. Successor to Agency 1.0 starter packs.

2. **Provision** — Per-environment: create infrastructure for a service type on a provider. `provision fly app`, `provision docker db postgres`, `provision cloudflare cname`. Idempotent — skips what already exists.

3. **Deploy** — Per-push: ship code to provisioned infrastructure. Build image, push, run migrations, collect URLs.

Not every service needs all three. A Vercel frontend is stateless — provision and deploy are effectively the same operation. DNS is provision-only (no "deploy" to DNS). A database is provision-only (no code to deploy).

### Mapping to Tools, Skills, Agents

#### Data Layer (declarative files)

| Artifact | Purpose | Format |
|---|---|---|
| **Topology manifest** | Declares services, types, dependencies | YAML |
| **Provider bindings** | Maps service types to providers per environment | YAML |
| **Environment profiles** | Named targets (local, dev, pr, staging, production) | Part of bindings |
| **Provider definitions** | Describes a provider's capabilities, setup requirements | YAML |

#### Tools (deterministic, wrap CLIs)

Each provider gets a tool that implements a common interface:

```
<provider>-provider setup    — verify/configure the provider
<provider>-provider provision <service-type> [options]
<provider>-provider deploy <service> [options]
<provider>-provider teardown <service>
<provider>-provider status <service>
```

| Tool | Wraps | Provider ops |
|---|---|---|
| `docker-provider` | docker, docker-compose | Local containers, volumes, networks |
| `fly-provider` | flyctl | Fly apps, postgres, machines, IPs, certs, secrets |
| `vercel-provider` | vercel CLI | Vercel projects, deployments, domains |
| `cloudflare-provider` | Cloudflare API | DNS zones, CNAME records |
| `doppler-provider` | doppler CLI | Secret projects, configs, sync |
| `topology-resolve` | — | Reads topology + bindings + environment → concrete plan |
| `health-check` | curl/fetch | Hit endpoints, verify services are up |

#### Skills (orchestration, judgment)

| Skill | Purpose |
|---|---|
| `/provider-setup <provider>` | Set up a provider (account, tokens, org). Runs setup tool, stores creds in Doppler, verifies. Successor to starter packs. |
| `/provision <provider> <service-type>` | Provision a service type on a provider. Calls provider tool, handles errors. |
| `/deploy <service>` | Deploy code to a provisioned service. Picks the right provider tool from bindings. |
| `/preview <environment> [--services ...]` | Orchestrator. Resolves topology, provisions what's missing, deploys everything (or a subset), wires up gateway/DNS, runs health checks. |
| `/preview down <name>` | Teardown. Reverse of preview, handles partial state. |
| `/topology [view|add|edit]` | View or edit the service topology manifest. |

#### Agents (future)

| Agent | Purpose |
|---|---|
| `preview-monitor` | Watch a preview environment, report drift, health degradation |
| `provision-agent` | Complex multi-step provisioning with retries and rollback |

Not needed for v1. Skills calling tools is sufficient.

### Service Types

Service types are generic categories, not hardcoded to the current stack:

| Type | Examples | Lifecycle |
|---|---|---|
| `compute` | NestJS backend, API gateway, workers | provision + deploy |
| `frontend` | Next.js apps (doctor, patient, ops, folio-web) | deploy (Vercel is stateless) |
| `db` | PostgreSQL, Redis, SQLite | provision only |
| `gateway` | Reverse proxy, URL rewriter | provision + deploy |
| `dns` | CNAME records, zone config | provision only |
| `secrets` | Doppler config, env vars | provision only |
| `cache` | Redis, Memcached | provision only |
| `queue` | SQS, BullMQ | provision only |

New types can be added without changing the framework.

### Topology Manifest

A topology declares services and their dependencies:

```yaml
# topology.yaml
name: monofolk
version: 1

services:
  backend:
    type: compute
    depends_on: [db-main, secrets]
    build: apps/backend
    health: /health

  doctor-frontend:
    type: frontend
    build: apps/doctor-frontend
    depends_on: [backend]

  folio-web:
    type: frontend
    build: apps/folio-web
    depends_on: [db-folio]  # folio has its own schema

  gateway:
    type: gateway
    build: apps/gateway
    depends_on: [backend, doctor-frontend, patient-frontend, ops-frontend]

  db-main:
    type: db
    engine: postgres

  db-folio:
    type: db
    engine: postgres

  dns:
    type: dns

  secrets:
    type: secrets
```

### Provider Bindings

Bindings map service types to concrete providers per environment:

```yaml
# bindings.yaml
environments:
  local:
    providers:
      compute: docker
      frontend: docker
      db: docker
      gateway: docker
      dns: null  # localhost, no DNS needed
      secrets: doppler

  dev:
    providers:
      compute: fly
      frontend: vercel
      db: fly
      gateway: vercel
      dns: cloudflare
      secrets: doppler

  staging:
    providers:
      compute: fly
      frontend: vercel
      db: fly
      gateway: vercel
      dns: cloudflare
      secrets: doppler

  production:
    providers:
      compute: fly
      frontend: vercel
      db: fly
      gateway: vercel
      dns: cloudflare
      secrets: doppler
```

### The `/preview` Flow

```
/preview local
  1. topology-resolve(topology.yaml, bindings.yaml, local)
     → produces a concrete plan: which services, which providers, what order
  2. For each service in dependency order:
     a. Check if provider is set up (docker-provider status)
     b. Provision if needed (docker-provider provision <type>)
     c. Deploy if applicable (docker-provider deploy <service>)
  3. health-check all endpoints
  4. Report URLs and status

/preview dev
  1. topology-resolve(topology.yaml, bindings.yaml, dev)
  2. For each service in dependency order:
     a. Check provider (fly-provider status, vercel-provider status)
     b. Provision (fly-provider provision app, vercel-provider provision project)
     c. Deploy (fly-provider deploy backend, vercel-provider deploy doctor-frontend)
  3. Wire up gateway (vercel.json rewrites from collected URLs)
  4. Wire up DNS (cloudflare-provider provision cname)
  5. health-check all endpoints
  6. Report URLs and status

/preview local --services folio-web,db-folio
  1. topology-resolve with service filter → only folio-web + db-folio + their deps
  2. Provision and deploy only the filtered set
```

## Design Decisions

### DD-1: Topology is declarative, execution is skill-driven

The topology manifest describes *what*, not *how*. Skills read the topology and make judgment calls about execution order, error recovery, and partial state. This keeps the manifest simple and the complexity in code that can reason about it.

### DD-2: Provider tools implement a common interface

All provider tools support the same verbs: `setup`, `provision`, `deploy`, `teardown`, `status`. This makes providers swappable and the orchestration skills provider-agnostic. Adding a new provider means writing one tool, not modifying skills.

### DD-3: Local-first validation

Build and validate against Docker (local) before extending to cloud providers. Docker exercises the full architecture (topology resolution, dependency ordering, provisioning, deployment, health checks) without cloud costs or auth complexity.

### DD-4: Environment as binding selector, not separate config

Environments are not separate topology files. They're binding selectors — same topology, different provider mappings. This prevents drift between local and production topologies.

### DD-5: Subset deployment via service filter

`/preview local --services folio-web` deploys only folio-web and its transitive dependencies. The topology graph handles dependency resolution. No separate "folio topology" needed.

### DD-6: Starter packs become provider-setup skills

Agency 1.0 starter packs (vercel, supabase-auth, node-base, etc.) become `/provider-setup <provider>` skills. They retain composability, verification, and CLI-first approach, but gain agent judgment, idempotency, and Doppler integration.

### DD-7: Ideas adopted from System Initiative

- **Computed wiring:** Connection strings, URLs, and ports are derived from the topology graph, not hardcoded. If backend depends on db-main, the DATABASE_URL is computed from the provisioned db's connection info.
- **Environment overlays:** Same base topology, environment-specific bindings layered on top (SI's "change set" concept).
- **Continuous qualifications:** Health checks and policy constraints are part of the service model, evaluated continuously — not just at deploy time.

## Constraints

- **No server-level configuration.** This is service composition, not infrastructure-as-code. We're pulling together managed services (Vercel, Fly.io, Cloudflare, Supabase, GCP), not configuring VMs.
- **Extensible, not hardcoded.** Service types, providers, and environment profiles can be added without framework changes. Don't assume postgres, don't assume a backend exists, don't assume the service list is fixed.
- **Cloud services are managed services.** Off local, everything is a managed service (Fly.io, Vercel, Cloudflare, Supabase, GCP BigQuery). No self-managed infrastructure beyond local Docker.

## Validation Plan

Three twists against local/Docker to prove the architecture:

1. **Full stack** — backend + postgres + all frontends + gateway. Exercises the full dependency graph and all service types.
2. **Folio stack** — folio-web + folio db only. Exercises subset deployment and service filtering.
3. **Single service** — just the backend, or just one frontend. Exercises the minimal case.

If the same `/preview local` handles all three via topology + bindings + service filter, the architecture validates.

## Open Questions

- **Topology format:** YAML is proposed but not confirmed. Could be JSON, TOML, or even TypeScript for computed values. Needs prototyping.
- **Provider definition format:** How does a provider declare what service types it supports and what options they take?
- **Computed wiring details:** How exactly does DATABASE_URL flow from db-main's provisioned state to backend's deploy? Output → input mapping needs design.
- **State tracking:** Where does the system record what's currently provisioned? A registry file? The provider's own state?
- **PR/branch previews:** How does the naming/isolation work? Each PR gets its own topology instance with unique names?

## Dependencies

- Existing Docker Compose files (`docker-compose.dev.yml`) — starting point for docker-provider
- Existing `/preview` command (`claude/usr/jordan/commands/preview.md`) — to be replaced by the new skill
- First-deploy findings (`devex-first-deploy-findings-20260326.md`) — informs cloud provider implementations
- Doppler project `sg_dev_noah` — secrets management
- Agency 1.0 starter packs (`~/code/the-agency/claude/starter-packs/`) — reference for provider-setup skills
