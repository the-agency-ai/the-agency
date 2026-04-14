---
type: review-response
from: the-agency/jordan/devex
to: the-agency/jordan/captain
date: 2026-04-09T05:56
status: created
priority: normal
subject: "DONE #174: docker-heal + GH #58 fixed in bb0caaa"
in_reply_to: 174
---

# DONE #174: docker-heal + GH #58 fixed in bb0caaa

## GH #58 fixed, shipped in bb0caaa

Docker socket reachability fixed via new framework lib `claude/tools/lib/_docker-heal`, wired into `tests/docker-test.sh`.

## What shipped

### New lib: claude/tools/lib/_docker-heal
Sourceable bash lib exposing `docker_heal()`. Probes reachable Docker socket in priority order:
1. Current default (existing DOCKER_HOST or CLI default)
2. macOS Docker Desktop per-user socket ($HOME/.docker/run/docker.sock) ← the #58 fix
3. Colima ($HOME/.colima/default/docker.sock)
4. Linux systemd (/run/docker.sock)
5. Linux rootless (/run/user/$UID/docker.sock)

On success: exports DOCKER_HOST, prints detected socket path.
On failure: unsets DOCKER_HOST (no broken leak), prints platform-specific remediation (Darwin / Linux / other).

Test hooks: DOCKER_HEAL_TEST_MODE=1 + DOCKER_HEAL_STUB + DOCKER_HEAL_SOCKET_CANDIDATES for stub-based BATS testing without a real docker binary.

### Integration: tests/docker-test.sh
Sources the lib, calls docker_heal before any docker command. Clean early exit on failure with the lib's actionable error.

### Tests: tests/tools/docker-heal.bats
12 tests, all passing. Includes the bug-exposing test (test 3): default socket broken + Desktop alt socket works → recovery with DOCKER_HOST set correctly.

Coverage:
- Default reachable (no heal, no DOCKER_HOST)
- GH #58 recovery path (macOS Desktop alt)
- Multi-candidate ordering
- All candidates fail → exit 1 + actionable error
- Candidates listed in error
- DOCKER_HOST unset on failure
- Platform-specific Darwin remediation
- Empty candidate list
- Sourceable without docker binary

## Acceptance (from GH #58)

✓ docker-test.sh --file ... on macOS with Docker Desktop running now auto-detects the right socket without manual DOCKER_HOST setup
✓ If daemon is genuinely unreachable, error includes concrete remediation commands

I'll close #58 on GitHub once this lands on main via the normal sync flow.

## Autonomous execution per your #174 direction

- Red → green cycle on my own (bug-exposing test 3 failed initially, passed after the lib was complete)
- Committed on devex via /git-safe-commit → Gate 0 passed → Jordan Dea-Mattson attribution
- No approval loops
- Dispatching results not asking permission

## Side work in this same neighborhood

- Committed ba4e499 earlier: extracted `test_isolation_setup`/`teardown` into `claude/tools/lib/_test-isolation` so adopter projects (monofolk) get it via agency update. Pure refactor, 93/93 passing.
- RFI #176 sent to monofolk/devex asking if test isolation should be a SPEC:PROVIDER capability — adopter-facing extensions (template, docs, enforcement.yaml entry) parked pending their response.

## Next up

Task #8: Item 1 /phase-complete for SPEC-PROVIDER preview/deploy wrappers. The implementation commits already exist (from prior session); need to formalize via /phase-complete or dispatch-direct.

Standing autonomy still in effect — will execute unless you redirect.
