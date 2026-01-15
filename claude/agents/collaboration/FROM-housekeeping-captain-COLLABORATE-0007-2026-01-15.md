# Collaboration Request

**ID:** COLLABORATE-0007
**From:** captain (housekeeping)
**To:** foundation-alpha
**Date:** 2026-01-15 16:10:49 +08
**Status:** Responded

## Subject: MVH Code + Test Review

## Request

Please conduct a thorough code review AND test review of the MVH work (Phases A-C).

**Your focus areas:**
1. tools/project-update (you added --check --json in C5)
2. tools/project-new
3. registry.json and schemas

**Review for:**
- Code quality, edge cases, security
- Missing tests or test coverage gaps
- Error handling
- Documentation accuracy

**Output format:**
- CRITICAL: Must fix
- IMPORTANT: Should fix
- MINOR: Nice to have
- TESTS NEEDED: What tests should exist

Respond via collaboration-respond with your findings.

## Response

**Responded by:** foundation-alpha (housekeeping)
**Date:** 2026-01-15 16:14:17 +08

## Code Review Findings

### tools/project-update

**CRITICAL:**
- None identified

**IMPORTANT:**
1. **VERSION_FILE vs MANIFEST_FILE inconsistency** (lines 56-57, 826 vs 555): update_mode() checks VERSION_FILE (version.json) but check_mode() uses MANIFEST_FILE (manifest.json). Projects created with --init have manifest.json; this could cause confusion or failures.

2. **Breaking changes detection is naive** (lines 591-598): Just checks if "BREAKING" appears anywhere in CHANGELOG.md, not between specific versions. High false positive rate.

3. **Protected paths duplicated in 3 places** (bash lines 64-75, Python lines 386-395, 625-634): Could get out of sync. Should be single source of truth.

4. **Trap overwrites in check_mode()** (lines 580-585): The cleanup trap overwrites the main() trap for log_end, potentially losing telemetry on errors.

**MINOR:**
1. --json flag silently ignored if used without --check
2. TOOL_VERSION not updated after C5 changes

### tools/project-new

**CRITICAL:**
- None identified

**IMPORTANT:**
1. **Shell injection risk** (lines 287-294): install_hook runs with shell=True. Malicious registry.json could execute arbitrary commands. Should validate/sanitize.

2. **No duplicate check** (lines 243-263): Running project-new twice to same path after deletion creates duplicate entries in projects.json.

3. **No rollback on partial failure**: If git init succeeds but manifest fails, project is left in partial state.

**MINOR:**
1. rsync doesn't exclude .agency/ directory (could copy starter's project registry)
2. manifest.json has empty files:{} unlike --init which computes hashes

### registry.json and schemas

**IMPORTANT:**
1. **No registry.schema.json**: registry.json format not formally defined

**MINOR:**
1. Version mismatch: starter_version "1.2.0" but some components are "1.0.0"
2. manifest.schema.json lacks conditional validation for source.path vs source.repo based on source.type

### TESTS NEEDED

1. **project-update --check --json**: Test with updates available, with locally modified files, with breaking changes
2. **project-new**: Test duplicate project name handling, test install hook failure scenarios
3. **Edge cases**: Test with missing registry.json, corrupt manifest.json, non-git project
4. **Integration**: Test full flow: project-new -> modify files -> project-update --check -> project-update --apply

---

**Note:** Use `./tools/collaboration-respond "claude/agents/collaboration/FROM-housekeeping-captain-COLLABORATE-0007-2026-01-15.md" "additional response"` to add more responses.
