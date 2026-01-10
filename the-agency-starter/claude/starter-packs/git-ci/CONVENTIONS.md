# Git CI Starter Pack

Conventions for Git workflows and CI/CD pipelines in The Agency.

## GitHub Actions

### Workflow Structure

```
.github/
  workflows/
    ci.yml              # Main CI pipeline (test, lint, build)
    release.yml         # Release automation
    pr-check.yml        # PR validation
```

### CI Pipeline (ci.yml)

```yaml
name: CI

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: '20'
          cache: 'npm'

      - name: Install dependencies
        run: npm ci

      - name: Lint
        run: npm run lint

      - name: Type check
        run: npm run type-check

      - name: Test
        run: npm test

      - name: Build
        run: npm run build
```

### PR Check (pr-check.yml)

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

      - name: Check PR title format
        env:
          TITLE: ${{ github.event.pull_request.title }}
        run: |
          if [[ ! "$TITLE" =~ ^(feat|fix|docs|chore|refactor|test)\(.+\):.*$ ]]; then
            echo "PR title must follow: type(scope): message"
            exit 1
          fi

      - name: Check for CLAUDE.md compliance
        run: |
          # Verify commit messages follow conventions
          # Use process substitution to ensure exit status propagates
          while read msg; do
            if [[ ! "$msg" =~ ^[a-z-]+/[a-z-]+:.*$ ]]; then
              echo "Commit message must follow: workstream/agent: message"
              echo "Got: $msg"
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

      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: '20'
          cache: 'npm'

      - name: Install and build
        run: |
          npm ci
          npm run build

      - name: Create GitHub Release
        uses: softprops/action-gh-release@v1
        with:
          generate_release_notes: true
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

---

## Pre-commit Hooks

### Setup with Husky

```bash
npm install -D husky lint-staged
npx husky init
```

### .husky/pre-commit

```bash
#!/bin/sh
. "$(dirname "$0")/_/husky.sh"

npx lint-staged
```

### .husky/commit-msg

```bash
#!/bin/sh
. "$(dirname "$0")/_/husky.sh"

# Validate commit message format: workstream/agent: type(scope): message
commit_msg=$(cat "$1")
pattern="^[a-z-]+/[a-z-]+: (feat|fix|docs|chore|refactor|test)(\(.+\))?: .+"

if ! echo "$commit_msg" | grep -qE "$pattern"; then
  echo "ERROR: Commit message must follow format:"
  echo "  workstream/agent: type(scope): message"
  echo ""
  echo "Examples:"
  echo "  housekeeping/housekeeping: feat(tools): add new utility"
  echo "  web/frontend: fix(auth): resolve login issue"
  echo ""
  echo "Your message: $commit_msg"
  exit 1
fi
```

### lint-staged.config.js

```javascript
module.exports = {
  '*.{js,jsx,ts,tsx}': ['eslint --fix', 'prettier --write'],
  '*.{json,md,yml,yaml}': ['prettier --write'],
};
```

---

## Branch Protection

### Recommended Settings (GitHub)

**Branch:** `main`

| Setting | Value |
|---------|-------|
| Require pull request reviews | Yes (1 reviewer) |
| Require status checks | Yes |
| Required checks | `test`, `validate` |
| Require branches to be up to date | Yes |
| Require signed commits | Optional |
| Include administrators | Yes |

### Branch Naming Convention

```
feature/ISSUE-123-short-description
fix/ISSUE-456-bug-description
docs/update-readme
chore/dependency-updates
```

---

## Secrets Management

### Required Secrets

| Secret | Purpose |
|--------|---------|
| `GITHUB_TOKEN` | Auto-provided by GitHub |
| `NPM_TOKEN` | Publishing to npm (if applicable) |
| `VERCEL_TOKEN` | Deployment (see Vercel starter pack) |

### Environment Variables

```yaml
# In workflow
env:
  NODE_ENV: production
  CI: true

# From secrets
env:
  API_KEY: ${{ secrets.API_KEY }}
```

---

## Caching Strategies

### Node.js Dependencies

```yaml
- uses: actions/setup-node@v4
  with:
    node-version: '20'
    cache: 'npm'  # Automatic caching
```

### Custom Cache

```yaml
- name: Cache build artifacts
  uses: actions/cache@v4
  with:
    path: |
      .next/cache
      node_modules/.cache
    key: ${{ runner.os }}-build-${{ hashFiles('**/package-lock.json') }}
    restore-keys: |
      ${{ runner.os }}-build-
```

---

## Matrix Builds

### Multi-version Testing

```yaml
jobs:
  test:
    strategy:
      matrix:
        node-version: [18, 20, 22]
        os: [ubuntu-latest, macos-latest]

    runs-on: ${{ matrix.os }}
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: ${{ matrix.node-version }}
      - run: npm ci && npm test
```

---

## Integration with The Agency

### Triggering Agent Work

```yaml
# .github/workflows/agent-dispatch.yml
name: Agent Dispatch

on:
  issues:
    types: [labeled]

jobs:
  dispatch:
    if: github.event.label.name == 'agent-work'
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Create collaboration request
        run: |
          ./tools/collaborate \
            --from github-actions \
            --to housekeeping \
            --request "Review issue #${{ github.event.issue.number }}"
```

### Quality Gates

The Agency's pre-commit checks should mirror CI:

```bash
# tools/pre-commit-check
#!/bin/bash
npm run lint
npm run type-check
npm run test
```

---

## Monitoring & Notifications

### Slack Notifications

```yaml
- name: Notify Slack on failure
  if: failure()
  uses: 8398a7/action-slack@v3
  with:
    status: failure
    fields: repo,message,commit,author,action,eventName,ref,workflow
  env:
    SLACK_WEBHOOK_URL: ${{ secrets.SLACK_WEBHOOK }}
```

### Status Badges

Add to README.md:
```markdown
![CI](https://github.com/ORG/REPO/actions/workflows/ci.yml/badge.svg)
![Release](https://github.com/ORG/REPO/actions/workflows/release.yml/badge.svg)
```

---

## Quick Start Checklist

- [ ] Create `.github/workflows/ci.yml`
- [ ] Create `.github/workflows/pr-check.yml`
- [ ] Install husky: `npm install -D husky lint-staged`
- [ ] Initialize husky: `npx husky init`
- [ ] Create `.husky/pre-commit` and `.husky/commit-msg`
- [ ] Create `lint-staged.config.js`
- [ ] Enable branch protection on `main`
- [ ] Add status badges to README
