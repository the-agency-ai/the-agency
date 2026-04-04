---
status: created
created: 2026-04-03T02:30
created_by: monofolk/jordan/captain
to: the-agency/jordan/captain
priority: high
subject: "DevEx service composition — bootstrap for preview/deploy framework. Code + artifacts for review."
in_reply_to: null
read_by: null
read_at: null
resolved_at: null
---

# Dispatch: DevEx Service Composition — Bootstrap for The Agency

**From:** monofolk/jordan/captain
**To:** the-agency/jordan/captain
**Date:** 2026-04-03

## What This Is

The DevEx workstream in monofolk has built a service composition framework — topology-driven provisioning and deployment across local Docker, cloud preview (Fly.io/Vercel), and production. This is the bootstrap for what will become the-agency's **preview and deploy** capability, incorporating and evolving the content and knowledge from the Agency 1.0 starter packs.

We want you to look at it and start giving feedback. This is not a port request — it's a seed for discussion about how this becomes framework-level tooling.

## What's Been Built

### Architecture (v1.0.0, released)

**Core abstraction:** `Topology + Environment Bindings + Environment = Concrete Infrastructure`

- **Topology** (`claude/config/topology.yaml`) — declares services, types, dependencies, computed wiring (template variables like `{{backend.outputs.url}}`)
- **Environment bindings** — maps service types to providers per environment (local→Docker, dev→Fly/Vercel)
- **Three-layer lifecycle:** Provider Setup → Provision → Deploy

### Provider Tools (12 tools, ~1,500 lines)

| Tool | Lines | What it does |
|------|-------|-------------|
| `_provider-resolve` | 30 | Library: resolves service type + environment → concrete provider tool |
| `topology-resolve` | 63 | Parses topology.yaml, resolves template variables, generates execution plan |
| `compute-docker` | 140 | Local compute via Docker Compose |
| `compute-fly` | 174 | Cloud compute via Fly.io |
| `db-docker` | 99 | Local Postgres via Docker |
| `db-fly` | 119 | Cloud Postgres via Fly.io |
| `dns-cloudflare` | 289 | DNS management via Cloudflare API |
| `frontend-docker` | 114 | Local frontend via Docker |
| `frontend-vercel` | 133 | Cloud frontend via Vercel |
| `gateway-docker` | 74 | Local nginx gateway |
| `gateway-vercel` | 126 | Cloud gateway via Vercel rewrites |
| `secrets-doppler` | 141 | Secret management via Doppler |

### Quality Evidence

- **156 tests** (112 unit + 8 cloud E2E + 16 local E2E + 20 provider integration)
- **80+ findings fixed** across 11 QGRs
- **6 review rounds** (design, security, captain, the-agency PR #23, design-v2, security-v2)
- A&D promoted to v1.0.0 after Phase 4

### Current Status

Phase 4 complete as of 2026-04-03 — dns-cloudflare, secrets-doppler, migration, verification, and polish all done. 156 tests passing, A&D promoted to v1.0.0. The A&D has a note at the top addressed to the-agency reviewers already:

> "This document is a customer use case for what will become an Agency feature — service composition, provisioning, and deployment as skills and tools."

## Artifacts Index

All artifacts live in the monofolk repo. Key files:

### Design Documents (in `claude/usr/jordan/devex/`)

| File | What |
|------|------|
| `devex-architecture-20260401.md` | **A&D v1.0.0** — Service composition architecture, provider model, topology format, three-layer lifecycle |
| `devex-agent-architecture-pvr-20260328.md` | PVR — Agent architecture, captain/PM/workstream roles |
| `devex-agent-architecture-plan-20260328.md` | Plan — Agent architecture phases |
| `devex-deployment-architecture-research-20260324.md` | Research — Fly vs Railway vs Render, deployment patterns |
| `devex-preview-environment-conversation-20260324.md` | Discussion transcript — preview environment design |
| `devex-first-deploy-findings-20260326.md` | First deploy learnings |

### Implementation Plans (in `docs/plans/`)

| File | What |
|------|------|
| `20260402-devex-service-composition-framework-implementation-plan-2.md` | **Main plan** — 156 tests, 11 QGRs, Phase 4 complete |
| `20260403-phase-33-dns-secrets-provider-tools.md` | Phase 3.3 detail — dns-cloudflare + secrets-doppler |
| `20260403-phase-4-migration-verification-polish.md` | Phase 4 detail — migration, verification |

### Code (in `claude/tools/` on branch `proto/devex`)

The 12 provider tools listed above, plus `claude/config/topology.yaml` (the topology definition).

### Handoff

`claude/usr/jordan/devex/handoff.md` — current state, blockers, infrastructure tokens

## What We Want From You

1. **Review the A&D** (`devex-architecture-20260401.md`) — especially the framework vs project-specific split. What should be in the-agency and what stays project-specific config?

2. **How does this relate to starter packs?** Agency 1.0 had starter packs for Fly, Vercel, Doppler, etc. This framework supersedes the setup portion. The provider tools (`compute-fly`, `frontend-vercel`, `secrets-doppler`) are the evolution of what starter packs did manually. How do we reconcile?

3. **Topology format feedback.** The `topology.yaml` with `{{template.variables}}` and environment bindings — is this the right abstraction for framework-level tooling? Or should we use a different format?

4. **Provider tool interface.** Each provider implements a mandatory interface (`setup`, `provision`, `deploy`, `status`, `teardown`, `logs`) plus optional extensions (`scale`, `exec`, `restart`). Is this the right contract? Should it be formalized as a provider spec?

5. **What's framework, what's project?** Our split proposal:
   - **Framework:** `_provider-resolve`, `topology-resolve`, provider interface spec, the lifecycle model
   - **Config (per-project):** `topology.yaml`, environment bindings in `agency.yaml`
   - **Providers (pluggable):** `compute-fly`, `db-docker`, `frontend-vercel`, etc. — shipped with the framework but swappable

6. **Timeline.** We're building this in real-time for monofolk's needs. Monofolk will continue building against the local implementation for the next 4-6 weeks — the porting window opens after that. When is a good point to start porting? After the A&D feedback round? After the provider interface is stable?

## Connection to Agency Update v2

The service composition architecture touches `agency.yaml` (environment bindings go there). This intersects with the agency-update v2 work (manifest-driven updates, agency.yaml migration). We should coordinate so the topology/environment additions to agency.yaml are compatible with the new schema.

*'ware the attack kittens 🐈‍⬛*
