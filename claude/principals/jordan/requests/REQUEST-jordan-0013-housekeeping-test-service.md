# REQUEST-jordan-0013: Test Service + TestBench

**Requested By:** principal:jordan

**Assigned To:** housekeeping

**Status:** Open

**Priority:** High

**Created:** 2026-01-10 14:45 SST

**Updated:** 2026-01-10 14:45 SST

## Summary

Build **test-service** - a test execution and history service that makes test results accessible to both humans (via TestBench UI) and agents (via API/CLI).

**Vision:** Environment observability for agents and principals. An agent investigating a failure should be able to query test history, trigger targeted tests, and understand test health - just like a human would use a CI dashboard.

## Use Cases

### For Agents
```
"Run bug-service tests"
"When did this test last pass?"
"Show me flaky tests in the last week"
"What tests are failing on main?"
"Run just the authentication tests"
```

### For Principals (via TestBench UI)
- View test run history
- Trigger test suites manually
- See pass/fail trends
- Drill down into failures
- Identify flaky tests

### Future (Cloud)
- CI/CD integration
- Cross-environment test results (dev/staging/prod)
- Test coverage tracking
- Performance regression detection

## Architecture

### Embedded Service Pattern
```
services/agency-service/
  src/embedded/
    test-service/
      index.ts
      routes.ts
      service/
        test.service.ts
        test-runner.ts          # Executes tests via Bun
      repository/
        test-run.repository.ts
        test-result.repository.ts
      types.ts
```

### API Design

```
# Test Execution
POST   /api/test/run                 # Trigger test run
POST   /api/test/run/:suite          # Run specific suite (core, bug, etc.)
GET    /api/test/run/:runId          # Get run status/results
DELETE /api/test/run/:runId          # Cancel running test

# Test History
GET    /api/test/runs                # List test runs
GET    /api/test/runs/latest         # Latest run per suite
GET    /api/test/history/:testName   # History for specific test

# Test Discovery
GET    /api/test/suites              # List available test suites
GET    /api/test/suites/:suite       # List tests in suite

# Statistics
GET    /api/test/stats               # Overall test health
GET    /api/test/flaky               # Flaky test report
```

### Data Models

```typescript
interface TestSuite {
  name: string;                  // e.g., "core", "bug-service"
  path: string;                  // e.g., "tests/core"
  testCount: number;
}

interface TestRun {
  id: string;                    // UUID
  suite: string;                 // "all" | "core" | "bug-service" | etc.
  status: 'pending' | 'running' | 'passed' | 'failed' | 'cancelled';
  triggeredBy: {
    type: 'principal' | 'agent' | 'system' | 'ci';
    name: string;
  };
  startedAt: Date;
  completedAt?: Date;
  duration?: number;             // ms

  // Results
  total: number;
  passed: number;
  failed: number;
  skipped: number;

  // Git context (optional)
  gitBranch?: string;
  gitCommit?: string;
}

interface TestResult {
  runId: string;
  testName: string;              // Full test name
  suite: string;
  status: 'passed' | 'failed' | 'skipped';
  duration: number;              // ms
  error?: {
    message: string;
    stack?: string;
    expected?: string;
    actual?: string;
  };
}
```

### Test Runner Integration

Uses Bun's test runner with JSON output:

```typescript
// test-runner.ts
async function runTests(suite: string): Promise<TestRun> {
  const testPath = suite === 'all'
    ? 'tests/'
    : `tests/${suite}/`;

  const proc = Bun.spawn(['bun', 'test', testPath, '--reporter=json'], {
    cwd: SERVICE_DIR,
    stdout: 'pipe',
    stderr: 'pipe',
  });

  // Parse JSON output, store results
  // ...
}
```

### Storage Strategy

**Local (SQLite):**
- Store test runs and results in SQLite
- Keep history for configurable period (default: 30 days)
- Fast queries for local development

**Cloud (Future):**
- PostgreSQL for persistent history
- Integration with CI systems (GitHub Actions, etc.)
- Webhook notifications

## CLI Integration

```bash
# Run tests
./tools/agency-service test                    # Run all tests
./tools/agency-service test core               # Run core tests
./tools/agency-service test bug                # Run bug-service tests

# Sub-service shorthand
./tools/agency-service bug test                # Same as test bug

# Query test history
./tools/agency-service test runs               # List recent runs
./tools/agency-service test runs --suite bug   # Filter by suite
./tools/agency-service test latest             # Latest results

# Test health
./tools/agency-service test stats              # Pass rate, etc.
./tools/agency-service test flaky              # Flaky tests

# Specific test
./tools/agency-service test history "should create bug"
```

## TestBench UX (AgencyBench)

