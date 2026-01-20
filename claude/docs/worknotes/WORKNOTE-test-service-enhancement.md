# WORKNOTE: Test Service Enhancement

**Date:** 2026-01-20
**REQUEST:** REQUEST-jordan-0013
**Status:** Complete (impl stage)
**Tag:** REQUEST-jordan-0013-impl

---

## Executive Summary

Enhanced the existing test-service with configuration-based test management, suite discovery, and CI integration. The test-service now serves as the observability layer for tests—analogous to how log-service provides observability for logs.

**Key Outcome:** Tests can now be tracked, analyzed, and executed through a unified service with configuration-driven flexibility.

---

## The Problem

Before this enhancement:
- Test runners and targets were hardcoded
- No way to configure different test suites
- CI ran `bun test` directly with no tracking
- No visibility into test history across runs
- No way to discover and register new test suites

After:
```
Configuration (YAML)
├── Runners (how to execute: bun, jest, etc.)
├── Targets (where tests live: agency-service, starter)
└── Suites (groups of tests: core, integration, etc.)
           ↓
Test Service
├── Discovery (find test directories)
├── Execution (run with tracking)
├── History (all runs recorded)
└── Analysis (stats, flaky detection)
           ↓
CLI / API / CI
```

---

## Implementation

### Phase Breakdown

| Phase | Description | Files | Tests |
|-------|-------------|-------|-------|
| 1 | Config types & service | 2 new | - |
| 2 | Schema updates (target column) | 2 modified | - |
| 3 | Discovery service | 1 new | - |
| 4 | Service & runner updates | 2 modified | - |
| 5 | API routes | 1 modified | - |
| 6 | CLI commands | 1 modified | - |
| 7 | CI integration | 1 modified | - |
| 8 | Documentation | 2 new/modified | - |
| 9 | Tests | 2 new | 41 |

**Total:** 7 new files, 8 modified files, 41 new tests (760 total passing)

### Key Design Decisions

#### 1. YAML Configuration

Chose YAML over JSON for configuration because:
- Human-readable and editable
- Comments supported (for documentation in config)
- Aligns with other config files in the ecosystem

```yaml
version: "1.0"
runners:
  - id: bun
    command: ['bun', 'test']
    outputFormat: bun
targets:
  - id: agency-service
    path: source/services/agency-service
    runner: bun
suites:
  - id: core
    name: Core Tests
    target: agency-service
    path: tests/core
    tags: [unit, fast]
```

#### 2. Separation of Runners, Targets, and Suites

Three-tier configuration model:
- **Runners** - How to execute (bun, jest, custom)
- **Targets** - Where code lives (different paths)
- **Suites** - What to run (groups of tests)

This allows:
- Multiple projects with same runner
- Same target with different suite groupings
- Easy addition of new test frameworks

#### 3. Discovery with Interactive Registration

Two-step suite management:
1. **Discovery** - Scan filesystem for test directories
2. **Registration** - Explicitly add to config

Why not auto-register?
- User control over what's tracked
- Prevents accidental inclusion of scratch/experimental tests
- Config remains explicit and intentional

#### 4. Database Schema Migration

Added `target` column to existing `test_runs` table with:
- Default value for backwards compatibility
- Index for query performance
- Migration runs automatically on service start

```sql
ALTER TABLE test_runs ADD COLUMN target TEXT DEFAULT 'default'
CREATE INDEX idx_test_runs_target ON test_runs(target)
```

### Code Architecture

```
test-service/
├── config/
│   ├── test-config.types.ts   # Zod schemas
│   └── test-config.service.ts # Load/save/validate
├── service/
│   ├── test.service.ts        # Main business logic
│   ├── test-runner.ts         # Execution (legacy + config)
│   └── discovery.service.ts   # Suite discovery
├── repository/
│   └── test-run.repository.ts # Data access
├── routes/
│   └── test.routes.ts         # HTTP endpoints
└── types.ts                   # Domain types
```

---

## Technical Highlights

### Zod Schema Validation

