#!/bin/bash
#
# Supabase Starter Pack Installer
#
# Usage:
#   ./claude/starter-packs/supabase/install.sh
#
# This installs:
#   - Supabase client libraries
#   - Client/server Supabase helpers
#   - Auth callback route
#   - Middleware for protected routes
#   - Database types template
#   - Example migration
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"

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
echo -e "${BLUE}  Supabase Starter Pack Installer${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

cd "$PROJECT_ROOT"

# ============================================================================
# Verify Next.js project
# ============================================================================

if [[ ! -f "package.json" ]]; then
    log_warn "No package.json found. Run from project root."
    exit 1
fi

# ============================================================================
# Install Supabase packages
# ============================================================================

log_step "Installing Supabase packages..."

npm install @supabase/supabase-js @supabase/ssr

log_info "Installed @supabase/supabase-js and @supabase/ssr"

# ============================================================================
# Create Supabase client helpers
# ============================================================================

log_step "Creating Supabase client helpers..."

mkdir -p src/lib/supabase

# Browser client
cat > src/lib/supabase/client.ts << 'CODE'
import { createBrowserClient } from '@supabase/ssr';
import type { Database } from '@/types/database';

export function createClient() {
  return createBrowserClient<Database>(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!
  );
}
CODE

log_info "Created src/lib/supabase/client.ts"

# Server client
cat > src/lib/supabase/server.ts << 'CODE'
import { createServerClient, type CookieOptions } from '@supabase/ssr';
import { cookies } from 'next/headers';
import type { Database } from '@/types/database';

export function createClient() {
  const cookieStore = cookies();

  return createServerClient<Database>(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
    {
      cookies: {
        get(name: string) {
          return cookieStore.get(name)?.value;
        },
        set(name: string, value: string, options: CookieOptions) {
          try {
            cookieStore.set({ name, value, ...options });
          } catch (error) {
            // Handle cookies in Server Components
          }
        },
        remove(name: string, options: CookieOptions) {
          try {
            cookieStore.set({ name, value: '', ...options });
          } catch (error) {
            // Handle cookies in Server Components
          }
        },
      },
    }
  );
}

// Admin client (server-side only, bypasses RLS)
export function createAdminClient() {
  return createServerClient<Database>(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.SUPABASE_SERVICE_ROLE_KEY!,
    {
      cookies: {
        get() { return undefined; },
        set() {},
        remove() {},
      },
    }
  );
}
CODE

log_info "Created src/lib/supabase/server.ts"

# ============================================================================
# Create database types
# ============================================================================

log_step "Creating database types template..."

mkdir -p src/types

cat > src/types/database.ts << 'CODE'
// Generated types - run 'supabase gen types typescript' to update
// Or define manually based on your schema

export type Database = {
  public: {
    Tables: {
      profiles: {
        Row: {
          id: string;
          email: string;
          full_name: string | null;
          avatar_url: string | null;
          created_at: string;
          updated_at: string;
        };
        Insert: {
          id: string;
          email: string;
          full_name?: string | null;
          avatar_url?: string | null;
        };
        Update: {
          email?: string;
          full_name?: string | null;
          avatar_url?: string | null;
        };
      };
      // Add more tables here
    };
    Views: {};
    Functions: {};
    Enums: {};
  };
};

// Helper types
export type Tables<T extends keyof Database['public']['Tables']> =
  Database['public']['Tables'][T]['Row'];

export type InsertTables<T extends keyof Database['public']['Tables']> =
  Database['public']['Tables'][T]['Insert'];

export type UpdateTables<T extends keyof Database['public']['Tables']> =
  Database['public']['Tables'][T]['Update'];
CODE

log_info "Created src/types/database.ts"

# ============================================================================
# Create auth callback route
# ============================================================================

log_step "Creating auth callback route..."

mkdir -p src/app/auth/callback

cat > src/app/auth/callback/route.ts << 'CODE'
import { createClient } from '@/lib/supabase/server';
import { NextResponse } from 'next/server';

export async function GET(request: Request) {
  const { searchParams, origin } = new URL(request.url);
  const code = searchParams.get('code');
  const next = searchParams.get('next') ?? '/';

  if (code) {
    const supabase = createClient();
    const { error } = await supabase.auth.exchangeCodeForSession(code);

    if (!error) {
      return NextResponse.redirect(`${origin}${next}`);
    }
  }

  // Return to login page with error
  return NextResponse.redirect(`${origin}/login?error=auth_callback_error`);
}
CODE

log_info "Created src/app/auth/callback/route.ts"

# ============================================================================
# Update middleware for Supabase auth
# ============================================================================

log_step "Updating middleware for Supabase auth..."

cat > middleware.ts << 'CODE'
import { createServerClient, type CookieOptions } from '@supabase/ssr';
import { NextResponse, type NextRequest } from 'next/server';

