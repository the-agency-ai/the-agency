# Code Review Findings: Agency-Service

**Request:** REQUEST-jordan-0015
**Reviewed By:** housekeeping (primary) + subagent (parallel)
**Date:** 2026-01-10
**Services:** bug-service, messages-service, log-service, test-service, core

---

## Executive Summary

The agency-service demonstrates solid architectural principles with clean layered architecture. However, several security, performance, and code quality issues were identified.

**Totals:** 2 Critical, 5 High, 6 Medium, 5 Low

---

## Critical Issues

### 1. JWT Authentication Not Validated
**File:** `src/core/middleware/auth.middleware.ts:107-120`
**Severity:** CRITICAL

The `decodeJwt` function decodes tokens WITHOUT cryptographic verification. The `_secret` parameter is unused.

```typescript
function decodeJwt(token: string, _secret?: string): Record<string, string> {
  // TODO: Use a proper JWT library for validation
  const parts = token.split('.');
  const payload = JSON.parse(atob(parts[1]));
  return payload;
}
```

**Impact:** Attackers can forge tokens since signature verification is not performed.
**Fix:** Use `jose` or `jsonwebtoken` library to verify signature.

### 2. Missing Input Validation on X-Agency-User Header
**File:** `src/core/middleware/auth.middleware.ts:46-53`
**Severity:** HIGH (Critical area)

```typescript
const [type, name] = userHeader.split(':');
user = {
  type: (type as AuthUser['type']) || 'agent',
```

**Impact:** `type` is cast without validation - could bypass `requireType` middleware.
**Fix:** Validate `type` is one of: `principal`, `agent`, `system`.

---

## High Severity Issues

### 3. Race Condition in Bug ID Sequence
**File:** `src/embedded/bug-service/repository/bug.repository.ts:117-143`

TOCTOU race: Two concurrent requests could get same `next_id`.

**Fix:** Use transaction or `INSERT...ON CONFLICT DO UPDATE...RETURNING`.

### 4. N+1 Query Pattern in Message Repository
**File:** `src/embedded/messages-service/repository/message.repository.ts:268-279`

```typescript
for (const row of rows) {
  const recipientRows = await this.db.query(...);  // N+1!
}
```

**Impact:** 51 queries for 50 messages.
**Fix:** Batch fetch recipients with `WHERE message_id IN (...)`.

### 5. Null Dereference in Log Repository
**File:** `src/embedded/log-service/repository/log.repository.ts:212-216`

```typescript
return rowToLogEntry(row!);  // Non-null assertion without check
```

**Fix:** Add explicit null check.

### 6. Bug Routes Missing Error Handler
**File:** `src/embedded/bug-service/routes/bug.routes.ts`

No try-catch blocks on route handlers (unlike test-service).

**Fix:** Add try-catch or use Hono's `onError` middleware.

### 7. Unvalidated Body Parsing
**File:** `src/embedded/bug-service/routes/bug.routes.ts:93-96, 123-126`

`/status` and `/assign` endpoints use `c.req.json()` directly without Zod validation.

**Fix:** Create Zod schemas and use `zValidator` consistently.

---

## Medium Severity Issues

### 8. Unused Queue Parameter
**File:** `src/embedded/messages-service/service/message.service.ts:22-26`

`queue` parameter declared but never used.

### 9. Loose Type Casting
**Files:** All repositories

```typescript
status: row.status as Bug['status']  // No runtime validation
```

**Fix:** Add Zod validation before casting.

### 10. Inconsistent Response Formats
Error responses differ across services:
- `{ error, message }` vs `{ error: 'string' }` vs `{ success, bugId }`

### 11. Duplicated Time Parsing
**Files:** `message.repository.ts:372-398`, `log.repository.ts:473-497`

`parseSince` method duplicated identically.

**Fix:** Extract to `core/lib/time.ts`.

### 12. Batch Insert Without Transaction
**File:** `src/embedded/log-service/repository/log.repository.ts:222-229`

```typescript
for (const entry of entries) {
  await this.create(entry);  // 1000 separate commits possible
}
```

**Fix:** Wrap in `this.db.transaction()`.

### 13. Command Injection Risk in Test Runner
**File:** `src/embedded/test-service/service/test-runner.ts:120-128`

`suite` and `testFile` from user input passed to `spawn()`.

**Fix:** Validate suite is alphanumeric, testFile is within tests dir.

---

## Low Severity Issues

### 14. Hardcoded Version String
**File:** `src/core/lib/logger.ts:86`
Version `0.1.0` hardcoded, not read from package.json.

### 15. Magic Numbers
Various files have unexplained magic numbers (1000ms, 120000ms, etc).

### 16. Missing Negative Test Cases
Tests only cover happy paths - no constraint violations, connection failures.

### 17. Commented Out Code
**File:** `src/core/lib/logger.ts:50-52`
Empty if block with incomplete functionality.

### 18. Unused Import
**File:** `src/embedded/test-service/service/test.service.ts:8`
DatabaseAdapter import could be simplified.

---

## Positive Observations

1. **Clean Architecture** - Layered routes -> service -> repository
2. **Consistent Patterns** - All services follow same structure
3. **Good TypeScript** - Proper interfaces and generics
4. **Zod Validation** - Most endpoints use type-safe validation
5. **Comprehensive Tests** - Good repository/service coverage
6. **Structured Logging** - Consistent Pino usage
7. **Database Adapter** - Vendor-neutral interface
8. **Full-Text Search** - FTS5 in log service

---

## Recommended Fix Priority

**Immediate (before release):**
- [ ] #2 Validate X-Agency-User header type
- [ ] #6 Add try-catch to bug routes
- [ ] #7 Add Zod validation to status/assign

**Soon:**
- [ ] #3 Fix race condition in bug ID sequence
- [ ] #4 Fix N+1 query pattern
- [ ] #5 Fix null dereference

**Tech Debt:**
- [ ] #1 Implement proper JWT validation (separate task)
- [ ] #9-18 Code quality improvements

---

## Test Review Summary

**Coverage:** 151 tests passing
**Layers tested:** Repository (primary), Service, Routes (partial)

**Gaps:**
- No negative test cases (error paths)
- No integration tests
- No load/stress tests
- Routes tests incomplete for some services

---

*Generated by housekeeping agent for REQUEST-jordan-0015*
