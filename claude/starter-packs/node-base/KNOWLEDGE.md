# Knowledge: Node Base

Context for agents working with this pack.

## Tech Stack

- **Runtime:** Node.js 22+ LTS
- **Package Manager:** pnpm 9+
- **Language:** TypeScript 5.x
- **Linting:** ESLint 9 flat config
- **Formatting:** Prettier 3.x

## Key Decisions

### Why pnpm over npm/yarn?

1. **Faster:** Parallel downloads, efficient caching
2. **Strict:** Prevents phantom dependencies
3. **Disk efficient:** Content-addressable storage

### Why TypeScript?

1. **Type safety:** Catch errors at compile time
2. **Tooling:** Better IDE support
3. **Documentation:** Types are documentation

### Why ESLint flat config?

1. **Future-proof:** Legacy config deprecated
2. **Simpler:** Explicit imports, composable
3. **Type-safe:** Better TypeScript integration

## Common Patterns

### Adding Dependencies

```bash
# Production dependency
pnpm add lodash

# Dev dependency
pnpm add -D @types/lodash
```

### Running Scripts

```bash
pnpm build    # Compile TypeScript
pnpm dev      # Run with tsx (hot reload)
pnpm lint     # Check code quality
pnpm format   # Format code
```

### Environment Variables

```bash
# Create .env.local (gitignored)
echo "API_KEY=xxx" > .env.local

# Load in code
import 'dotenv/config';
console.log(process.env.API_KEY);
```

## Agent Instructions

When working with this pack:

1. **Always use pnpm** - Never npm or yarn
2. **Run build before commit** - Ensure TypeScript compiles
3. **Run lint before commit** - Ensure code quality
4. **Check types** - `pnpm exec tsc --noEmit`

## Troubleshooting Guide

| Issue            | Solution                       |
| ---------------- | ------------------------------ |
| Module not found | `pnpm install`                 |
| Type errors      | Check `@types/` package exists |
| ESLint failures  | Run `pnpm lint --fix`          |
| Build fails      | Check `tsconfig.json` paths    |
