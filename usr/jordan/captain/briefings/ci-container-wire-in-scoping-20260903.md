# Scoping brief — wiring the container gate into CI

**For:** principal discussion (item ③ of the 1→2→③ plan). **Not** an execution plan yet — this surfaces the decision space so we can scope it together.

**Date:** 2026-09-03 · **Author:** captain · **Status:** for-discussion

---

## TL;DR

The container test-isolation arc (#42) landed locally on **Apple containers** (v46.44/46.47). Two things are still open, and they're entangled:

1. **The Docker backend is routing-verified only** — never run live. Its natural proving ground is Linux CI (GitHub runners are Linux + ship Docker).
2. **CI doesn't actually run our tests yet.** `smoke.yml` is a **placeholder that passes unconditionally** — the real battery (`bats src/tests/tools/`, `agency verify`, lint) is still tracked as "pending."

So "wire the container into CI" is really **two decisions**: (a) *build out the smoke battery at all*, and (b) *whether that battery runs bats directly on the runner or inside the container*.

---

## Current CI state (what's actually there)

| Workflow | Runner | What it does |
|---|---|---|
| `smoke.yml` | ubuntu-latest | **Placeholder** — echoes pass. Required status context; real battery pending. |
| `bash32-probe.yml` | macos-latest | git-captain bats under bash 3.2 (real tests, narrow scope) |
| `auto-release`, `release-tag-check`, `release-version-precheck` | ubuntu-latest | Release plumbing — not test execution |

**The load-bearing fact:** the required `smoke` gate is green-by-fiat today. Nothing blocks a PR on the 1800+ bats tests. That's the real gap; the container is a sub-question inside it.

---

## The nuance that reframes this

GitHub runners are **ephemeral and disposable** — a fresh VM per job. So running `bats src/tests/tools/` *directly on the runner* is **already isolated** by disposal. The container's core value proposition (isolate the test run from a dirty/stateful host) is the *local* pain point, not the CI one.

That means the container's value **in CI** is narrower and specific:

- **Proves the Docker backend live** — the one untested path in the whole #42 arc.
- **Local/CI environment parity** — same OCI image locally and in CI, so "works in the container on my machine" == "works in CI."
- **Exercises the container gate end-to-end** — the abstraction, the overlay, the clone-into-container all get real CI coverage.

It does **not** meaningfully add isolation over plain runner-bats. Worth being honest about that when we weigh cost.

---

## Options

### Option A — Build the smoke battery on the runner directly (no container)
Replace the placeholder with real steps: `bats src/tests/tools/`, `agency verify` on a fresh init, lint. Runs bats straight on ubuntu.
- **Pro:** Closes the *actual* gap (CI runs our tests). Simplest. No image build overhead (~fast). Runner disposal already gives isolation.
- **Con:** Docker backend stays unproven. No local/CI image parity.

### Option B — Build the battery **through the container** (`test-run --isolated`)
Smoke job installs Docker (preinstalled on ubuntu), builds/pulls the OCI image, runs `test-run --isolated`.
- **Pro:** Proves the Docker backend live. Full parity. Exercises the gate end-to-end.
- **Con:** Image build adds ~30–60s/run (unless we publish to ghcr.io and pull). The isolation benefit is marginal over A (runner already disposable). More moving parts to keep green.

### Option C — Both, as **parallel jobs** (recommended starting point for discussion)
One job runs bats directly (fast feedback, Option A). A second job runs `test-run --isolated` on Docker (proves the backend, Option B). They run concurrently.
- **Pro:** Fast signal AND live Docker proof. The container job can be **non-required** at first (informational) so a container-infra flake never blocks a PR while we build confidence, then promoted to required once stable.
- **Con:** Two jobs to maintain; roughly 2× CI minutes on the test path.

---

## Open questions to decide together

1. **Do we build the smoke battery now, or is that its own scoped piece of work?** (It's arguably the bigger fish — the container is riding along.)
2. **Is proving the Docker backend a goal we want CI to own**, or is "routing-verified + Apple-live" enough and Docker stays best-effort?
3. **Image strategy if we go container-in-CI:** build per-run (simple, slower) vs. publish to `ghcr.io` and pull (a publish pipeline, faster runs)?
4. **Required vs. informational** for the container job at first — gate PRs on it immediately, or shadow-run until proven stable?
5. **Scope boundary:** is this one workstream ("CI build-out") with the container as a sub-task, or do we keep #42's container work separate from the smoke-battery work?

---

## Captain's read (for reaction, not decision)

- The **honest gap is the placeholder smoke gate**, not the container. I'd frame the primary work as "build the real smoke battery" (Option A is table stakes).
- The container belongs in CI as a **parallel, initially-informational Docker job** (Option C) — that's the cheapest way to get the live Docker proof we've been deferring, without letting container-infra flakes block PRs before they've earned trust.
- Image-per-run first (simplest); graduate to ghcr.io only if run-time becomes annoying.

Reacting to that read — or redrawing the option space — is the discussion.
