# Knowledge: GitHub CI

Context for agents working with this pack.

## Tech Stack

- **CI System:** GitHub Actions
- **Runner:** ubuntu-latest
- **Package Manager:** pnpm 9
- **Node:** v22 LTS

## Workflow Structure

```
.github/
  workflows/
    ci.yml              # Main CI pipeline (test, lint, build)
    pr-check.yml        # PR validation
    release.yml         # Release automation
```

### CI Pipeline (ci.yml)

```yaml
name: CI
on:
  push: [main] # Runs on push to main
  pull_request: [main] # Runs on PRs to main

jobs:
  build:
    steps:
      - checkout # Get code
      - setup pnpm # Install pnpm
      - setup node # Install Node 22, setup cache
      - install # pnpm install --frozen-lockfile
      - lint # pnpm lint
      - typecheck # tsc --noEmit
      - build # pnpm build
      - test # pnpm test
```

### PR Check (pr-check.yml)

Validates PR titles and commit messages follow conventions:

```yaml
name: PR Check

on:
  pull_request:
    types: [opened, synchronize, reopened]

jobs:
  validate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0

      - name: Check PR title format
        env:
          TITLE: ${{ github.event.pull_request.title }}
        run: |
          # Allow Agency format: workstream/agent: message
          if [[ "$TITLE" =~ ^[a-z-]+/[a-z-]+:.*$ ]]; then
            exit 0
          fi
          # Allow conventional commits: type(scope): message
          if [[ "$TITLE" =~ ^(feat|fix|docs|chore|refactor|test)(\(.+\))?:.*$ ]]; then
            exit 0
          fi
          echo "PR title must follow: workstream/agent: message OR type(scope): message"
          exit 1

      - name: Validate commit messages
        run: |
          while IFS= read -r msg; do
            if [[ ! "$msg" =~ ^[a-z-]+/[a-z-]+:.*$ ]] && \
               [[ ! "$msg" =~ ^(feat|fix|docs|chore|refactor|test)(\(.+\))?:.*$ ]] && \
               [[ ! "$msg" =~ ^Merge ]]; then
              echo "Invalid commit: $msg"
              exit 1
            fi
          done < <(git log --format="%s" origin/main..HEAD)
```

### Release Automation (release.yml)

```yaml
name: Release

on:
  push:
    tags:
      - 'v*'

jobs:
  release:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Install pnpm
        uses: pnpm/action-setup@v4
        with:
          version: 9

      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: '22'
          cache: 'pnpm'

      - name: Install and build
        run: |
          pnpm install --frozen-lockfile
          pnpm build

      - name: Create GitHub Release
        uses: softprops/action-gh-release@v1
        with:
          generate_release_notes: true
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

---

## Pre-commit Hooks (Husky)

### Setup

```bash
pnpm add -D husky lint-staged
pnpm exec husky init
```

### .husky/pre-commit

```bash
#!/bin/sh
. "$(dirname "$0")/_/husky.sh"

pnpm exec lint-staged
```

### .husky/commit-msg

Validates commit message format (Agency or conventional commits):

```bash
#!/bin/sh
. "$(dirname "$0")/_/husky.sh"

commit_msg=$(cat "$1")

# Allow Agency format: workstream/agent: message
if echo "$commit_msg" | head -1 | grep -qE "^[a-z-]+/[a-z-]+: "; then
    exit 0
fi

# Allow conventional commits: type(scope): message
if echo "$commit_msg" | head -1 | grep -qE "^(feat|fix|docs|chore|refactor|test|release)(\(.+\))?: "; then
    exit 0
fi

# Allow merge commits
if echo "$commit_msg" | head -1 | grep -qE "^Merge "; then
    exit 0
fi

echo "ERROR: Commit message must follow format:"
echo "  workstream/agent: message (Agency format)"
echo "  type(scope): message (Conventional commits)"
exit 1
```

### lint-staged.config.js

```javascript
module.exports = {
  '*.{js,jsx,ts,tsx}': ['eslint --fix', 'prettier --write'],
  '*.{json,md,yml,yaml}': ['prettier --write'],
};
```

---

## Commit Message Validation

The Agency uses a specific commit message format:

```
workstream/agent: type(scope): message
```

**Examples:**

- `housekeeping/captain: feat(tools): add new utility`
- `web/frontend: fix(auth): resolve login issue`
- `analytics/pipeline: docs: update API reference`

**Also accepted:** Standard conventional commits (`feat(scope): message`)

---

## Branch Protection

### Recommended Settings (GitHub)

**Branch:** `main`

| Setting                            | Value                |
| ---------------------------------- | -------------------- |
| Require pull request reviews       | Yes (1 reviewer)     |
| Require status checks              | Yes                  |
| Required checks                    | `build`, `validate`  |
| Require branches to be up to date  | Yes                  |
| Require signed commits             | Optional             |
| Include administrators             | Yes                  |

### Branch Naming Convention

```
feature/ISSUE-123-short-description
fix/ISSUE-456-bug-description
docs/update-readme
chore/dependency-updates
```

---

## Common Patterns

### Add Environment Variables

```yaml
env:
  NEXT_PUBLIC_API_URL: ${{ secrets.API_URL }}
```

### Run on Specific Paths

```yaml
on:
  push:
    paths:
      - 'src/**'
      - 'package.json'
```

### Matrix Builds

```yaml
strategy:
  matrix:
    node: [20, 22]
steps:
  - uses: actions/setup-node@v4
    with:
      node-version: ${{ matrix.node }}
```

### Custom Cache

```yaml
- name: Cache build artifacts
  uses: actions/cache@v4
  with:
    path: |
      .next/cache
      node_modules/.cache
    key: ${{ runner.os }}-build-${{ hashFiles('**/pnpm-lock.yaml') }}
    restore-keys: |
      ${{ runner.os }}-build-
```

---

## Secrets Management

### Required Secrets

| Secret         | Purpose                            |
| -------------- | ---------------------------------- |
| `GITHUB_TOKEN` | Auto-provided by GitHub            |
| `NPM_TOKEN`    | Publishing to npm (if applicable)  |
| `VERCEL_TOKEN` | Deployment (see Vercel starter)    |

---

## Agent Instructions

1. **Check CI before merge** - `gh run list`
2. **Fix CI failures locally** - Run same commands
3. **Don't skip CI** - `[skip ci]` only for docs

## Troubleshooting Guide

| Issue             | Solution                           |
| ----------------- | ---------------------------------- |
| Timeout           | Add `timeout-minutes: 30`          |
| Cache miss        | Check pnpm-lock.yaml committed     |
| Permission denied | Check `permissions:` block         |
| pnpm not found    | Ensure pnpm/action-setup@v4 runs first |

---

## Quick Start Checklist

- [ ] Run `./claude/starter-packs/github-ci/install.sh` OR set up manually
- [ ] Create `.github/workflows/ci.yml`
- [ ] Create `.github/workflows/pr-check.yml`
- [ ] Create `.github/workflows/release.yml`
- [ ] Install husky: `pnpm add -D husky lint-staged`
- [ ] Initialize husky: `pnpm exec husky init`
- [ ] Create `.husky/pre-commit` and `.husky/commit-msg`
- [ ] Create `lint-staged.config.js`
- [ ] Enable branch protection on `main`
- [ ] Add status badges to README
