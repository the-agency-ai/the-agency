# DevEx Workstream

## Scope

DevEx owns the developer experience for agents and principals working in TheAgency:
- Test infrastructure (isolation, Docker, BATS, CI)
- Commit workflow (pre-commit hooks, QGR enforcement, smart scoping)
- Permission model (settings-template.json, safe operation pre-approval)
- Tooling ergonomics (agency-init, agent-create, worktree lifecycle)
- Agent bootstrap (cold start, handoff, identity resolution)

## Boundaries

- **Owns:** `tests/`, `claude/tools/commit-precheck`, `.git/hooks/pre-commit`, `tests/Dockerfile`, `tests/docker-test.sh`, `tests/tools/test_helper.bash`
- **Contributes to:** `claude/tools/` (ergonomic improvements), `.claude/settings.json` (permission model), `claude/config/settings-template.json`
- **Does NOT own:** ISCP tools (iscp workstream), application workstreams (mdpal, mock-and-mark), agent class definitions

## Review Discipline

All test infrastructure changes get full QG. Pre-commit hook changes are especially sensitive — a broken hook blocks all agents.

## Key Context

- ISCP built the foundation: `test_helper.bash`, `Dockerfile`, `docker-test.sh`, `ISCP_DB_PATH` override
- 32 BATS test files total, only 7 have isolation helpers
- Pre-commit hook (`commit-precheck`) runs ALL tests unconditionally — the burning problem
- Friction points catalog: `usr/jordan/captain/friction-points-20260405.md`
