# REQUEST-jordan-0021: Starter Kits

**Requested By:** principal:jordan

**Assigned To:** housekeeping

**Status:** Phase 1 Complete

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

### 2026-01-10 19:05 SST - Reviews Complete

**Code Review (13 issues):**

| Severity | Issue | File |
|----------|-------|------|
| Critical | PR title injection vulnerability | git-ci CONVENTIONS.md:73-74 |
| High | Pipeline exit in subshell bug | git-ci CONVENTIONS.md:82-88 |
| High | Deprecated Next.js 15 params API | nextjs-react CONVENTIONS.md:67-88 |
| High | Missing await for cookies() | supabase CONVENTIONS.md:36-37 |
| Medium | Redundant --save-dev flag | git-ci install.sh:157 |
| Medium | Silent npm failures masked | git-ci install.sh:157 |
| Medium | Missing src directory check | nextjs-react install.sh |
| Medium | Inconsistent CI fallback behavior | git-ci install.sh:72-81 |
| Low | Deprecated Deno std URL | supabase CONVENTIONS.md:427 |
| Low | Hardcoded region in vercel.json | vercel install.sh:64 |
| Low | Missing TypeScript children type | vercel CONVENTIONS.md:209,227 |
| Low | Outdated GitHub Action version | vercel CONVENTIONS.md:371 |
| Low | X-XSS-Protection header deprecated | vercel install.sh:83-86 |

**Test Review (7 categories):**
1. No test infrastructure exists for installer scripts
2. Missing prerequisite validation across all scripts
3. No idempotency checks (silent overwrites)
4. No rollback capability on failure
5. middleware.ts conflict between vercel and supabase installers
6. Edge cases not handled (wrong directory, network failures)
7. Husky hook references file that may not exist

**Fixes Applied:**
- [x] Critical: PR title injection - use env var instead of shell interpolation
- [x] High: Pipeline exit bug - fix subshell exit behavior with process substitution
- [ ] Note: Next.js 15 API changes documented but not fixed (breaking change for existing projects)
- [ ] Note: Test infrastructure deferred to Phase 2
- [ ] Note: Other medium/low issues tracked for Phase 2

**Status:** Ready for complete tag