Configuration validated at load time:

```typescript
export const testRunnerSchema = z.object({
  id: z.string().regex(safeIdPattern),
  command: z.array(z.string()).min(1),
  outputFormat: z.enum(['bun', 'jest', 'tap', 'raw']),
});
```

Benefits:
- Type-safe configuration
- Clear error messages
- Runtime validation
- TypeScript integration

### Configurable Test Runner

New `runTestsWithConfig()` function alongside legacy `runTests()`:

```typescript
export async function runTestsWithConfig(options: ConfigurableRunnerOptions): Promise<BunTestOutput> {
  const { projectRoot, suite, suitePath, target, runner } = options;

  // Resolve working directory from target
  const cwd = join(projectRoot, target.path);

  // Build command from runner config
  const args = [...runner.command.slice(1)];

  // Execute with configurable command
  const proc = spawn(runner.command[0], args, { cwd });
  // ...
}
```

### CI Integration

GitHub Actions workflow now:
1. Starts agency-service
2. Waits for health check
3. Runs tests through test-service
4. Reports results via CLI
5. Cleans up

```yaml
- name: Run tests via test-service
  run: |
    ./tools/agency-service test run all ci github-actions
    RESULT=$(./tools/agency-service test latest | jq -r '.status')
    if [ "$RESULT" = "failed" ]; then exit 1; fi
```

---

## Metrics

| Metric | Value |
|--------|-------|
| Lines added | ~2,100 |
| New tests | 41 |
| Total tests | 760 |
| New endpoints | 7 |
| New CLI commands | 5 |
| Phases completed | 9 |
| Implementation time | Single session |

---

## For the Book

### Key Themes

1. **Observability as First-Class Citizen**
   - Tests need the same observability as logs
   - Track history, analyze patterns, detect issues
   - Service-based approach vs. one-off execution

2. **Configuration Over Convention (Sometimes)**
   - When flexibility matters more than simplicity
   - YAML for human-editable config
   - Zod for validation

3. **Incremental Enhancement**
   - Legacy runner preserved
   - Config-based runner layered on top
   - Backwards compatible schema migration

4. **Multi-Target Testing**
   - Same service tests multiple codebases
   - Enables monorepo and multi-project testing
   - CI integration across all targets

### Quotable Patterns

**"Runners, Targets, Suites"** - The three-tier configuration model that enables flexible test management.

**"Discovery + Registration"** - Find automatically, track explicitly. Prevents config pollution while reducing manual setup.

**"Observability for Tests"** - Treating test execution as a first-class observable event, not just a pass/fail gate.

### Case Study Angle

This work demonstrates:
- How to enhance an existing service incrementally
- Schema migration strategies in SQLite
- Configuration-driven architecture
- Integration between CLI, API, and CI

---

## Files Changed

### New Files (7)
| File | Purpose | Lines |
|------|---------|-------|
| `config/test-config.types.ts` | Zod schemas | 85 |
| `config/test-config.service.ts` | Config service | 190 |
| `service/discovery.service.ts` | Suite discovery | 240 |
| `.agency/test-config.yaml` | Default config | 65 |
| `claude/docs/TESTING.md` | Documentation | 200 |
| `tests/test-service/config.test.ts` | Config tests | 240 |
| `tests/test-service/discovery.test.ts` | Discovery tests | 190 |

### Modified Files (8)
| File | Changes |
|------|---------|
| `types.ts` | Added target field |
| `test-run.repository.ts` | Target column + migration |
| `test.service.ts` | Config/discovery integration |
| `test-runner.ts` | runTestsWithConfig() |
| `test.routes.ts` | 7 new endpoints |
| `tools/agency-service` | 5 new commands |
| `.github/workflows/test.yml` | CI through service |
| `CLAUDE.md` | Reference to TESTING.md |

---

## References

- REQUEST-jordan-0013: Implementation plan
- claude/docs/TESTING.md: User documentation
- .agency/test-config.yaml: Configuration example
- Tag: REQUEST-jordan-0013-impl
