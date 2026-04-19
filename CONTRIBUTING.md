# Contributing to The Agency

Thank you for your interest in contributing to **The Agency** — a framework for AI-augmented software development. Whether you're fixing a typo, reporting a bug, improving the docs, or building a new tool, we welcome your help.

This document is the front door for community contributors. If you're looking for the deep reference on our trust and verification model, see [CONTRIBUTION-MODEL.md](agency/REFERENCE-CONTRIBUTION-MODEL.md). If you're looking for the methodology, see [agency/CLAUDE-THEAGENCY.md](agency/CLAUDE-THEAGENCY.md).

## TL;DR

1. **Fork** the repo and clone your fork
2. Create a **branch** from `main`
3. Make your changes, run the local checks (see below)
4. Open a **Pull Request** against `main`
5. **CI runs automatically** — look for green checks
6. A maintainer reviews your PR and either merges it or comments with feedback
7. Target review response: **within 2 business days**

## Code of Conduct

Participation in this project is governed by our [Code of Conduct](CODE_OF_CONDUCT.md). Be kind, be constructive, be patient. Reports of violations go to the contact listed in the Code of Conduct.

## How we think about contributions

The Agency uses a **three-ring contribution model** that matches review discipline to trust. As a community contributor, you're in **Ring 3**, which means:

- Every PR gets the **full CI validation gate** (tool tests, skill validation, smoke tests)
- A maintainer will **review with a welcoming, pedagogical tone** — we want you to succeed
- You don't need to understand our internal processes to contribute — CI and review catch everything that matters
- First-time contributors are especially welcome

Don't be intimidated by the word "framework." If your PR is one line that fixes a typo, that's a valid PR. If it's a new tool that does something cool, that's also a valid PR. All sizes are welcome.

Full detail on how the rings work: [CONTRIBUTION-MODEL.md](agency/REFERENCE-CONTRIBUTION-MODEL.md).

## Before you start

**For small changes** (typos, doc fixes, one-file bug fixes):
- Just open a PR. No issue needed. Go for it.

**For larger changes** (new tools, new skills, architectural changes, new workstreams):
- **Open an issue first** to discuss the approach. This avoids you building something we can't merge.
- We'd rather spend 10 minutes aligning on design than have you build the wrong thing.

## Development setup

The Agency is a bash-heavy framework with TypeScript and Python components. Prerequisites:

- **bash 4+** (macOS ships bash 3.2 — `brew install bash` if you're on macOS)
- **git 2.30+**
- **bats-core** for running tool tests (`brew install bats-core` or your package manager equivalent)
- **jq** for JSON processing (`brew install jq`)
- **gh** GitHub CLI (`brew install gh`)
- **Node.js 20+** and **pnpm** if you're working on TypeScript components
- **Python 3.10+** if you're working on Python tools

Clone your fork and get started:

```bash
git clone https://github.com/YOUR-USERNAME/the-agency.git
cd the-agency
```

If you're working on a subsystem that has its own dependencies, each subsystem documents its own setup in a local README.

## Running tests locally (recommended)

We encourage you to run the test suite locally before pushing. This gives you fast feedback and makes review faster.

```bash
# Run the BATS test suite (tool tests)
bats tests/tools/

# Run skill validation tests
bats tests/skills/skill-validation.bats

# Run TypeScript tests if you're working on TS components
npx vitest run
```

You don't *have* to run these locally — CI will run them for you. But local runs are faster and mean fewer round-trips on your PR.

## Making changes

### Branch naming

Use a descriptive branch name. Any format is fine, but we recommend:

- `fix/<short-description>` for bug fixes
- `feat/<short-description>` for new features
- `docs/<short-description>` for documentation changes

### Commit messages

We're relaxed about commit messages from community contributors. Our preference:

- First line is a concise summary (under 72 chars)
- Optional body explaining the *why*
- Reference related issues (`Fixes #123`)

You don't need to follow our internal commit message convention — that's for our internal worktree flow.

### Writing code

A few project conventions that will make review easier:

- **Provenance headers** on new scripts and significant modules — explain *what problem* the code solves and *how & why* you chose your approach. See examples in `agency/tools/` for the format.
- **No silent failures** — fail loudly or handle explicitly. If you suppress an error, comment why.
- **Use the dedicated tools** when available — `agency/tools/` has many utilities; prefer them over inline bash.
- **Follow existing patterns** — if there's a similar tool or skill that does something close to what you're building, match its structure.

## Opening your Pull Request

1. Push your branch to your fork
2. Open a PR against `the-agency-ai/the-agency:main`
3. Fill out the PR template — it asks for:
   - **What the PR does** (one paragraph)
   - **Why it's needed** (link to issue if applicable)
   - **Test plan** — how you tested the change
   - **Checklist** — did you update docs, did you run tests, etc.
4. Submit

The PR template is there to help you structure your submission. If something doesn't apply, write "N/A" — don't delete the section.

## What happens next — the review process

1. **CI runs immediately** on your PR. Two workflows fire for community PRs:
   - `smoke-ubuntu` — fast sanity check on a fresh Ubuntu environment (<90 seconds)
   - `fork-pr-full-qg` — full validation gate (tool tests, skill validation, smoke tests)
2. **A maintainer will respond within 2 business days** for a first review
3. The review may include:
   - **Approval** — if the PR is ready, it gets merged
   - **Feedback as PR comments** — suggestions, questions, requested changes
   - **Dispatch to another maintainer** — if a domain expert needs to weigh in
4. **You iterate based on feedback** — push new commits to the same branch, CI re-runs, reviewer re-reviews
5. **Merge** — once approved and CI is green, a maintainer merges your PR

**If CI fails:**
- Click the failed check for details
- Fix the issue locally
- Push the fix to your branch — CI re-runs automatically
- Ask for help in PR comments if you're stuck

**If review takes longer than 2 business days:**
- Ping the PR with a polite comment — we may have missed the notification
- We commit to not ghosting contributors. If we can't review in that window, we'll tell you why and give you a new ETA.

## What we care about

**We care about:**

- Changes that work and pass tests
- Clear explanations of *why* a change is needed
- Consistency with existing patterns
- Kindness and patience in discussions

**We don't care about:**

- Perfect first drafts
- Knowing our internal jargon (we'll explain what we mean if something is unclear)
- Following every convention on your first PR (we'll help you align)
- Whether your PR is "important enough" (all PRs are welcome)

## What can you contribute?

- **Bug fixes** — fix issues you encounter
- **New tools** — add utilities to `agency/tools/`
- **New skills** — add skills to `.claude/skills/`
- **New agents** — build specialized agent classes
- **Starter packs** — framework-specific conventions and templates
- **Documentation** — improve guides, examples, error messages
- **Tests** — expand test coverage
- **Workshop materials** — improve the learning on-ramp

## What if I want to be more involved?

If you find yourself contributing frequently and would like to take on more responsibility, reach out — we're planning a path for regular community contributors to graduate to higher default trust. We're not ready to formalize that yet, but we're paying attention.

## Getting help

- **Questions about the framework:** Open a GitHub issue with the `question` label
- **Stuck on a PR:** Comment on the PR, tag a maintainer
- **Security issues:** Please do NOT open a public issue. Email the contact in [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md)

## Thank you

Every contribution — from a typo fix to a new subsystem — makes the framework better. Thanks for taking the time.

---

*OFFENDERS WILL BE FED TO THE — CUTE — ATTACK KITTENS!*
