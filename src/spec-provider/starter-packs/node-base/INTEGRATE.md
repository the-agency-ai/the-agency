# Integrate: Node Base

## What This Pack Provides

After completing node-base, your project has:

| Component  | Location           | Purpose          |
| ---------- | ------------------ | ---------------- |
| TypeScript | `tsconfig.json`    | Type safety      |
| ESLint     | `eslint.config.js` | Code quality     |
| Prettier   | `.prettierrc`      | Formatting       |
| Scripts    | `package.json`     | Build, lint, dev |

## Next Packs

### For Web Applications

```
node-base → react-app → supabase-auth → vercel-deploy
```

### For API Services

```
node-base → nitro-api → supabase-auth → supabase-data → vercel-deploy
```

### For Full Stack

```
node-base → react-app → nitro-api → supabase-auth → supabase-data → github-ci → vercel-deploy
```

## Integration Points

### With react-app

- Uses same TypeScript config (extended)
- Uses same ESLint rules (extended for React)
- Uses same Prettier config

### With nitro-api

- Uses same TypeScript config (extended)
- Uses same ESLint rules
- Adds API-specific scripts

### With github-ci

- Runs `pnpm build` in CI
- Runs `pnpm lint` in CI
- Runs `pnpm test` (if tests added)

## Files Other Packs Modify

| Pack          | Modifies                        |
| ------------- | ------------------------------- |
| react-app     | `package.json`, `tsconfig.json` |
| nitro-api     | `package.json`, adds `server/`  |
| github-ci     | Adds `.github/workflows/`       |
| vercel-deploy | Adds `vercel.json`              |
