---
title: 'Review Response: DevEx Service Composition A&D'
type: dispatch-response
status: complete
date: 2026-04-01
source: captain (the-agency framework)
target: jordan (principal)
in-response-to: dispatch-devex-service-composition-review-20260401.md
---

# Review Response: DevEx Service Composition A&D

Three-agent parallel review of `claude/docs/design/devex-service-composition-architecture.md` covering: (1) framework vs. project-specific boundaries, (2) fit with existing Agency patterns, (3) general design feedback. Plus a design proposal for how the framework should evolve.

**Key context:** The installed base is two projects — the-agency (no deployments) and monofolk (the customer). We sit on both sides. No backwards compatibility needed. Build it right from the start.

---

## 1. Framework-Level Features to Extract

| Component | Priority | Notes |
|-----------|----------|-------|
| **Topology manifest format** (YAML schema) | P0 | The genuinely new framework concept. Services, types, dependencies, computed wiring. |
| **`topology-resolve` tool** | P0 | Core engine: topology + agency.yaml environments + environment arg → concrete plan. |
| **Provider tool interface** (setup/provision/deploy/teardown/status + day-2 verbs) | P0 | The provider contract. Multi-verb. Document as spec + ship a provider template. |
| **Service type taxonomy** (compute, frontend, db, gateway, dns, secrets, cache, queue) | P0 | Default set, extensible. |
| **`agency.yaml` environments section** | P0 | Environment-aware provider mapping. Replaces flat provider fields. See design proposal below. |
| **`_provider-resolve` v2** | P0 | Two-arg: `_provider-resolve <type> <environment>`. Clean break from v1. |
| **`/preview` orchestration skill** | P1 | Flagship. Resolve → provision → deploy → health-check. |
| **`/provider-setup` skill** | P1 | Interactive provider setup. Replaces starter packs (setup portion). |
| **`/service-provision` and `/service-deploy` skills** | P1 | Namespaced to avoid bare-verb collision. |
| **`docker-provider` → `compute-docker`** | P1 | Local-first validation. Ships with framework. |
| **`health-check` tool** | P1 | Generic HTTP endpoint checker. |
| **State tracking format** | P1 | Provider tools query provider state (authoritative). Framework provides a cache/registry format for fast lookups. |
| **`/topology` skill** | P2 | View/edit topology. |
| **`compute-fly`, `frontend-vercel`, `dns-cloudflare`** | P2 | Bundled providers, projects opt in. |

**Project-specific:** Topology content, provider choices, MonoFolk service definitions.

---

## 2. Design Proposal: How the Framework Evolves

### agency.yaml gets an `environments` section

No separate `bindings.yaml`. One config file. Clean break.

```yaml
project:
  name: "monofolk"

secrets:
  provider: vault

terminal:
  provider: ghostty

environments:
  local:
    compute: docker
    frontend: docker
    db: docker
    gateway: docker
    dns: null
    secrets: doppler
  dev:
    compute: fly
    frontend: vercel
    db: fly
    gateway: vercel
    dns: cloudflare
    secrets: doppler
  production:
    compute: fly
    frontend: vercel
    db: fly
    gateway: vercel
    dns: cloudflare
    secrets: doppler
  # Per-service overrides when type-level defaults aren't enough
  overrides:
    special-worker:
      dev:
        provider: aws-lambda
        options:
          memory: 1024
```

### _provider-resolve becomes two-arg

```bash
# Today (dies):  _provider-resolve secrets → secret-vault
# Tomorrow:      _provider-resolve compute local → compute-docker
#                _provider-resolve compute production → compute-fly
#                _provider-resolve secrets local → secrets-doppler
```

Reads the `environments` section of `agency.yaml`. Clean, no fallback paths.

### Tool naming: `{type}-{provider}`

Natural extension of what already works:

| Today | Tomorrow |
|-------|----------|
| `secret-vault` | `secrets-vault` (pluralize for consistency) |
| `secret-doppler` | `secrets-doppler` |
| — | `compute-docker` |
| — | `compute-fly` |
| — | `frontend-vercel` |
| — | `frontend-docker` |
| — | `dns-cloudflare` |

Multi-verb via argument: `compute-fly setup`, `compute-fly provision`, `compute-fly deploy`, `compute-fly status`, `compute-fly logs`, `compute-fly scale`.

### Topology is a separate artifact

Because it describes the **application** (services, dependencies, build paths), not the **Agency config** (providers, environments).

Lives at `claude/config/topology.yaml`. Read by `topology-resolve`.

### Computed wiring via template interpolation

Provider tools emit structured JSON output:
```json
{"service": "db-main", "type": "db", "outputs": {"url": "postgres://...", "host": "localhost", "port": 5432}}
```

