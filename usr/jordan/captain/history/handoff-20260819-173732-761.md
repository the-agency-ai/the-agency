---
type: session
agent: the-agency/jordan/captain
date: 2026-08-19T04:30
trigger: compact-container-isolation-42
branch: container-test-isolation
mode: continuation
next-action: |
  MAKE IT SO — continue the container test-isolation build (#42), driving the
  small steps WITH the principal (they approved "your call — small steps").
  Everything is checkpointed on branch container-test-isolation (commit 83217224),
  Apple `container` is installed + its service RUNNING, image built, mechanism
  PROVEN. Resume at step (2): run the WHOLE bats suite inside the container via
  `./agency/tools/container-test-run` (no args) to surface any tool the Dockerfile
  is missing (add to agency/containers/test-runner/Dockerfile), then the other
  steps below. Do NOT re-litigate container-vs-in-process — that's decided
  (container substrate); do NOT conflate CI with GitHub Linux runners.
---

# Captain handoff — container test-isolation (#42), mid-build (post-compact)

## Immediate next action: "Make it so" — the small steps (principal-approved)
Drive these WITH the principal, small commits, on branch `container-test-isolation`:
1. **Working-tree mode** — runner currently tests COMMITTED HEAD (`git clone /src /work`).
   Add a mode that tests the working tree (copy tracked+untracked, EXCLUDE
   node_modules + .claude/worktrees), so it tests uncommitted changes.
2. **Run the WHOLE suite in-container** (DO THIS FIRST) — `./agency/tools/container-test-run`
   (no args → runs bats:all set). Surfaces missing image deps; add them to the Dockerfile, rebuild.
3. **Wire it in** — `test-run --isolated` (or make isolated the default locally).
4. **Prove the Docker backend** — `CONTAINER_PROVIDER=docker ./agency/tools/container-test-run ...`
   (Docker IS installed but its DAEMON IS DOWN — needs Docker Desktop started first).
5. **Land it** — QG + commit + PR (it's a WIP checkpoint now, not QG'd/landed).

## What's built (branch container-test-isolation, checkpoint 83217224, mirrored to src/)
- **agency/tools/lib/_container-runtime** — OCI backend ABSTRACTION. Functions:
  `container_backend` (→apple|docker), `container_available`, `container_run <img> -- <cmd>`.
  Backend from agency.yaml `container.provider` (auto|apple|docker); env CONTAINER_PROVIDER
  overrides. Follows the DevEx `_provider-resolve` pattern (sourced/silent/bash-3.2).
- **agency/tools/container-test-run** — the runner: mount repo READ-ONLY → `git clone` to
  writable /work in a throwaway container → run bats there → discard. Host structurally protected.
- **agency/containers/test-runner/Dockerfile** — alpine:3.20 + bash git bats jq python3 coreutils findutils grep sed gawk. Image tag: `the-agency-test-runner:latest`.
- **agency.yaml** — new `container:` provider section (next to `preview:`).

## Environment state (this machine: Apple Silicon, macOS 26.2)
- Apple `container` v1.2.2 INSTALLED (brew install container). Service RUNNING
  (`container system start` done, kata guest kernel installed). Image built.
- Docker v29.2.1 installed but DAEMON NOT REACHABLE (the "cannot connect to daemon" pain).
- PROVEN: git tag created inside the container did NOT reach host (620→620, no proof tag);
  `container-test-run src/tests/tools/agency-version.bats` → all green in-container.

## The real goal (do not regress on these — principal corrected me 3×)
- Apple Containers is a **SUBSTRATE decision**, not a #42 fix: everywhere we use Docker
  + new areas are candidates. Build an **ABSTRACTION supporting BOTH Docker and Apple
  Containers** (done: _container-runtime). Drive WITH the principal — NO separate workstream.
- **CI = Continuous Integration (the practice), NOT "GitHub Linux runners."** It can run on
  Apple Silicon. Don't repeat that conflation.
- The pain is **LOCAL persistence** — local machine persists so test damage accumulates;
  CI runners are ephemeral (self-isolating by disposal). A container is a **structural
  backstop** (doesn't depend on tests being written correctly, which they keep not being).
- #42's origin was the planned "docker-test"; Apple Containers is the better runtime on Apple Silicon.
- Candidate register (for later): test isolation (#42, in progress), devex service composition,
  starter-pack prototypes (nextjs/nestjs), app builds (mdpal/mock-and-mark/mdslidepal),
  agency-init fresh-install verification, daemonless dev ergonomics.

## Session context / what shipped before this
- **PR #480 / v46.43 LANDED**: bats:all 247→0 (tools/agents/docs fixture repair) + #144 hookify
  canary harness. Local main reconciled to v46.43.
- Flags filed: #256 (tool-create, done), #257 (src/agency hook drift), #258 (3 skipped backlog
  probes #181/#205/#396), #259 (agency init README-install latent bug), #260 (release-bug
  pollution tags — **actually 620 local tags**, need captain `git-captain tag` sweep; verify
  not pushed first), #262 (git-safe-commit `git add -A` footgun).
- **#42 research brief** at usr/jordan/captain/briefings/apple-containers-test-isolation-42-20260818.md
  — its CONCLUSION IS NOW STALE (it argued in-process over Apple Containers; the principal's
  decision reversed to container-substrate-with-abstraction). REWRITE its conclusion when convenient.

## On resume
1. `/compact-resume`.
2. Execute next-action: `./agency/tools/container-test-run` (whole suite in-container) → fix image gaps → then steps 1,3,4,5. Confirm each small step with the principal (drive WITH them).

— captain. Container test-isolation proven; making it so.

*OFFENDERS WILL BE FED TO THE — CUTE — ATTACK KITTENS!*
