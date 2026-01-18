# REQUEST-jordan-0069: myclaude Verbose/Debug Mode and Reliability

**Status:** Ready
**Priority:** High
**Requested By:** jordan
**Assigned To:** captain
**Workstream:** housekeeping
**Created:** 2026-01-18
**Related:** REQUEST-jordan-0068 (Codebase Review - identified some issues)

## Summary

Enhance `./tools/myclaude` with comprehensive verbose/debug mode and improve reliability of service readiness checks.

## Problem Statement

Currently:
1. `--verbose` flag exists but doesn't propagate to child tools/commands
2. When debugging issues, there's no way to get full debug output from all components
3. Service readiness checks may not wait long enough or verify all services
4. Integration between components may have timing issues

## Goals

### Primary Goal: Verbose/Debug Mode

Add `--debug` flag that:
1. Enables verbose output for myclaude itself
2. Passes verbose/debug flags to all child tools and commands
3. Shows full debug output for issue diagnosis
4. Sets appropriate environment variables for downstream tools

### Secondary Goal: Reliability Improvements

Review and improve:
1. Service readiness checks (verify all services are up)
2. Wait for services with configurable timeout
3. Health check verification before proceeding
4. Error handling and recovery

## Implementation

### Phase 1: Debug Mode Enhancement

**Current State:**
```bash
# myclaude has --verbose but it's local only
./tools/myclaude housekeeping captain --verbose
```

**Desired State:**
```bash
# --debug propagates to everything
./tools/myclaude housekeeping captain --debug

# Sets environment variables:
export VERBOSE=true
export DEBUG_HOOKS=1
export LOG_LEVEL=debug
# ... passes --verbose to all tools called
```

**Tasks:**
- [ ] Add `--debug` flag (distinct from `--verbose`)
- [ ] Set `DEBUG=1` environment variable
- [ ] Pass `--verbose` to all tool invocations
- [ ] Log all service health checks in debug mode
- [ ] Show full curl responses in debug mode

### Phase 2: Service Readiness Review

**Audit `check_services()` function:**
- [ ] Does it verify ALL required services?
- [ ] Does it wait long enough for slow starts?
- [ ] Does it handle service startup failures gracefully?
- [ ] Does it verify services are actually responding correctly?

**Improvements:**
- [ ] Add configurable timeout for service startup
- [ ] Add retry with exponential backoff
- [ ] Verify health endpoint returns expected response
- [ ] Check all services (not just agency-service)

### Phase 3: Integration Timing

**Audit startup sequence:**
- [ ] Are there race conditions between service start and use?
- [ ] Do we verify database migrations complete before proceeding?
- [ ] Are environment variables set before they're needed?

## Technical Requirements

### Debug Environment Variables

```bash
# When --debug is passed, set:
export VERBOSE=true           # For tools that check this
export DEBUG_HOOKS=1          # For Claude Code hooks
export LOG_LEVEL=debug        # For agency-service
export DEBUG_MYCLAUDE=1       # Specific to myclaude
```

### Child Tool Invocation

```bash
# Current
"$PROJECT_ROOT/tools/agency-service" start

# With debug
if [[ "$DEBUG" == "true" ]]; then
    "$PROJECT_ROOT/tools/agency-service" start --verbose
fi
```

### Service Readiness Pattern

```bash
# Improved wait_for_service function
wait_for_service() {
    local url="$1"
    local name="$2"
    local timeout="${3:-30}"
    local start_time=$(date +%s)

    while true; do
        if curl -sf "$url/health" > /dev/null 2>&1; then
            [[ "$DEBUG" == "true" ]] && echo "[DEBUG] $name ready"
            return 0
        fi

        local elapsed=$(($(date +%s) - start_time))
        if [[ $elapsed -ge $timeout ]]; then
            log_error "$name failed to start within ${timeout}s"
            return 1
        fi

        [[ "$DEBUG" == "true" ]] && echo "[DEBUG] Waiting for $name... (${elapsed}s)"
        sleep 1
    done
}
```

## Acceptance Criteria

### Phase 1 Complete
- [ ] `--debug` flag implemented
- [ ] Debug output shows all service checks
- [ ] Debug output shows tool invocations
- [ ] Environment variables propagated correctly
- [ ] Tests pass (GREEN)
- [ ] Tagged: `REQUEST-jordan-0069-phase1`

### Phase 2 Complete
- [ ] Service readiness checks improved
- [ ] Configurable timeout implemented
- [ ] All services verified before proceeding
- [ ] Tests pass (GREEN)
- [ ] Tagged: `REQUEST-jordan-0069-phase2`

### Complete
- [ ] Tagged: `REQUEST-jordan-0069-complete`

## Files to Modify

- `tools/myclaude` - Main implementation
- `tools/agency-service` - Add debug support
- `tools/_log-helper` - Debug mode support (if needed)

## Testing

```bash
# Verify debug mode works
./tools/myclaude housekeeping captain --debug 2>&1 | tee debug.log

# Check service timing
time ./tools/myclaude housekeeping captain --debug

# Test with slow service
# (Artificially delay agency-service start)
```

---

## Activity Log

### 2026-01-18 - Created
- Request created based on jordan's feedback
- Identified need for debug propagation and service reliability improvements

