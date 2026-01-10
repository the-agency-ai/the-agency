# REQUEST-jordan-0021: Starter Kits

**Requested By:** principal:jordan

**Assigned To:** housekeeping

**Status:** Phase 1 Complete (impl)

**Priority:** High (Tonight - before 21:00)

**Created:** 2026-01-10 17:45 SST

## Summary

Create starter kits that provide framework-specific conventions and patterns for common technology stacks. Phase 1 focuses on documentation/conventions, Phase 2 will add working templates.

---

## Phase 1: Documentation (Tonight)

Convention docs with examples for:

### 1. Git CI ✓
- [x] GitHub Actions workflow patterns (ci.yml, pr-check.yml, release.yml)
- [x] Pre-commit hook integration (Husky + lint-staged)
- [x] Branch protection recommendations
- [x] CI/CD pipeline conventions
- [x] Turnkey installer: `./claude/starter-packs/git-ci/install.sh`

### 2. Next.js + React ✓
- [x] Project structure conventions (App Router)
- [x] Component patterns (Button, forms)
- [x] API route conventions (explicit operations)
- [x] State management recommendations (SWR, Zustand)
- [x] Turnkey installer: `./claude/starter-packs/nextjs-react/install.sh`

### 3. Vercel ✓
- [x] Deployment configuration (vercel.json)
- [x] Environment variable management
- [x] Preview deployment patterns
- [x] Edge function conventions (middleware)
- [x] Security headers
- [x] Turnkey installer: `./claude/starter-packs/vercel/install.sh`

### 4. Supabase ✓
- [x] Database schema conventions
- [x] Auth integration patterns
- [x] Row-level security patterns
- [x] Client/server helpers
- [x] Turnkey installer: `./claude/starter-packs/supabase/install.sh`

---

## Phase 2: Templates (Later)

Working starter templates for each kit:
- React Native
- PostHog
- Apple Platforms (macOS, iOS, iPadOS, watchOS, visionOS)

---

## File Structure

```
claude/starter-packs/
├── git-ci/
│   └── CONVENTIONS.md
├── nextjs-react/
│   └── CONVENTIONS.md
├── vercel/
│   └── CONVENTIONS.md
├── supabase/
│   └── CONVENTIONS.md
└── (phase 2 additions)
```

---

## Activity Log

### 2026-01-10 17:45 SST - Created
- User prioritized 4 starter kits for tonight
- Phase 1: docs, Phase 2: templates
- Target: complete before 21:00

### 2026-01-10 18:45 SST - Phase 1 Complete
- All 4 starter packs created with turnkey installers
- Git CI: workflows, hooks, branch protection
- Next.js + React: App Router, explicit APIs, state management
- Vercel: config, security headers, middleware
- Supabase: clients, auth, RLS, migrations
- Total: 3,129 lines of conventions and installers

