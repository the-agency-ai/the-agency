# Contribution Model — Three Rings of Trust

The-agency uses a **three-ring contribution model** that matches CI discipline to the trust relationship with the contributor. The deeper the verification needed, the more CI runs. Local QG depth stays the same — what changes is how much we trust that it actually ran as designed.

> **Core principle:** CI is the verification layer. Trust is asymmetric. Treat contributors according to the trust posture, not a one-size-fits-all gate.

## The Three Rings

| Ring | Who | Trust Posture | Local QG | CI Scope | Process Gate |
|------|-----|---------------|----------|----------|--------------|
| **Ring 1: Internal** | Captain + worktree agents on the-agency itself | **Trust** — same processes, same players, hookify enforced | Mandatory at commit time | Smoke test only | Local QG is the gate; CI is parity check |
| **Ring 2: Sister Projects** | Partner repos that follow our processes with their own players (monofolk, future partners) | **Trust but verify** — same processes, *different players* | They run our QG framework on their side | Full validation gate | CI is the verification layer; captain review on merge |
| **Ring 3: Community** | Forks, workshop students, public contributors | **Verify** — unknown players, unknown process adherence | Not expected | Full gate + welcoming review | CI + captain review + CONTRIBUTING.md |

## Ring 1: Internal

**Who belongs here:** The captain and all worktree agents operating on this repository under the same captain's direction. Devex, iscp, and any future agents that follow the-agency's captain workflow.