### Features
- Test suite browser (tree view)
- Run tests with one click
- Live test execution progress
- Pass/fail history graphs
- Failure drill-down with stack traces
- Flaky test identification
- Filter by status, suite, time range

### Layout
```
┌─────────────────────────────────────────────────────────────┐
│ TestBench                              [Run All] [Run Core] │
├──────────────────┬──────────────────────────────────────────┤
│ Suites           │ Latest Run: 2026-01-10 14:30            │
│ ─────────────────│ Status: ✅ Passed (71/71)                │
│ ▼ core (15)      │ Duration: 2.38s                         │
│   ✅ config      │──────────────────────────────────────────│
│   ✅ database    │ Test Results:                           │
│   ✅ queue       │ ✅ should create bug with required...   │
│ ▼ bug-service    │ ✅ should return 400 for missing...     │
│   ✅ repository  │ ✅ should list bugs                     │
│   ✅ service     │ ✅ should filter by workstream          │
│   ✅ routes      │ ...                                     │
│                  │──────────────────────────────────────────│
│ [History]        │ Recent Runs:                            │
│ [Flaky Tests]    │ ✅ 14:30 - 71/71 (2.38s)               │
│                  │ ✅ 12:15 - 71/71 (2.41s)               │
│                  │ ❌ 10:02 - 70/71 (2.55s) ← Click to see│
└──────────────────┴──────────────────────────────────────────┘
```

## Implementation Phases

### Phase 1: Core test-service
- [ ] Create `embedded/test-service/` structure
- [ ] Implement test run and result schemas
- [ ] Implement `test-run.repository.ts`
- [ ] Implement `test-result.repository.ts`
- [ ] Implement `test-runner.ts` (Bun test execution)
- [ ] Implement `test.service.ts`
- [ ] Implement routes (`/api/test/*`)

### Phase 2: CLI Integration
- [ ] Update `./tools/agency-service test` to use service
- [ ] Add `./tools/agency-service test runs` command
- [ ] Add `./tools/agency-service test stats` command
- [ ] Add `./tools/agency-service <service> test` shorthand

### Phase 3: TestBench UX
- [ ] Create TestBench app in AgencyBench
- [ ] Implement test suite browser
- [ ] Implement run trigger UI
- [ ] Implement results display
- [ ] Implement history view

### Phase 4: Advanced Features
- [ ] Flaky test detection algorithm
- [ ] Test coverage integration
- [ ] CI/CD webhook integration
- [ ] Multi-environment support

## Acceptance Criteria

**Phase 1:**
- [ ] `POST /api/test/run` triggers tests and returns run ID
- [ ] `GET /api/test/run/:id` returns run status and results
- [ ] Test results are persisted to database
- [ ] `./tools/agency-service test` uses the service

**Phase 2:**
- [ ] `./tools/agency-service test runs` shows history
- [ ] `./tools/agency-service bug test` works

**Overall:**
- [ ] Agents can trigger and query tests via API
- [ ] TestBench UI provides human-friendly test management
- [ ] Test history is retained for configurable period

## Dependencies

- REQUEST-jordan-0011 (agency-service foundation) - COMPLETE
- REQUEST-jordan-0012 (log-service) - For correlating test failures with logs

## Technical Notes

### Bun Test JSON Reporter

Bun's test runner can output JSON for parsing:

```bash
bun test --reporter=json
```

Output includes test names, durations, pass/fail status, and error details.

### Flaky Test Detection

A test is considered flaky if:
- It has both passed and failed in the last N runs
- Pass rate is between 10% and 90%
- Minimum 5 runs for statistical significance

```sql
SELECT test_name,
       SUM(CASE WHEN status = 'passed' THEN 1 ELSE 0 END) as passes,
       SUM(CASE WHEN status = 'failed' THEN 1 ELSE 0 END) as failures,
       COUNT(*) as total
FROM test_results
WHERE created_at > datetime('now', '-7 days')
GROUP BY test_name
HAVING passes > 0 AND failures > 0
ORDER BY failures DESC;
```

### Test Suite Discovery

Scan test directories to discover available suites:

```typescript
async function discoverSuites(): Promise<TestSuite[]> {
  const testsDir = path.join(SERVICE_DIR, 'tests');
  const entries = await fs.readdir(testsDir, { withFileTypes: true });

  return entries
    .filter(e => e.isDirectory())
    .map(e => ({
      name: e.name,
      path: `tests/${e.name}`,
      testCount: countTestFiles(`tests/${e.name}`),
    }));
}
```

---

## Activity Log

### 2026-01-10 14:45 SST - Created
- Request created based on discussion about environment observability
- Vision: queryable test execution for both agents and humans
- Supports future CI/CD integration and multi-environment testing
