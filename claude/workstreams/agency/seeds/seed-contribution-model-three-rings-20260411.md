---
type: seed
workstream: agency
topic: Contribution Model — Three Rings of Trust
date: 2026-04-11
author: the-agency/jordan/captain
status: approved-proceed
transcript: usr/jordan/captain/transcripts/contribution-model-three-rings-20260411.md
related:
  - claude/CLAUDE-THEAGENCY.md
  - claude/docs/QUALITY-GATE.md
  - claude/tools/upstream-port
  - usr/jordan/captain/flags (flag #84 — PR tool needed)
---

# Seed: Contribution Model — Three Rings of Trust

## What is this seed?

A contribution trust framework for the-agency that separates **Internal**, **Sister Projects**, and **Community** contributors into three rings, each with distinct CI scope and review discipline. Sparked by skill validation tests that had been silently failing since the earliest days of the project, generating CI failure emails that everyone learned to ignore — a classic broken window.

This seed captures the strategic discussion that produced the framework and the action plan that follows from it. It is the foundation for a formal `CONTRIBUTION-MODEL.md` reference document, a repo-root `CONTRIBUTING.md`, and a significant rework of CI scope.

## The trigger

During the April 11 session (Day 36-37 captain session), Jordan observed:

> "We have failing test reports. A number of them. I am getting notified regularly in email."
> "These tests go back to the earliest days of the-agency. Of course they are breaking."

Investigation found:
- Tests were failing on every push to main and every PR branch since at least D35-R2 — weeks of broken CI
- All failures were the same skill validation suite (4 tests, same fixes)
- Email notifications were firing on every failure, training everyone to ignore CI emails entirely
- **Root cause:** The tests were never wired into local QG. They only ran in CI. Because the local QG didn't catch them, authors pushed broken code. Because CI emails were noise, nobody acted. The broken window stayed broken.

This led Jordan to ask the strategic question:

> "I want you to review the CI tests in light of our QG regime. What — if any — tests make sense to run on the CI?"

## The core insight (Jordan's)

> "How we treat our own PRs, where we have strong confidence in the QG process, is different from how we handle a PR from a contributor. And I think we need to think through that process. We have been letting monofolk just commit directly. Think that needs to change and it is tied to our contributor process."

**Trust is asymmetric.** CI is the trust boundary. When we fully trust that local QG ran, CI is mostly redundant. When we don't trust it, CI is the gate. The current architecture collapses the distinction — we were running the same CI for everyone, which meant either duplicating local QG (for internal, where we trusted it) or gating at the wrong place (for external, where we should have been stricter).

## The three rings

| Ring | Source | Trust Posture | Local QG | CI Scope |
|------|--------|---------------|----------|----------|
| **Ring 1: Internal** | Captain + worktree agents (devex, iscp, etc.) on the-agency | **Trust** — same processes, same players, hookify enforced | Mandatory, enforced at commit time | Smoke test only — confirm Linux parity, fresh-clone works |
| **Ring 2: Sister Projects** | Partner repos that follow our processes (monofolk, future partners) | **Trust but verify** — same processes, *different players*. We trust the QG framework they run; we verify execution because different engineers are running it. | They run our QG framework on their side | Full validation gate — verification layer for Ring 2 |
| **Ring 3: Community** | Forks, workshop students, public contributors | **Verify** — unknown players, unknown processes | Not expected | Full gate + welcoming captain review + documented CONTRIBUTING.md |

**Key principle: CI is the verification layer. The deeper the verification needed, the more CI runs. Local QG depth stays the same across all rings — what changes is how much we trust that it actually ran as designed.**

**Ring 2 is "trust but verify," not "partner but different."** Monofolk follows our processes — the Valueflow, the QG regime, the three-bucket triage, hookify rules, the commit discipline. They have the same methodology. What's different is the *players* executing it — a different captain, different worktree agents, different engineers. We trust the processes; we verify the execution because we can't see their local QG runs. This is federation, not partnership.

## Why this matters for monofolk (Ring 2 decision)

Monofolk has been pushing directly to the-agency main as if they were internal. They are not. They are a **sister project that follows our processes but runs them with different players**:

- **Same processes:** They use the Valueflow, the QG regime, three-bucket triage, hookify rules, the commit discipline. The methodology is shared.
- **Different players:** Their captain is not our captain. Their worktree agents are not our worktree agents. Their engineers are not our engineers.
- **Different local QG runs:** We can't see them. We can't verify they ran. We can't know what their specific red-green cycle caught.

Calling them "internal" is a fiction. The right model is **Ring 2: Trust but Verify**. Direct push must stop. All monofolk contributions come via PR through the existing `upstream-port` tool. The full CI gate runs on monofolk PRs as the **verification layer** — we trust the processes they're running, we verify the execution.

**This is kind to monofolk.** Right now, if monofolk's captain commits a subtle bug that our QG would catch, it lands on our main and becomes our problem to deal with after the fact. Under Ring 2, they get fast feedback at PR time — the verification gate catches issues before landing, and they get a clean signal to fix. Partner-trust SLA means fast review turnaround and "yes by default" disposition for well-formed PRs.

**Symmetric:** We do the same when contributing upstream to monofolk — PR through their review process, respect their gate. This is federation with reciprocal verification, not hierarchy.

## Why this matters for the workshop and community

The workshop is Monday, April 13 at Republic Polytechnic. 22 invites sent. Confirmed attendees include Kiren Kumar (DCEO IMDA) sending two officers as observers with intent to upskill many more. Workshop students will be the first community contributors to the-agency at scale.

Strategic plan: **kill the-agency-starter and redirect users to the main repo**. This makes the main repo the front door for all new users. The first thing a new user sees when they want to give something back is the contribution process. That process needs to be a first-class experience — not a bolted-on afterthought.

Required artifacts before the workshop:
- **CONTRIBUTING.md** at repo root — the contributor's front door
- **Contributor PR template** — forces scope declaration, test plan
- **Code of conduct** — open source norms
- **Maintainer response SLA** — committed turnaround so contributors aren't ghosted
- **Captain review skill tuned for external PRs** — welcoming tone, not internal-terse tone
- **Fork-PR CI gate** — automated validation for untrusted PRs
- **`CONTRIBUTION-MODEL.md` reference doc** — the full three-ring framework

## CI rework — what goes, what stays

### DELETE from CI (belongs in local QG)

The following tests currently run in CI and should be moved to `commit-precheck` so they fire at commit time, not 5+ minutes after push:

- `tests/skills/skill-validation.bats` — caught the author, not the email 8 hours later
- `tests/tools/iscp-*.bats` — tool unit tests
- `tests/tools/agent-identity.bats`
- `tests/tools/dispatch*.bats`
- `tests/tools/flag.bats`
- `tests/tools/iscp-migrate.bats`

These total roughly 224 tests. All of them should run locally on every commit, not in CI.

### KEEP in CI (unique value)

Only three things belong in CI:

1. **`smoke-ubuntu`** (every push) — fresh clone on Ubuntu, `agency init` in /tmp, `agency verify`, 5 key tools execute `--help`, hookify rules fire correctly. Total runtime target: <90 seconds.
2. **`fork-pr-full-qg`** (PRs from forks only) — full BATS suite + skill validation + tool tests. The contributor gate. Triggered by `github.event.pull_request.head.repo.full_name != github.repository`.
3. **`sister-project-pr-gate`** (PRs from branches matching sister-project patterns) — full validation, same as fork gate. Enforces Ring 2 discipline on partner PRs.

### Email notifications

Disable global failure email notifications. Replace with:
- **ci-monitor script** for the captain's Monitor tool — checks CI status on main, only fires when there's a genuine failure to act on, no email noise
- **Branch failure handling** — branch failures go to the dispatch queue, not email
- **Main failure = escalation** — if main goes red, it fires a high-priority dispatch/flag, not a silent email

## Action plan (order of operations)

The following sequence applies the seed:

1. ✅ **Fix the immediate broken window** — PR #76 (D36-R2) merged. Skill validation tests pass. Main is green.
2. **Document the three rings** — write `claude/docs/CONTRIBUTION-MODEL.md` as the reference.
3. **Draft `CONTRIBUTING.md`** at repo root — the contributor's front door. References the three-ring model.
4. **Send monofolk transition dispatch** — tell their captain the Ring 2 transition is starting, with a clear deadline and migration path via `upstream-port`.
5. **Wire branch protection on main** — AFTER monofolk is informed. Disallow direct push for all but an explicit allowlist. All changes via PR.
6. **Rework CI workflows** — new `smoke-ubuntu.yml`, new `fork-pr-full-qg.yml`, new `sister-project-pr-gate.yml`. Delete the legacy `Tests` workflow that was running the full BATS suite.
7. **Move skill-validation into commit-precheck** — so the next time a skill is wrong, the commit blocks immediately. Red-green at author time.
8. **Build `ci-monitor` script** for the Monitor tool — replaces email notifications.
9. **Disable email notifications** in GitHub repo settings.
10. **Set up code of conduct** — standard open source doc.
11. **Create contributor PR template** — `.github/PULL_REQUEST_TEMPLATE.md`.
12. **Tune captain review skill for external PRs** — welcoming tone, explicit "first-time contributor" detection.

## Open questions (deferred)

### Q3: Ring 2.5 — vetted external contributors?

Workshop students start as Ring 3. Some will become regulars — contributing frequently, learning our standards, earning trust. Do we need an intermediate **Ring 2.5: Trusted External Contributor** status for people who graduate out of Ring 3 but aren't (yet) Ring 1?

Possible shape:
- Lower CI burden than Ring 3 (maybe smoke + targeted gates instead of full)
- Named in a CODEOWNERS-like registry
- Reviewed by captain with higher default-trust posture
- Still can't direct-push; still requires PR

**Deferred for later.** This is a problem we'll have once we have enough community contributors to matter — not a Day 1 problem. Park it until we actually have a candidate.

### CI monitoring and escalation

The Monitor tool pattern (already used for dispatches and changelog) can replace email notifications for CI. A `ci-monitor` script would poll CI status for main and for open PRs, staying silent when everything is green and emitting structured output only when something actionable happens. This needs design work during the application phase.

### Branch protection specifics

Exactly which branches are protected, which actors are in the allowlist, and how the-agency's own captain (which commits coordination artifacts to main) interacts with protection rules — needs careful design so we don't lock ourselves out of our own coordination workflow.

## Decisions captured

1. **Three-ring model approved** as the contribution trust framework. Ring 1 Internal, Ring 2 Sister Projects, Ring 3 Community.
2. **Monofolk moves to Ring 2** — direct push ends, PRs via `upstream-port`, full CI gate on their PRs. Partner-trust SLA for fast review.
3. **CI scope drastically reduced** — only smoke-ubuntu, fork-pr-full-qg, sister-project-pr-gate. Legacy BATS-in-CI is deleted.
4. **Tests move to local QG** — skill-validation, tool unit tests, ISCP tests all run in commit-precheck, not CI.
5. **Email notifications disabled** — replaced with Monitor-tool-based ci-monitor for the captain.
6. **Contribution workflow becomes a first-class experience** — required before workshop.

## Provenance

- **Discussion transcript:** `usr/jordan/captain/transcripts/contribution-model-three-rings-20260411.md`
- **Triggering PR:** #76 (D36-R2) — fix for broken skill validation tests
- **Triggering flag:** #84 — PR tool needed (captain-only enforcement of PR-first workflow)
- **Related seed:** workshop preparation seeds (workshop-outline, workshop-setup-guide)

## Apply

This seed is **approved to proceed**. The action plan above is the execution order. Captain begins applying immediately after this seed is committed.

---

*OFFENDERS WILL BE FED TO THE — CUTE — ATTACK KITTENS!*
