# Prerequisites: Vercel

## Required Packs

- `node-base` - Node.js foundation
- `react-app` - Next.js application

## Required Tools

- Vercel CLI: `pnpm add -g vercel`
- Vercel account: https://vercel.com/signup

## Required Access

- GitHub repository connected to Vercel
- Vercel account with project creation permissions

## Verify Prerequisites

```bash
# Check Vercel CLI
vercel --version

# Check Next.js project
grep -q '"next"' package.json && echo "Next.js detected"

# Check pnpm
pnpm --version
```
