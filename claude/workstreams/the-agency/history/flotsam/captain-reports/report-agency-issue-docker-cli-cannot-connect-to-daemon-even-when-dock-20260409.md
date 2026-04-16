---
report_type: agency-issue
issue_type: bug
filing_agent: the-agency/jordan/captain
filed_by: jordan
date_filed: 2026-04-09
target_repo: the-agency-ai/the-agency
github_issue: https://github.com/the-agency-ai/the-agency/issues/58
github_issue_number: 58
status: open
---

# Docker CLI cannot connect to daemon even when Docker Desktop is running

**Filed:** 2026-04-09T01:07:59Z
**Target:** [the-agency-ai/the-agency](https://github.com/the-agency-ai/the-agency)
**Issue:** [#58](https://github.com/the-agency-ai/the-agency/issues/58)
**Type:** bug
**Status:** open

## Filed Body

**Type:** bug

**Type:** bug / devex blocker

## Problem

Running `./tests/docker-test.sh` fails with:

```
failed to connect to the docker API at unix:///var/run/docker.sock; check if the path is correct and if the daemon is running: dial unix /var/run/docker.sock: connect: no such file or directory
```

even when Docker Desktop is running on the host. This blocks every test run that requires container isolation, including the BATS suite verification path used by `worktree-sync.bats`, `run-in.bats`, and all ISCP tests in `docker-test.sh --iscp-only`.

## Why this is a devex blocker

1. **No self-heal path.** When Docker Desktop starts on macOS, the `docker` CLI uses a context that points somewhere other than `/var/run/docker.sock` (probably `~/.docker/run/docker.sock`). The CLI can't reach the daemon without the right `DOCKER_HOST` or context selection. The agent has no way to detect or fix this without principal intervention.
2. **Framework test verification is blocked.** Every test-writing session ends with a 'run this in docker' step that may silently fail for reasons unrelated to the test. Today this happened during the `run-in` and `#57` test builds — the tests had to be run via raw `bats` instead of the isolation container.
3. **Principal-intervention tax.** Every time this fails, the agent has to escalate to the principal to check Docker. That's fine when the principal is at the keyboard, but it's a hard block when they're on remote control or asleep.

## Expected

At least one of these should be true:

- (a) `docker-test.sh` auto-detects a running Docker Desktop and sets `DOCKER_HOST` or selects the right context before running tests.
- (b) `docker-test.sh` prints an actionable fix-it-yourself diagnostic if the daemon is unreachable — e.g., 'Run: docker context use desktop-linux' or 'Set DOCKER_HOST=unix://$HOME/.docker/run/docker.sock'.
- (c) A framework tool `docker-heal` (or similar) that an agent can invoke to get Docker talking without principal help.

## Acceptance criteria

- `./tests/docker-test.sh --file tests/tools/iscp-check.bats` runs successfully from a fresh shell on a Mac with Docker Desktop running, without manual DOCKER_HOST or context setup.
- If the daemon is genuinely not running, the error message includes a concrete remediation command.

## Related

- Flag #53 (captured today) — 'Docker Desktop is running but docker CLI cannot connect'
- Dispatch #171 (devex escalation) — /session-resume reliance on worktree-sync; docker test gap would have made the #57 red-green cycle impossible without falling back to local bats.

## Response Log

_(append responses, comments, and state changes here as they occur)_

- **2026-04-09:** Filed via `agency-issue file`. Issue created at https://github.com/the-agency-ai/the-agency/issues/58
