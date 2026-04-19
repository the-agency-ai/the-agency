# Node Base Starter Pack

**Foundation for all Node.js projects**

## What This Pack Does

Sets up a Node.js project with:

- Node.js version management (via nvm)
- pnpm package manager
- TypeScript configuration
- ESLint + Prettier
- Basic project structure

## Why This Pack?

Every Node.js project in The Agency starts here. This pack establishes:

- Consistent tooling across all projects
- Type safety from day one
- Code quality enforcement
- Agent-friendly configuration

## Trade-offs

| Choice             | Alternative   | Why We Chose This              |
| ------------------ | ------------- | ------------------------------ |
| pnpm               | npm, yarn     | Faster, disk-efficient, strict |
| TypeScript         | JavaScript    | Type safety, better tooling    |
| ESLint flat config | Legacy config | Future-proof, simpler          |

## Dependencies

**None** - This is the base pack.

## What's Next?

After completing this pack:

- `react-app` - For web applications
- `nitro-api` - For API services
- `supabase-auth` - For authentication
- `github-ci` - For CI/CD
