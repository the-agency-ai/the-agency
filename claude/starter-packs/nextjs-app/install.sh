#!/bin/bash
# Next.js App Starter Pack — installer
#
# Scaffolds a new Next.js 16 app under apps/<name>/ mirroring apps/doctor-frontend/.
# Invoked by claude/tools/ui-add (via tools/ui-add.ts).
#
# Contract (args):
#   --name <kebab>       — app name (required; becomes apps/<name>/)
#   --port <num>         — host port for dev server (required)
#   --base-path <path>   — Next.js basePath (optional, default: /<name>)
#   --repo-root <path>   — absolute path to repo root (required)
#   --dry-run            — print plan, don't write

set -euo pipefail

NAME=""
PORT=""
BASE_PATH=""
REPO_ROOT=""
DRY_RUN=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --name)       NAME="$2"; shift 2 ;;
        --port)       PORT="$2"; shift 2 ;;
        --base-path)  BASE_PATH="$2"; shift 2 ;;
        --repo-root)  REPO_ROOT="$2"; shift 2 ;;
        --dry-run)    DRY_RUN=true; shift ;;
        -h|--help)
            cat <<USAGE
Usage: install.sh --name <kebab> --port <num> --repo-root <path> [options]

Options:
  --name <kebab>         App name (required, kebab-case)
  --port <num>           Host port (required, integer)
  --base-path <path>     Next.js basePath [default: /<name>]
  --repo-root <path>     Repo root absolute path (required)
  --dry-run              Print plan, don't write
USAGE
            exit 0 ;;
        *) echo "[nextjs-app] ERROR: unknown arg: $1" >&2; exit 1 ;;
    esac
done

if [[ -z "$NAME" || -z "$PORT" || -z "$REPO_ROOT" ]]; then
    echo "[nextjs-app] ERROR: --name, --port, --repo-root are required" >&2
    exit 1
fi

: "${BASE_PATH:="/$NAME"}"

TARGET_DIR="$REPO_ROOT/apps/$NAME"

if [[ -e "$TARGET_DIR" ]]; then
    echo "[nextjs-app] ERROR: $TARGET_DIR already exists — refusing to overwrite" >&2
    exit 1
fi

# --- file templates -----------------------------------------------------------

read -r -d '' PACKAGE_JSON <<EOF || true
{
  "name": "${NAME}",
  "version": "0.1.0",
  "private": true,
  "scripts": {
    "dev": "next dev --port ${PORT}",
    "build": "next build",
    "start": "next start --port ${PORT}"
  },
  "dependencies": {
    "@of/ui": "workspace:*",
    "next": "16.1.6",
    "react": "19.2.3",
    "react-dom": "19.2.3"
  },
  "devDependencies": {
    "@testing-library/jest-dom": "^6.9.1",
    "@testing-library/react": "^16.3.2",
    "@testing-library/user-event": "^14.6.1",
    "@types/node": "^20",
    "@types/react": "^19",
    "@types/react-dom": "^19",
    "jsdom": "^29.0.1",
    "vitest": "^4.1.0"
  }
}
EOF

read -r -d '' TSCONFIG_JSON <<EOF || true
{
  "extends": "../../tsconfig.web.json",
  "compilerOptions": {
    "lib": ["dom", "dom.iterable", "esnext"],
    "allowJs": true,
    "noEmit": true,
    "module": "esnext",
    "moduleResolution": "bundler",
    "jsx": "react-jsx",
    "plugins": [
      {
        "name": "next"
      }
    ],
    "paths": {
      "@/*": ["./*"]
    }
  },
  "include": [
    "next-env.d.ts",
    "**/*.ts",
    "**/*.tsx",
    ".next/types/**/*.ts",
    ".next/dev/types/**/*.ts",
    "**/*.mts"
  ],
  "exclude": ["node_modules"]
}
EOF

read -r -d '' NEXT_CONFIG_TS <<EOF || true
import type { NextConfig } from 'next';

const nextConfig: NextConfig = {
  basePath: '${BASE_PATH}',
};

export default nextConfig;
EOF

read -r -d '' DOCKERFILE <<EOF || true
# Build context must be the monorepo root
FROM node:24.13.0
RUN corepack enable && corepack prepare pnpm@10.29.2 --activate
WORKDIR /app

# Copy only root config + this app + shared packages
COPY package.json pnpm-lock.yaml pnpm-workspace.yaml tsconfig*.json ./
COPY apps/${NAME}/ apps/${NAME}/
COPY packages/ packages/

