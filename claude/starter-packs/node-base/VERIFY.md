# Verify: Node Base

Run these checks to confirm setup is correct.

## Automated Check

```bash
# Run all verification in one command
pnpm build && pnpm lint && echo "✅ All checks passed"
```

## Manual Checks

### 1. Node Version

```bash
node --version
# Expected: v22.x or higher
```

### 2. pnpm Working

```bash
pnpm --version
# Expected: 9.x or higher
```

### 3. TypeScript Compiles

```bash
pnpm build
# Expected: No errors, dist/ folder created
```

### 4. ESLint Runs

```bash
pnpm lint
# Expected: No errors
```

### 5. Development Mode

```bash
pnpm dev
# Expected: "Hello from The Agency!"
```

## Verification Checklist

- [ ] `node --version` shows v22+
- [ ] `pnpm --version` shows 9+
- [ ] `pnpm build` succeeds
- [ ] `pnpm lint` passes
- [ ] `pnpm dev` runs
- [ ] Git repo initialized

## Troubleshooting

### "command not found: pnpm"

```bash
npm install -g pnpm
source ~/.zshrc
```

### TypeScript errors

```bash
pnpm add -D @types/node
```

### ESLint "Cannot find module"

```bash
# Ensure package.json has "type": "module"
pnpm pkg set type="module"
```
