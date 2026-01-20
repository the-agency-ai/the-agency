# Testing Guide

The Agency uses a test-service for test execution, tracking, and analysis. This provides observability for tests similar to how log-service provides observability for logs.

## Overview

The test-service provides:

- **Configuration-based test management** - Define runners, targets, and suites in YAML
- **Suite discovery** - Automatically find test directories
- **Test execution tracking** - Record all test runs with results
- **Statistics and analysis** - Pass rates, flaky test detection
- **CI integration** - Run tests through the service in CI pipelines

## Configuration

Test configuration is stored in `.agency/test-config.yaml`:

```yaml
version: "1.0"

runners:
  - id: bun
    command:
      - bun
      - test
    outputFormat: bun

targets:
  - id: agency-service
    path: source/services/agency-service
    runner: bun
    description: Main agency service tests

  - id: starter
    path: test/the-agency-starter/source/services/agency-service
    runner: bun
    description: Starter kit tests

suites:
  - id: all
    name: All Tests
    target: agency-service
    path: tests
    tags: [all]
    enabled: true

  - id: core
    name: Core Tests
    target: agency-service
    path: tests/core
    tags: [unit, fast]
    enabled: true
```

### Runners

Runners define how to execute tests:

| Field | Description |
|-------|-------------|
| `id` | Unique identifier |
| `command` | Command array (first element is executable) |
| `outputFormat` | Parser to use (bun, jest, tap, raw) |

### Targets

Targets define where tests are located:

| Field | Description |
|-------|-------------|
| `id` | Unique identifier |
| `path` | Path relative to project root |
| `runner` | Runner ID to use |
| `description` | Optional description |

### Suites

Suites define groups of tests:

| Field | Description |
|-------|-------------|
| `id` | Unique identifier |
| `name` | Human-readable name |
| `target` | Target ID |
| `path` | Path relative to target (e.g., `tests/core`) |
| `tags` | Optional tags for filtering |
| `enabled` | Whether suite is active |

## CLI Reference

### Running Tests

```bash
# Run all tests
./tools/agency-service test run

# Run specific suite
./tools/agency-service test run core

# Run with CI trigger
./tools/agency-service test run all ci github-actions
```

### Viewing Results

```bash
# Get latest test run
./tools/agency-service test latest

# Get specific test run
./tools/agency-service test get <run-id>

# Get only failures
./tools/agency-service test get <run-id> failures

# List recent runs
./tools/agency-service test list

# Filter by suite/status
./tools/agency-service test list --suite core --status failed
```

### Statistics

```bash
# Overall stats
./tools/agency-service test stats

# Stats for suite
./tools/agency-service test stats core

# Find flaky tests
./tools/agency-service test flaky
```

### Configuration Management

```bash
# Show configuration
./tools/agency-service test config

# List targets
./tools/agency-service test targets

# List runners
./tools/agency-service test runners
```

### Suite Discovery

```bash
# Discover all suites
./tools/agency-service test discover

# Discover in specific target
./tools/agency-service test discover agency-service

# Register a discovered suite
./tools/agency-service test register my-suite "My Suite" agency-service tests/my-suite
```

## API Reference

### Test Execution

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/api/test/run/execute` | POST | Start and execute test run |
| `/api/test/run/start` | POST | Start run without executing |
| `/api/test/run/execute/:id` | POST | Execute pending run |
| `/api/test/run/cancel/:id` | POST | Cancel running test |

### Test Queries

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/api/test/run/list` | GET | List runs with filtering |
| `/api/test/run/latest` | GET | Get most recent run |
| `/api/test/run/get/:id` | GET | Get run with results |
| `/api/test/run/failures/:id` | GET | Get failed results |

### Statistics

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/api/test/stats` | GET | Get statistics |
| `/api/test/flaky` | GET | Get flaky tests |
| `/api/test/suites` | GET | Get available suites |

### Configuration

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/api/test/config/get` | GET | Get configuration |
| `/api/test/config/reload` | POST | Reload from disk |
| `/api/test/discover` | GET | Discover suites |
| `/api/test/suite/register` | POST | Register suite |
| `/api/test/suite/unregister` | POST | Unregister suite |
| `/api/test/target/list` | GET | List targets |
| `/api/test/runner/list` | GET | List runners |

## Discovery Workflow

1. **Discover test directories**:
   ```bash
   ./tools/agency-service test discover
   ```

2. **Review discovered suites** - Shows unregistered suites

3. **Register desired suites**:
   ```bash
   ./tools/agency-service test register my-suite "My Suite" agency-service tests/my-suite
   ```

4. **Configuration is saved** - Suite added to `.agency/test-config.yaml`

## CI Integration

The test workflow (`.github/workflows/test.yml`) runs tests through the test-service:

1. Starts agency-service
2. Waits for health check
3. Runs tests via CLI with CI trigger
4. Reports results
5. Stops service

Test runs from CI are tagged with:
- `triggeredByType: ci`
- `triggeredByName: github-actions`

This allows filtering CI runs separately from local runs.

## Trigger Types

| Type | Description |
|------|-------------|
| `principal` | Triggered by human |
| `agent` | Triggered by Claude agent |
| `system` | Triggered by system (default) |
| `ci` | Triggered by CI pipeline |

## Best Practices

1. **Use configuration** - Define all test suites in config rather than ad-hoc

2. **Tag appropriately** - Use tags for filtering (unit, integration, slow)

3. **Review flaky tests** - Regularly check `test flaky` for unstable tests

4. **Clean old runs** - Use `test cleanup` to remove old data

5. **Use CI triggers** - Mark CI runs appropriately for better tracking