RUN chmod +x /app/apps/${NAME}/scripts/init-docker.sh

ENV NODE_ENV=development
ENV TZ=UTC

EXPOSE ${PORT}
CMD ["/app/apps/${NAME}/scripts/init-docker.sh"]
EOF

read -r -d '' INIT_DOCKER_SH <<EOF || true
#!/usr/bin/env bash
set -euo pipefail

echo "==> Configuring shared pnpm store"
pnpm config set store-dir /app/.pnpm-store

echo "==> Installing dependencies"
pnpm install --filter ${NAME}...

echo "==> Starting Next.js dev server"
pnpm --filter ${NAME} run dev
EOF

read -r -d '' LAYOUT_TSX <<EOF || true
import type { Metadata } from 'next';
import './globals.css';

export const metadata: Metadata = {
  title: '${NAME}',
  description: 'Scaffolded by /ui-add',
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en">
      <body className="antialiased">{children}</body>
    </html>
  );
}
EOF

read -r -d '' PAGE_TSX <<EOF || true
export default function Home() {
  return (
    <main className="flex min-h-screen flex-col items-center justify-center p-24">
      <h1 className="text-4xl font-bold">${NAME}</h1>
      <p className="mt-4 text-muted-foreground">
        Scaffolded by <code>/ui-add</code> — start here.
      </p>
    </main>
  );
}
EOF

read -r -d '' GLOBALS_CSS <<EOF || true
@import '@of/ui/globals.css';
EOF

read -r -d '' POSTCSS_CONFIG_MJS <<EOF || true
export { default } from '@of/ui/postcss.config';
EOF

# --- dry-run ------------------------------------------------------------------

if [[ "$DRY_RUN" == "true" ]]; then
    echo "[nextjs-app] DRY-RUN — would write:"
    echo "  $TARGET_DIR/package.json"
    echo "  $TARGET_DIR/tsconfig.json"
    echo "  $TARGET_DIR/next.config.ts (basePath: $BASE_PATH)"
    echo "  $TARGET_DIR/postcss.config.mjs"
    echo "  $TARGET_DIR/Dockerfile (port: $PORT)"
    echo "  $TARGET_DIR/scripts/init-docker.sh"
    echo "  $TARGET_DIR/app/layout.tsx"
    echo "  $TARGET_DIR/app/page.tsx"
    echo "  $TARGET_DIR/app/globals.css (imports @of/ui/globals.css)"
    exit 0
fi

# --- write --------------------------------------------------------------------
# Writes are atomic-per-file to a staged parent directory. On any failure the
# partial directory is removed via the EXIT trap so /service-add can retry
# cleanly without a manual `rm -rf`.

cleanup_on_failure() {
    local code=$?
    if [[ $code -ne 0 && -d "$TARGET_DIR" ]]; then
        echo "[nextjs-app] install failed (exit $code) — removing partial $TARGET_DIR" >&2
        rm -rf "$TARGET_DIR"
    fi
}
trap cleanup_on_failure EXIT

mkdir -p "$TARGET_DIR/app" "$TARGET_DIR/scripts"

printf '%s\n' "$PACKAGE_JSON"     > "$TARGET_DIR/package.json"
printf '%s\n' "$TSCONFIG_JSON"    > "$TARGET_DIR/tsconfig.json"
printf '%s\n' "$NEXT_CONFIG_TS"   > "$TARGET_DIR/next.config.ts"
printf '%s\n' "$POSTCSS_CONFIG_MJS" > "$TARGET_DIR/postcss.config.mjs"
printf '%s\n' "$DOCKERFILE"       > "$TARGET_DIR/Dockerfile"
printf '%s\n' "$INIT_DOCKER_SH"   > "$TARGET_DIR/scripts/init-docker.sh"
printf '%s\n' "$LAYOUT_TSX"       > "$TARGET_DIR/app/layout.tsx"
printf '%s\n' "$PAGE_TSX"         > "$TARGET_DIR/app/page.tsx"
printf '%s\n' "$GLOBALS_CSS"      > "$TARGET_DIR/app/globals.css"

chmod +x "$TARGET_DIR/scripts/init-docker.sh"

trap - EXIT
echo "[nextjs-app] wrote $TARGET_DIR/ (9 files, port=$PORT, basePath=$BASE_PATH)"
