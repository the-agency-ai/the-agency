# Verify: GitHub CI

## Automated Check

```bash
# Check workflow exists
cat .github/workflows/ci.yml && echo "✅ Workflow exists"

# Check last run status
gh run list --limit 1
```

## Manual Checks

### 1. Workflow File Exists

```bash
ls -la .github/workflows/ci.yml
```

### 2. Push Triggers Workflow

1. Make a small change
2. `git add . && git commit -m "test ci" && git push`
3. Check: `gh run watch`

### 3. All Steps Pass

```bash
gh run view --log
# All steps should show green checkmarks
```

## Verification Checklist

- [ ] `.github/workflows/ci.yml` exists
- [ ] Push triggers workflow
- [ ] Lint step passes
- [ ] Type check step passes
- [ ] Build step passes
- [ ] Test step passes (or skips if no tests)

## Troubleshooting

### Workflow not triggering

```bash
# Check GitHub Actions is enabled
gh repo view --json hasActionsEnabled

# Check branch name matches
git branch --show-current  # Should be 'main'
```

### pnpm install fails

```bash
# Ensure lockfile is committed
git add pnpm-lock.yaml
git commit -m "Add lockfile"
```

### Build fails in CI but works locally

```bash
# Run exactly what CI runs
pnpm install --frozen-lockfile
pnpm lint
pnpm exec tsc --noEmit
pnpm build
```
