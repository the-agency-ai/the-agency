# AgencyBench

Developer workbench for The Agency - a multi-agent development framework.

## Overview

AgencyBench is a desktop application that provides visual tools for working with The Agency:

- **Markdown Browser** - Browse and preview markdown documentation
- **Knowledge Indexer** - Search across KNOWLEDGE.md files
- **Agent Monitor** - Monitor running agents (coming soon)
- **Collaboration Inbox** - Manage inter-agent requests (coming soon)

## Tech Stack

- **UI**: Next.js + React + Tailwind CSS
- **Desktop**: Tauri (Rust)
- **Database**: SQLite + Drizzle ORM

## Development

### Prerequisites

- Node.js 18+
- Rust (for Tauri builds)
- pnpm (recommended)

### Run in Development

```bash
# Web only (no Tauri)
npm run dev

# With Tauri (desktop app)
npm run tauri:dev
```

### Build

```bash
# Build Next.js
npm run build

# Build Tauri desktop app
npm run tauri:build
```

## Architecture

```
apps/agency-bench/
├── src/                    # Next.js frontend
│   ├── app/               # App router pages
│   │   └── bench/         # Main bench routes
│   │       └── (apps)/    # Embedded DevApps
│   ├── components/        # React components
│   └── lib/               # Utilities
├── src-tauri/             # Tauri backend (Rust)
│   └── src/
│       └── main.rs        # Tauri commands
└── public/                # Static assets
```

## DevApps

Each DevApp is a self-contained feature within AgencyBench:

| DevApp | Purpose | Status |
|--------|---------|--------|
| Markdown Browser | Browse/preview .md files | Ready |
| Knowledge Indexer | Search KNOWLEDGE.md | Ready |
| Agent Monitor | Monitor running agents | Planned |
| Collaboration Inbox | Inter-agent requests | Planned |

## License

MIT License - see LICENSE in root.
