# REQUEST-jordan-0030: Starter Onboarding Fixes

**Principal:** jordan
**Workstream:** housekeeping
**Agent:** housekeeping
**Created:** 2026-01-10
**Status:** open

## Summary

Fix critical onboarding issues discovered during the-agency-starter v1.0.2/v1.0.3 rollout. Users experienced friction that required manual intervention (including nuking Claude Code installs) which is unacceptable.

## Issues

### 1. Claude Code Already Installed Conflict

**Problem:** When users already have Claude Code installed, the installer correctly skips installation, but the `/welcome` command doesn't work. We had to go through an involved process of nuking their Claude Code install - this is NOT an option going forward.

**Root Cause:** TBD - need to investigate why `/welcome` doesn't register when Claude Code pre-exists.

**Proposed Fix:**
- Investigate the slash command registration mechanism
- Ensure `.claude/commands/` is recognized regardless of install method
- Add verification step after install to confirm commands are available
- Provide fallback instructions if commands aren't working

### 2. Principal Hardcoded as "jordan"

**Problem:** Many places have "jordan" hardcoded as the principal. During onboarding, we don't ask who the principal is, so new users end up with references to "jordan" throughout their install.

**Affected Areas:**
- `claude/principals/jordan/` directory structure
- Request files referencing `jordan`
- Configuration files
- Potentially tool defaults

**Proposed Fix:**
- `/welcome` interview MUST ask for principal name as first step
- Create `./tools/setup-principal` that:
  - Asks for principal name
  - Renames `claude/principals/jordan/` to `claude/principals/{name}/`
  - Updates all references
  - Sets environment variable

### 3. Environment Variable for Principal Name

**Problem:** We need a consistent way to reference the current principal across tools and scripts.

**Proposed Fix:**
- Define `AGENCY_PRINCIPAL` environment variable
- Create `./tools/set-principal` to configure this
- Update all tools to use `${AGENCY_PRINCIPAL:-$(whoami)}` pattern
- Add to shell profile during install (`.bashrc`, `.zshrc`)
- Pick up in setup process, `/welcome`, and all tools

### 4. AgencyBench Desktop Not Included

**Problem:** The pre-built desktop version of AgencyBench was not included in the starter. Users only get the source.

**Proposed Fix:**
- Option A: Include pre-built binaries for macOS/Windows/Linux
- Option B: Add `./tools/build-agency-bench` that builds locally
- Option C: Provide download links to GitHub releases
- Consider: Binary size vs. convenience tradeoff

### 5. Secret Service Not Auto-Starting

**Problem:** When Claude was launched via `./tools/myclaude`, the secret service didn't start automatically. Had to start it manually later.

**Proposed Fix:**
- Update `./tools/myclaude` to auto-start agency-service if not running
- Add health check before launching Claude
- Provide clear error message if service fails to start
- Consider: `./tools/agency-service start` as part of launch sequence

### 6. Bun Not Installed by Installer

**Problem:** Bun is a required dependency for agency-service and other tooling, but the installer doesn't install it. Users have to manually install bun, which breaks the "all dependencies handled by installer" promise.

**Proposed Fix:**
- Add bun installation to `install.sh`:
  ```bash
  if ! command -v bun &> /dev/null; then
      curl -fsSL https://bun.sh/install | bash
  fi
  ```
- Verify bun is available before proceeding with setup
- Add bun to prerequisites check alongside git and Claude Code
- Reload PATH after bun install to ensure it's available

## Additional Issues (TBD)

_Space reserved for additional issues as they're discovered._

---

## Acceptance Criteria

- [ ] Fresh install works on machine with existing Claude Code
- [ ] `/welcome` command works immediately after install
- [ ] Principal name is collected during onboarding
- [ ] No hardcoded "jordan" references in fresh install
- [ ] `AGENCY_PRINCIPAL` environment variable is set and used
- [ ] AgencyBench is runnable (built or downloadable)
- [ ] Secret service auto-starts with myclaude
- [ ] Bun is installed automatically by installer
- [ ] All dependencies installed without manual intervention
- [ ] End-to-end test of full onboarding flow passes

## Priority

**HIGH** - These are blocking issues for new user adoption.

## Notes

- Do NOT require users to nuke their Claude Code install
- Onboarding should be < 10 minutes with zero friction
- Every manual step is a potential dropout point