Topology declares the wiring:
```yaml
services:
  backend:
    type: compute
    depends_on: [db-main]
    env:
      DATABASE_URL: "{{db-main.outputs.url}}"
```

`topology-resolve` collects outputs in dependency order and interpolates. Simple, debuggable, no magic.

### Starter packs split into two concerns

1. **Provider setup** → `/provider-setup <provider>` skill (account, tokens, verify, store creds)
2. **App scaffolding** → separate skills per stack (middleware templates, config files, framework presets) — these are NOT provider-specific, they're stack-specific

A Vercel provider setup is "create account, get token." A Next.js app scaffold is "create next.config.js, add middleware, set up .vercelignore." Different concerns, different skills.

---

## 3. Review Findings

### Critical — Design Decisions Required Before Prototyping

**C1: Computed wiring must be designed first.** The output-to-input mapping (DATABASE_URL flowing from db to backend) determines the provider tool's output contract. Proposal above: template interpolation against structured provider output. Must be validated before writing provider tools.

**C2: State tracking approach.** Proposal: provider tools query the provider for authoritative state (`compute-fly status`). Framework provides a local cache/registry for fast lookups between queries. No Terraform-style state file as source of truth — the provider IS the source of truth.

### Major

**M1: Failure/retry semantics for `/preview`.** When service 3 of 8 fails to provision: log the failure, continue with independent services, report partial state at the end. No automatic rollback — user decides. `/preview` should be resumable (idempotent provision means re-running skips what succeeded).

**M2: Day-2 operations.** Provider tool interface needs verbs beyond setup/provision/deploy/teardown/status. Add: `logs`, `scale`, `exec`, `restart`. These are daily operations that practitioners need.

**M3: `gateway` type conflates service with config artifact.** Docker gateway = running container. Vercel gateway = `vercel.json` rewrite config. Acknowledge in the service type taxonomy that a "service" can be a config-only artifact with no deploy step.

**M4: Migration strategy unaddressed.** Database migrations are the most dangerous part of deploys. Need explicit treatment: ordering (migrate-then-deploy vs deploy-then-migrate), the provider deploy verb should accept a `--migrate` flag or migrations are a separate step in the topology.

### Minor

**m1:** Provider tools must integrate `_log-helper` for telemetry.
**m2:** No cost visibility or stale preview cleanup — need TTL or age reporting.
**m3:** `doppler-provider` → becomes `secrets-doppler` under the new naming. No conflict with existing pattern — it IS the pattern.
**m4:** Skill nesting (`/preview` calling `/service-provision`) is a new pattern. Adopt it explicitly as a design decision: orchestration skills can invoke other skills.
**m5:** Add a minimal example (single static site → one frontend service, one DNS binding) to validate the abstraction isn't over-engineered for simple cases.

---

## 4. Relationship to Existing Patterns

**Replaces:** `_provider-resolve` v1 (flat, single-arg) → v2 (environment-aware, two-arg). Starter packs → split into provider-setup skills + app-scaffold skills. Flat provider fields in `agency.yaml` → environments section.

**Extends:** `{type}-{provider}` tool naming (already established). `_log-helper` telemetry. Skill/tool separation.

**Novel:** Topology manifest. Dependency graph resolution with subset filtering. Computed wiring via template interpolation. Orchestration skills that invoke other skills. Multi-verb provider tool interface.

**Clean break — no backwards compat needed.** Two projects in the installed base. Redesign `_provider-resolve`, `agency.yaml`, and tool naming for the two-dimensional model from the start.

---

## 5. Suggested Next Steps

1. **Finalize computed wiring design** — validate template interpolation against monofolk's actual service dependencies
2. **Build `_provider-resolve` v2** — two-arg, reads `agency.yaml` environments section
3. **Build `topology-resolve`** — reads topology.yaml + agency.yaml → concrete plan with interpolated wiring
4. **Build `compute-docker` as first provider** — implements the full verb set against Docker
5. **Prototype against monofolk's Docker topology** — three twists (full stack, folio-only, single service)
6. **Build `/preview` skill** — orchestrates topology-resolve → provision → deploy → health-check
7. **Then cloud providers** — `compute-fly`, `frontend-vercel`, `dns-cloudflare`

Validate locally first (DD-3), then extend to cloud. Monofolk is the first and only customer.

---

## Design Strengths (acknowledged)

- Three-layer lifecycle is the right core abstraction
- DD-4 (environment as binding selector) prevents topology drift
- Uniform provider verb set enables genuine provider-agnosticism
- Subset deployment via topology graph filtering avoids config sprawl
- Local-first validation is pragmatically wise
- Clean separation of "what" (topology) from "how" (providers)
