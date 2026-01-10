#!/bin/bash
#
# Next.js + React Starter Pack Installer
#
# Usage:
#   ./claude/starter-packs/nextjs-react/install.sh [project-name]
#
# This installs:
#   - Next.js 14+ with App Router
#   - TypeScript configuration
#   - Tailwind CSS
#   - ESLint + Prettier
#   - Project structure following The Agency conventions
#   - API route templates with explicit operations
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_NAME="${1:-my-app}"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_step() { echo -e "${BLUE}[STEP]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }

echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}  Next.js + React Starter Pack Installer${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# ============================================================================
# Check if we're enhancing existing project or creating new
# ============================================================================

if [[ -f "package.json" ]] && grep -q "next" package.json 2>/dev/null; then
    log_info "Existing Next.js project detected. Enhancing..."
    PROJECT_ROOT="$(pwd)"
    ENHANCE_MODE=true
else
    log_step "Creating new Next.js project: $PROJECT_NAME"
    npx create-next-app@latest "$PROJECT_NAME" \
        --typescript \
        --tailwind \
        --eslint \
        --app \
        --src-dir \
        --import-alias "@/*" \
        --no-turbopack

    cd "$PROJECT_NAME"
    PROJECT_ROOT="$(pwd)"
    ENHANCE_MODE=false
fi

# ============================================================================
# Install additional dependencies
# ============================================================================

log_step "Installing additional dependencies..."

npm install zod swr zustand
npm install -D prettier eslint-config-prettier @types/node

log_info "Dependencies installed"

# ============================================================================
# Create utility files
# ============================================================================

log_step "Creating utility files..."

mkdir -p src/lib src/hooks src/types src/components/ui

# Utils
cat > src/lib/utils.ts << 'CODE'
import { type ClassValue, clsx } from 'clsx';
import { twMerge } from 'tailwind-merge';

export function cn(...inputs: ClassValue[]) {
  return twMerge(clsx(inputs));
}

export function formatDate(date: Date | string): string {
  return new Date(date).toLocaleDateString('en-US', {
    month: 'short',
    day: 'numeric',
    year: 'numeric',
  });
}

export function sleep(ms: number): Promise<void> {
  return new Promise(resolve => setTimeout(resolve, ms));
}
CODE

# Install clsx and tailwind-merge for cn utility
npm install clsx tailwind-merge

# API client
cat > src/lib/api.ts << 'CODE'
const API_BASE = process.env.NEXT_PUBLIC_API_URL || '/api';

interface ApiOptions extends RequestInit {
  params?: Record<string, string>;
}

async function request<T>(endpoint: string, options: ApiOptions = {}): Promise<T> {
  const { params, ...init } = options;

  let url = `${API_BASE}${endpoint}`;
  if (params) {
    const searchParams = new URLSearchParams(params);
    url += `?${searchParams.toString()}`;
  }

  const response = await fetch(url, {
    ...init,
    headers: {
      'Content-Type': 'application/json',
      ...init.headers,
    },
  });

  if (!response.ok) {
    const error = await response.json().catch(() => ({}));
    throw new Error(error.message || `API Error: ${response.status}`);
  }

  return response.json();
}

export const api = {
  get: <T>(endpoint: string, params?: Record<string, string>) =>
    request<T>(endpoint, { method: 'GET', params }),

  post: <T>(endpoint: string, body: unknown) =>
    request<T>(endpoint, { method: 'POST', body: JSON.stringify(body) }),
};
CODE

# Constants
cat > src/lib/constants.ts << 'CODE'
export const APP_NAME = 'My App';
export const APP_DESCRIPTION = 'Built with The Agency';

export const ROUTES = {
  home: '/',
  dashboard: '/dashboard',
  settings: '/settings',
} as const;
CODE

log_info "Created src/lib/ utilities"

# ============================================================================
# Create example API routes (explicit operations pattern)
# ============================================================================

log_step "Creating example API routes..."

mkdir -p src/app/api/example/{create,list,get,update,delete}
mkdir -p src/app/api/example/get/\[id\]
mkdir -p src/app/api/example/update/\[id\]
mkdir -p src/app/api/example/delete/\[id\]

# Create
cat > src/app/api/example/create/route.ts << 'CODE'
import { NextResponse } from 'next/server';

export async function POST(request: Request) {
  try {
    const body = await request.json();

    // TODO: Validate with Zod
    // TODO: Create in database

    const created = {
      id: crypto.randomUUID(),
      ...body,
      createdAt: new Date().toISOString(),
    };

    return NextResponse.json(created, { status: 201 });
  } catch (error) {
    return NextResponse.json(
      { error: 'Failed to create' },
      { status: 500 }
    );
  }
}
CODE

# List
cat > src/app/api/example/list/route.ts << 'CODE'
import { NextResponse } from 'next/server';

export async function GET(request: Request) {
  const { searchParams } = new URL(request.url);
  const limit = parseInt(searchParams.get('limit') || '10');
  const offset = parseInt(searchParams.get('offset') || '0');

  // TODO: Fetch from database

  return NextResponse.json({
    items: [],
    total: 0,
    limit,
    offset,
  });
}
CODE

# Get
cat > 'src/app/api/example/get/[id]/route.ts' << 'CODE'
import { NextResponse } from 'next/server';

export async function GET(
  request: Request,
  { params }: { params: { id: string } }
) {
  const { id } = params;

  // TODO: Fetch from database

  return NextResponse.json({
    id,
    name: 'Example',
    createdAt: new Date().toISOString(),
  });
}
CODE

# Update
cat > 'src/app/api/example/update/[id]/route.ts' << 'CODE'
import { NextResponse } from 'next/server';

export async function POST(
  request: Request,
  { params }: { params: { id: string } }
) {
  try {
    const { id } = params;
    const body = await request.json();

    // TODO: Validate with Zod
    // TODO: Update in database

    return NextResponse.json({
      id,
      ...body,
      updatedAt: new Date().toISOString(),
    });
  } catch (error) {
    return NextResponse.json(
      { error: 'Failed to update' },
      { status: 500 }
    );
  }
}
CODE

# Delete
cat > 'src/app/api/example/delete/[id]/route.ts' << 'CODE'
import { NextResponse } from 'next/server';

export async function POST(
  request: Request,
  { params }: { params: { id: string } }
) {
  const { id } = params;

  // TODO: Delete from database

  return NextResponse.json({ deleted: true, id });
}
CODE

log_info "Created example API routes at src/app/api/example/"

# ============================================================================
# Create example components
# ============================================================================

log_step "Creating example components..."

# Button component
cat > src/components/ui/Button.tsx << 'CODE'
import { forwardRef } from 'react';
import { cn } from '@/lib/utils';

interface ButtonProps extends React.ButtonHTMLAttributes<HTMLButtonElement> {
  variant?: 'primary' | 'secondary' | 'danger';
  size?: 'sm' | 'md' | 'lg';
  loading?: boolean;
}

export const Button = forwardRef<HTMLButtonElement, ButtonProps>(
  ({ className, variant = 'primary', size = 'md', loading, children, disabled, ...props }, ref) => {
    return (
      <button
        ref={ref}
        className={cn(
          'rounded font-medium transition-colors focus:outline-none focus:ring-2 focus:ring-offset-2',
          variants[variant],
          sizes[size],
          (loading || disabled) && 'opacity-50 cursor-not-allowed',
          className
        )}
        disabled={loading || disabled}
        {...props}
      >
        {loading ? 'Loading...' : children}
      </button>
    );
  }
);

Button.displayName = 'Button';

const variants = {
  primary: 'bg-blue-600 text-white hover:bg-blue-700 focus:ring-blue-500',
  secondary: 'bg-gray-200 text-gray-800 hover:bg-gray-300 focus:ring-gray-500',
  danger: 'bg-red-600 text-white hover:bg-red-700 focus:ring-red-500',
};

const sizes = {
  sm: 'px-3 py-1 text-sm',
  md: 'px-4 py-2',
  lg: 'px-6 py-3 text-lg',
};
CODE

log_info "Created src/components/ui/Button.tsx"

# ============================================================================
# Create error and loading pages
# ============================================================================

log_step "Creating error and loading pages..."

# Error page
cat > src/app/error.tsx << 'CODE'
'use client';

import { Button } from '@/components/ui/Button';

export default function Error({
  error,
  reset,
}: {
  error: Error & { digest?: string };
  reset: () => void;
}) {
  return (
    <div className="flex flex-col items-center justify-center min-h-screen gap-4">
      <h2 className="text-2xl font-bold">Something went wrong!</h2>
      <p className="text-gray-600">{error.message}</p>
      <Button onClick={() => reset()}>Try again</Button>
    </div>
  );
}
CODE

# Loading page
cat > src/app/loading.tsx << 'CODE'
export default function Loading() {
  return (
    <div className="flex items-center justify-center min-h-screen">
      <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-600" />
    </div>
  );
}
CODE

log_info "Created error and loading pages"

# ============================================================================
# Create environment files
# ============================================================================

log_step "Creating environment files..."

cat > .env.example << 'ENV'
# API Configuration
NEXT_PUBLIC_API_URL=http://localhost:3000/api

# Database (if using)
DATABASE_URL=

# Auth (if using)
NEXTAUTH_SECRET=
NEXTAUTH_URL=http://localhost:3000
ENV

if [[ ! -f ".env.local" ]]; then
    cp .env.example .env.local
    log_info "Created .env.local from .env.example"
fi

# ============================================================================
# Create Prettier config
# ============================================================================

cat > .prettierrc << 'JSON'
{
  "semi": true,
  "singleQuote": true,
  "tabWidth": 2,
  "trailingComma": "es5",
  "printWidth": 100
}
JSON

log_info "Created .prettierrc"

# ============================================================================
# Update package.json scripts
# ============================================================================

log_step "Updating package.json scripts..."

# Add type-check script if not exists
if ! grep -q '"type-check"' package.json; then
    npm pkg set scripts.type-check="tsc --noEmit"
fi

if ! grep -q '"format"' package.json; then
    npm pkg set scripts.format="prettier --write ."
fi

log_info "Updated package.json scripts"

# ============================================================================
# Summary
# ============================================================================

echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}  Next.js + React Starter Pack Installed!${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo "Project structure created:"
echo "  src/lib/          - Utilities (api.ts, utils.ts, constants.ts)"
echo "  src/components/   - UI components (Button.tsx)"
echo "  src/app/api/      - Example API routes (explicit operations)"
echo "  src/app/          - Error and loading pages"
echo ""
echo "Dependencies installed:"
echo "  - zod (validation)"
echo "  - swr (data fetching)"
echo "  - zustand (state management)"
echo "  - clsx, tailwind-merge (styling utilities)"
echo ""
echo "Next steps:"
echo "  1. cd $PROJECT_NAME"
echo "  2. npm run dev"
echo "  3. Visit http://localhost:3000"
echo ""
echo "API routes follow The Agency explicit operations pattern:"
echo "  POST /api/example/create"
echo "  GET  /api/example/list"
echo "  GET  /api/example/get/[id]"
echo "  POST /api/example/update/[id]"
echo "  POST /api/example/delete/[id]"
echo ""
echo "See CONVENTIONS.md for detailed documentation."
echo ""