**Trust basis:** Same processes (Valueflow, QG, three-bucket triage, hookify), same players (this captain's worktree agents), same commit discipline (`git-safe-commit` wrapper, enforced hookify rules, pre-commit quality gates). Everything that matters is enforced at the commit boundary by tools we control.

**What this means in practice:**

- **Local QG is the gate.** `commit-precheck` runs tool unit tests, skill validation, and other scoped checks at every commit. `/pr-prep` runs the full QG before PR. `/iteration-complete` and `/phase-complete` add deeper verification at boundary commits.
- **CI is a parity check, not a gate.** It confirms that what passed on the captain's macOS dev environment also passes on a fresh Ubuntu runner. CI scope: `smoke-ubuntu` only — fresh clone, `agency init`, `agency verify`, 5 key tool `--help` invocations, hookify rules fire correctly. Target runtime: <90 seconds.
- **Review is lightweight.** Captain's own commits go directly to main for coordination artifacts (handoffs, dispatches, seeds, config). Worktree agent PRs are reviewed by captain via `/captain-review` and dispatches.
- **Email notifications off.** Captain uses the `ci-monitor` tool via Monitor for real-time awareness without email noise.

**Permission model:** Captain can push directly to main for coordination paths (handoffs, dispatches, config, seeds). All other changes go through PR. Worktree agents never push to main — they land via `/phase-complete` or captain PR-merge.

## Ring 2: Sister Projects

**Who belongs here:** Partner repositories that follow the-agency's processes but are operated by a different captain and a different team. Current example: **monofolk**. Future examples: any repo that adopts the Valueflow and QG regime under its own captain.

**Trust basis (the refinement that matters):** Monofolk doesn't have a *different* QG — they have the **same processes with different players**. Same Valueflow, same QG regime, same three-bucket triage, same hookify rules, same commit discipline. What's different is *who* is running them: a different captain, different worktree agents, different engineers.

We trust the processes they're running, because they're our processes. **We verify the execution because different players are running them and we can't see their local QG runs.** That's the "trust but verify" posture.

This is **federation with reciprocal verification**, not hierarchy. When monofolk contributes to the-agency, we verify. When the-agency contributes to monofolk, they verify. Each side gates the other side's contributions with their own CI because neither side can see the other's local QG.

**What this means in practice:**

- **No direct push.** All sister-project contributions arrive via Pull Request, typically through the `upstream-port` tool which automates the fork → branch → PR flow.
- **Full CI gate runs on Ring 2 PRs.** `fork-pr-full-qg` or `sister-project-pr-gate` runs the complete BATS suite, skill validation, tool tests. This is the verification layer — it's not distrust of the framework, it's verification of execution by a different team.
- **Captain review with partner SLA.** Well-formed PRs get fast turnaround (same-day or next-day), "yes by default" disposition, and findings delivered as PR comments or dispatches. The posture is "welcome, let me help you ship this" — not "prove it to me."
- **Symmetric:** We follow the same pattern when contributing to sister projects.

**Permission model:** Sister project maintainers do not have direct push. Their PRs are built through `upstream-port` (or manually via fork + PR) and reviewed by the-agency captain before merge.

### How to transition a repo into Ring 2

1. The sending side adopts the Valueflow and QG regime (or demonstrates equivalent process)
2. A dispatch is sent announcing the transition, with a migration deadline
3. The sending side switches from direct push to `upstream-port`-based PRs
4. Branch protection activates on the receiving side after the migration deadline
5. Reciprocal arrangement on the other side — symmetry is the norm

## Ring 3: Community

**Who belongs here:** Everyone else. Fork-based contributors, workshop students, first-time drop-ins, anyone who clicks "Fork" on GitHub and wants to give something back.

**Trust basis:** **Verify.** We don't know who they are, we don't know if they've even read the docs, we don't know if they ran any local checks. That's not a problem — it's the normal open-source contributor experience. We welcome them, we provide a clear on-ramp, and we verify their contributions through CI and captain review.

**What this means in practice:**

- **CONTRIBUTING.md is the front door.** Every community contributor is pointed at `CONTRIBUTING.md` at the repo root, which explains the fork → PR flow, what "good" looks like, how to run local tests if they want fast feedback, the response SLA, and how captain review works.
- **Full CI gate runs on every fork PR.** `fork-pr-full-qg` workflow triggered by `github.event.pull_request.head.repo.full_name != github.repository`. Same validation as Ring 2 — because the trust posture is actually *weaker*, and the gate is the only thing protecting main.
- **Captain review with welcoming tone.** First-time contributors get a different review tone than internal PRs: welcoming, explanatory, pedagogical. Findings come as PR comments via `/pr-respond`. The posture is "we want you to succeed, here's what needs to change."
- **Code of conduct enforced.** Standard open-source norms — `CODE_OF_CONDUCT.md` at the repo root, contact info for violations.
- **Response SLA.** Maintainer response within 2 business days for first review. No ghosting.

**Permission model:** Forks cannot push to main. All community contributions arrive as PRs from forks. CI runs on PR creation and PR update.

### How someone graduates out of Ring 3

Deferred. Once we have community contributors at scale, we may introduce a **Ring 2.5: Trusted External Contributor** for individuals who have demonstrated consistent quality and earned heightened default trust. The shape is not designed yet — we'll design it when we have a real candidate.

## CI scope by ring

| CI Workflow | Triggers On | Ring | What it validates |
|-------------|-------------|------|-------------------|
| `smoke-ubuntu` | Every push to main, every PR | All rings | Fresh clone + `agency init` + `agency verify` + key tool smoke tests. <90s runtime. |
| `sister-project-pr-gate` | PRs from branches matching sister-project patterns | Ring 2 | Full BATS suite + skill validation + tool tests |
| `fork-pr-full-qg` | PRs from forks (`head.repo.full_name != base.repo.full_name`) | Ring 3 | Same as Ring 2 — full validation |

Ring 1 internal PRs trigger only `smoke-ubuntu`. The full validation suite stays local in `commit-precheck` and `/pr-prep` — Ring 1's "trust" posture means we trust the local run.

## What does NOT belong in CI

Anything that duplicates local QG without adding environment/verification value:

- Tests that the author already ran in `commit-precheck` 30 seconds before pushing
- Tests that run on the same macOS environment as the author's dev machine
- Validation that's enforced by hookify at commit time
- Anything that doesn't add a signal the author couldn't see locally

**The broken-window anti-pattern:** A test that runs only in CI, emails failures, and never gets fixed. This is how we ended up with weeks of failing skill validation tests and email notifications everyone learned to ignore. The fix: move the tests to local QG where the author sees them immediately, delete them from CI where they generate noise.

## The permission model in one picture

```
        ┌──────────────────────────────────────────┐
        │  Ring 3: Community / Workshop            │
        │  - Fork + PR (never direct push)         │
        │  - Full CI gate = verification           │
        │  - Captain review (welcoming tone)       │
        │  - CONTRIBUTING.md is the front door     │
        └──────────────────────────────────────────┘
            ┌──────────────────────────────────┐
            │  Ring 2: Sister Projects          │
            │  - upstream-port → PR             │
            │  - Full CI gate = verification    │
            │  - Captain review (partner SLA)   │
            │  - Trust the processes,           │
            │    verify the players             │
            └──────────────────────────────────┘
                ┌────────────────────────┐
                │  Ring 1: Internal       │
                │  - Captain + worktrees  │
                │  - Local QG enforced    │
                │  - Smoke CI only        │
                │  - Push to main OK for  │
                │    coordination paths   │
                └────────────────────────┘
```

## References

- **Seed:** `agency/workstreams/agency/seeds/seed-contribution-model-three-rings-20260411.md`
- **Quality Gate Protocol:** `agency/REFERENCE-QUALITY-GATE.md`
- **Code Review Lifecycle:** `agency/REFERENCE-CODE-REVIEW-LIFECYCLE.md`
- **Agency Methodology:** `agency/CLAUDE-THEAGENCY.md`
- **Contributor Front Door:** `CONTRIBUTING.md` (at repo root)
- **Code of Conduct:** `CODE_OF_CONDUCT.md` (at repo root)
- **Upstream port tool:** `agency/tools/upstream-port` — automates Ring 2 PR creation
- **CI monitor tool:** `agency/tools/ci-monitor` — replaces email notifications for captain

## Changelog

- **2026-04-11** — Initial version. Three rings defined: Internal, Sister Projects (trust but verify), Community. Monofolk transitions to Ring 2 starting this date.

---

*OFFENDERS WILL BE FED TO THE — CUTE — ATTACK KITTENS!*
