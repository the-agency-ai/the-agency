<!-- What Problem: The three-ring contribution model requires branch protection on
main to enforce PR-only policy. Without it, direct pushes bypass the CI gate.
This guide documents the setup — to be wired AFTER monofolk is informed.

How & Why: Step-by-step for the principal to configure GitHub branch protection
rules. Designed to work with the captain's coordination workflow (captain commits
coordination artifacts to main via local git, then pushes via /sync).

Written: 2026-04-12 during devex Day 35 — contribution model rollout -->

# Branch Protection Setup for Main

Configure GitHub branch protection to enforce the PR-only policy from the three-ring contribution model.

**IMPORTANT:** Wire this AFTER monofolk has been informed of the Ring 2 transition. Otherwise their next push will be rejected without warning.

## Settings

Go to **github.com/the-agency-ai/the-agency** > **Settings** > **Branches** > **Add branch protection rule**

### Branch name pattern
```
main
```

### Required settings

| Setting | Value | Why |
|---------|-------|-----|
| **Require a pull request before merging** | ON | Enforces PR-only for all external contributors |
| **Required approvals** | 1 | Captain or principal must approve |
| **Dismiss stale PR reviews** | ON | Force re-review after new commits |
| **Require status checks to pass** | ON | CI gate must pass before merge |
| **Required status checks** | `Smoke Test (Ubuntu) / smoke` | The universal smoke test |
| **Require branches to be up to date** | OFF | Avoids merge queue bottleneck |
| **Restrict who can push** | ON | Only allowlisted actors can push directly |

### Push allowlist

These actors can push directly to main (bypassing PR requirement):

| Actor | Why |
|-------|-----|
| `jordandm` | Principal — emergency fixes, coordination |
| `jordan-of` | Principal alternate GitHub identity |

**No bot accounts.** The captain agent commits locally and pushes via `/sync` through the principal's git identity. The principal's GitHub account is the push identity.

### Do NOT enable

| Setting | Why NOT |
|---------|---------|
| **Require signed commits** | Framework commits from Claude Code don't have GPG keys |
| **Require linear history** | We use merge, not rebase |
| **Include administrators** | Principal needs escape hatch for emergencies |
| **Lock branch** | Would block all pushes including allowlisted |

## Fork PR behavior

When branch protection is on with required status checks:
- Fork PRs trigger the `fork-pr-full-qg` workflow automatically
- The status check must pass before the PR can be merged
- This is the Ring 3 gate

## Sister project PR behavior

When monofolk creates a PR via `upstream-port`:
- The branch name starts with `upstream-port/`
- This triggers the `sister-project-pr-gate` workflow
- The status check must pass before merge
- This is the Ring 2 gate

## Verification

After enabling:
1. Try `git push origin main` from a non-allowlisted account — should be rejected
2. Try creating a PR from a fork — should trigger `fork-pr-full-qg`
3. Try `/sync` from captain session as jordandm — should succeed (allowlisted)
4. Verify the `Smoke Test (Ubuntu) / smoke` check appears as required on PRs

## Rollback

If branch protection causes issues:
1. Go to **Settings** > **Branches** > **main** rule
2. Click **Delete** to remove all protection
3. Investigate and re-enable with corrected settings

The allowlist and required checks can be adjusted without deleting the entire rule.