export async function middleware(request: NextRequest) {
  let response = NextResponse.next({
    request: {
      headers: request.headers,
    },
  });

  const supabase = createServerClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
    {
      cookies: {
        get(name: string) {
          return request.cookies.get(name)?.value;
        },
        set(name: string, value: string, options: CookieOptions) {
          request.cookies.set({ name, value, ...options });
          response = NextResponse.next({
            request: { headers: request.headers },
          });
          response.cookies.set({ name, value, ...options });
        },
        remove(name: string, options: CookieOptions) {
          request.cookies.set({ name, value: '', ...options });
          response = NextResponse.next({
            request: { headers: request.headers },
          });
          response.cookies.set({ name, value: '', ...options });
        },
      },
    }
  );

  // Refresh session if expired
  const { data: { user } } = await supabase.auth.getUser();

  // Protect dashboard routes
  if (request.nextUrl.pathname.startsWith('/dashboard')) {
    if (!user) {
      const loginUrl = new URL('/login', request.url);
      loginUrl.searchParams.set('next', request.nextUrl.pathname);
      return NextResponse.redirect(loginUrl);
    }
  }

  // Redirect logged-in users away from auth pages
  if (user && (request.nextUrl.pathname === '/login' || request.nextUrl.pathname === '/register')) {
    return NextResponse.redirect(new URL('/dashboard', request.url));
  }

  return response;
}

export const config = {
  matcher: [
    '/((?!_next/static|_next/image|favicon.ico|.*\\.(?:svg|png|jpg|jpeg|gif|webp)$).*)',
  ],
};
CODE

log_info "Updated middleware.ts with Supabase auth"

# ============================================================================
# Create example migration
# ============================================================================

log_step "Creating example migration..."

mkdir -p supabase/migrations

cat > supabase/migrations/00001_initial_schema.sql << 'SQL'
-- Initial schema migration
-- Run with: supabase db push

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Profiles table (extends Supabase auth.users)
CREATE TABLE IF NOT EXISTS profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email TEXT NOT NULL,
  full_name TEXT,
  avatar_url TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Enable RLS
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

-- Policies
CREATE POLICY "Public profiles are viewable by everyone"
  ON profiles FOR SELECT
  USING (true);

CREATE POLICY "Users can insert their own profile"
  ON profiles FOR INSERT
  WITH CHECK (auth.uid() = id);

CREATE POLICY "Users can update their own profile"
  ON profiles FOR UPDATE
  USING (auth.uid() = id);

-- Auto-create profile on signup
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO profiles (id, email, full_name, avatar_url)
  VALUES (
    NEW.id,
    NEW.email,
    NEW.raw_user_meta_data->>'full_name',
    NEW.raw_user_meta_data->>'avatar_url'
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION handle_new_user();

-- Auto-update updated_at
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_profiles_updated_at
  BEFORE UPDATE ON profiles
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at();
SQL

log_info "Created supabase/migrations/00001_initial_schema.sql"

# ============================================================================
# Update environment files
# ============================================================================

log_step "Updating environment files..."

if [[ -f ".env.example" ]]; then
    if ! grep -q "SUPABASE" .env.example; then
        cat >> .env.example << 'ENV'

# Supabase
NEXT_PUBLIC_SUPABASE_URL=https://your-project.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=your-anon-key
SUPABASE_SERVICE_ROLE_KEY=your-service-role-key
ENV
        log_info "Added Supabase variables to .env.example"
    fi
else
    cat > .env.example << 'ENV'
# Supabase
NEXT_PUBLIC_SUPABASE_URL=https://your-project.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=your-anon-key
SUPABASE_SERVICE_ROLE_KEY=your-service-role-key
ENV
    log_info "Created .env.example with Supabase variables"
fi

# ============================================================================
# Summary
# ============================================================================

echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}  Supabase Starter Pack Installed!${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo "Created:"
echo "  src/lib/supabase/client.ts    - Browser client"
echo "  src/lib/supabase/server.ts    - Server client + admin client"
echo "  src/types/database.ts         - TypeScript types template"
echo "  src/app/auth/callback/route.ts - OAuth callback handler"
echo "  middleware.ts                  - Auth protection middleware"
echo "  supabase/migrations/           - Example migration"
echo ""
echo "Next steps:"
echo "  1. Create a Supabase project: https://supabase.com/dashboard"
echo ""
echo "  2. Copy your project credentials to .env.local:"
echo "     NEXT_PUBLIC_SUPABASE_URL=https://xxx.supabase.co"
echo "     NEXT_PUBLIC_SUPABASE_ANON_KEY=eyJ..."
echo "     SUPABASE_SERVICE_ROLE_KEY=eyJ... (keep secret!)"
echo ""
echo "  3. Install Supabase CLI: npm install -g supabase"
echo ""
echo "  4. Link your project: supabase link --project-ref your-project-ref"
echo ""
echo "  5. Run migrations: supabase db push"
echo ""
echo "  6. Generate types: supabase gen types typescript --local > src/types/database.ts"
echo ""
echo "See CONVENTIONS.md for detailed documentation."
echo ""
