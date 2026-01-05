# Agency Workbench

Web UI for managing your Agency-powered project.

## Features

- **Staff Manager** - Team authentication and permissions
- **Agent Manager** - Configure and monitor Claude agents
- **Content Manager** - Manage prompts and templates
- **Pulse Beat** - Real-time metrics dashboard
- **Catalog** - Browse available agents

## Quick Start

```bash
# From repo root
pnpm install
pnpm --filter @agency/workbench dev
```

Opens at http://localhost:3001

## Deployment

Deploy to Vercel, Netlify, or any platform supporting Next.js.

```bash
pnpm --filter @agency/workbench build
```

## Configuration

Set environment variables in `.env.local`:

```bash
# Database (Supabase recommended)
DATABASE_URL=...
SUPABASE_URL=...
SUPABASE_ANON_KEY=...

# Auth
AUTH_SECRET=...

# Optional: Analytics
POSTHOG_API_KEY=...
```

## Structure

```
src/
├── app/
│   ├── staff/      # Staff Manager - team access
│   ├── agents/     # Agent Manager - agent config
│   ├── content/    # Content Manager - prompts/templates
│   ├── pulse/      # Pulse Beat - metrics
│   └── catalog/    # Catalog - agent discovery
└── components/     # Shared UI components
```

---

*Part of The Agency framework*
