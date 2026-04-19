# Setup: GitHub CI

**Time:** ~10 minutes
**Difficulty:** Beginner

## Quick Start (Automated)

Run the installer to set up everything automatically:

```bash
./claude/starter-packs/github-ci/install.sh
```

This creates:
- `.github/workflows/ci.yml` - Main CI pipeline
- `.github/workflows/pr-check.yml` - PR validation
- `.github/workflows/release.yml` - Release automation
- `.husky/pre-commit` - Lint staged files
- `.husky/commit-msg` - Validate commit messages
- `lint-staged.config.js` - Staged file configuration

**Skip to [Step 5](#step-5-push-to-github)** if using the installer.

---

## Manual Setup

### Step 1: Create Workflow Directory

```bash
mkdir -p .github/workflows
```

### Step 2: Create CI Workflow

```bash
cat > .github/workflows/ci.yml << 'EOF'
name: CI

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  build:
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

      - name: Install dependencies
        run: pnpm install --frozen-lockfile

      - name: Lint
        run: pnpm lint

      - name: Type check
        run: pnpm exec tsc --noEmit

      - name: Build
        run: pnpm build

      - name: Test
        run: pnpm test --if-present
EOF
```

### Step 3: Create PR Check Workflow

```bash
cat > .github/workflows/pr-check.yml << 'EOF'
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
            echo "PR title follows Agency format"
            exit 0
          fi
          # Allow conventional commits: type(scope): message
          if [[ "$TITLE" =~ ^(feat|fix|docs|chore|refactor|test)(\(.+\))?:.*$ ]]; then
            echo "PR title follows conventional commit format"
            exit 0
          fi
          echo "ERROR: PR title must follow one of these formats:"
          echo "  workstream/agent: message (Agency format)"
          echo "  type(scope): message (Conventional commits)"
          exit 1

      - name: Validate commit messages
        run: |
          echo "Checking commit messages..."
          while IFS= read -r msg; do
            if [[ "$msg" =~ ^[a-z-]+/[a-z-]+:.*$ ]] || \
               [[ "$msg" =~ ^(feat|fix|docs|chore|refactor|test)(\(.+\))?:.*$ ]] || \
               [[ "$msg" =~ ^Merge ]]; then
              continue
            fi
            echo "ERROR: Invalid commit message format"
            echo "Got: $msg"
            exit 1
          done < <(git log --format="%s" origin/main..HEAD 2>/dev/null || true)
          echo "All commit messages valid"
EOF
```

### Step 4: Create Release Workflow

```bash
cat > .github/workflows/release.yml << 'EOF'
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
          pnpm build || echo "No build script"

      - name: Create GitHub Release
        uses: softprops/action-gh-release@v1
        with:
          generate_release_notes: true
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
EOF
```

### Step 5: Push to GitHub

```bash
# Create repo if needed
gh repo create my-project --public --source=. --push

# Or if repo exists
git add .
git commit -m "chore: add GitHub CI workflows"
git push
```

### Step 6: Verify Workflow Runs

```bash
# Check workflow status
gh run list
```

---

## Optional: Husky + lint-staged

Set up pre-commit hooks for local enforcement.

### Install Dependencies

```bash
pnpm add -D husky lint-staged
```

### Initialize Husky

```bash
pnpm exec husky init
```

### Create Pre-commit Hook

```bash
cat > .husky/pre-commit << 'EOF'
#!/bin/sh
. "$(dirname "$0")/_/husky.sh"

pnpm exec lint-staged
EOF
chmod +x .husky/pre-commit
```

### Create Commit-msg Hook

```bash
cat > .husky/commit-msg << 'EOF'
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

echo "ERROR: Commit message format invalid"
echo ""
echo "Expected formats:"
echo "  workstream/agent: message (Agency format)"
echo "  type(scope): message (Conventional commits)"
echo ""
echo "Examples:"
echo "  housekeeping/captain: feat: add new tool"
echo "  feat(auth): add login page"
exit 1
EOF
chmod +x .husky/commit-msg
```

### Create lint-staged Config

```bash
cat > lint-staged.config.js << 'EOF'
module.exports = {
  '*.{js,jsx,ts,tsx}': ['eslint --fix', 'prettier --write'],
  '*.{json,md,yml,yaml}': ['prettier --write'],
};
EOF
```

---

## Optional: Add Test Script

```bash
# If you want tests, add Vitest
pnpm add -D vitest

# Add to package.json
pnpm pkg set scripts.test="vitest run"
```

---

## Optional: Pull Request Template

```bash
mkdir -p .github

cat > .github/pull_request_template.md << 'EOF'
## Summary

<!-- Brief description of changes -->

## Changes

- [ ] Change 1
- [ ] Change 2

## Testing

- [ ] Tested locally
- [ ] CI passes

## Notes

<!-- Any additional context -->
EOF
```

---

## Optional: Branch Protection

After pushing, configure branch protection in GitHub:

1. Go to **Settings > Branches**
2. Add rule for `main` branch
3. Enable:
   - Require pull request reviews (1 reviewer)
   - Require status checks to pass (`build`, `validate`)
   - Require branches to be up to date
   - Include administrators

---

## Done!

Proceed to [VERIFY.md](./VERIFY.md) to confirm setup.
