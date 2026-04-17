# Next.js App Starter Pack

**Provider for:** `/ui-add <name> --workstream <ws> --type nextjs-app`

**Purpose:** scaffolds a new Next.js 16 app under `apps/<name>/` mirroring the `apps/doctor-frontend/` reference pattern.

## What it creates

```
apps/<name>/
  package.json              — next@16, react@19, @of/ui workspace dep
  tsconfig.json             — extends tsconfig.web.json
  next.config.ts            — basePath: /<name> by default
  Dockerfile                — monorepo-root build context, uses pnpm
  scripts/init-docker.sh    — pnpm install + next dev
  app/
    layout.tsx              — minimal html + body wrapper
    page.tsx                — "<name>" welcome page
    globals.css             — minimal tokens-aware CSS
```

Also updates `claude/config/topology.yaml`:

- Adds a `frontend` service entry with `build: apps/<name>`, `wires_from: [backend]`, and `NEXT_PUBLIC_API_URL: "{{backend.outputs.url}}"`.

## Port allocation

The caller (`/ui-add`) allocates a free port from the `4100–4199` range by scanning `docker-compose.dev.yml`, and passes it via `--port <num>`. The Dockerfile EXPOSEs this port and `next dev --port <num>` uses it.

## What it does NOT do (v1)

- No shadcn/ui init (imports `@of/ui` components instead)
- No Tailwind install (the `@of/ui` package provides tokens)
- No auth setup (bring `supabase-auth` or similar if needed)
- No `@vercel/analytics` install (use the `vercel` starter pack)
- No `.vercel/project.json` wiring (separate concern; V2 deploy handles cloud)
- No `docker-compose.dev.yml` edit — the caller / operator extends it once the app stabilizes

## After scaffolding

1. Install dependencies from the monorepo root: `pnpm install`
2. Run locally: `pnpm --filter <name> dev`
3. Or with full stack: `pnpm preview:v2 local --services <name>`
4. Visit `http://localhost:<port>`

## Manifest contract

See `manifest.yaml` for the provider contract that `/ui-add` reads.
