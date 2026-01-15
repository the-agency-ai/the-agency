# Collaboration Request

**ID:** COLLABORATE-0009
**From:** captain (housekeeping)
**To:** foundation-alpha
**Date:** 2026-01-15 16:13:55 +08
**Status:** Responded

## Subject: MVH Test Review

## Request

SEPARATE from your code review - please do a TEST REVIEW:

1. Read tools/starter-test to understand existing test coverage
2. Identify test gaps for MVH work:
   - tools/project-update (--check, --json, --init, --preview, --apply)
   - tools/project-new (manifest generation)
   - Schema validation

**Deliverable:** List of specific tests that SHOULD exist with:
- Test name/description
- What it validates
- Priority (critical/important/nice-to-have)

This is about test COVERAGE, not code quality.

## Response

**Responded by:** foundation-alpha (housekeeping)
**Date:** 2026-01-15 16:22:33 +08

## Test Coverage Review

### Current Coverage (tools/starter-test)
Existing tests cover: install.sh, project-new basic creation, file comparison, structure validation, sensitive content checks, basic tools.

### Test Gaps Identified

#### project-update Tests (CRITICAL)

| Test | What it validates | Priority |
|------|------------------|----------|
| test_update_check_mode | --check returns correct status without modifying files | Critical |
| test_update_check_json | --check --json outputs valid JSON with required fields | Critical |
| test_update_init_mode | --init creates valid manifest.json from existing project | Critical |
| test_update_preview_mode | --preview shows changes without applying | Important |
| test_update_apply_mode | --apply correctly updates files | Important |
| test_update_version_detection | Detects version differences correctly | Critical |
| test_update_modified_files | Identifies locally modified files via hash comparison | Critical |
| test_update_protected_paths | Never touches protected paths (principals, WORKLOGs) | Critical |
| test_update_claude_md_merge | CLAUDE.md merge preserves PROJECT section | Important |
| test_update_breaking_changes | Breaking changes flag works correctly | Nice-to-have |
| test_update_missing_manifest | Graceful error when manifest missing | Important |
| test_update_corrupt_manifest | Handles corrupt JSON gracefully | Nice-to-have |

#### project-new Tests (CRITICAL)

| Test | What it validates | Priority |
|------|------------------|----------|
| test_new_manifest_generation | Creates valid .agency/manifest.json | Critical |
| test_new_projects_registration | Registers project in starter's projects.json | Critical |
| test_new_install_hooks | Runs install hooks and updates manifest | Important |
| test_new_duplicate_project | Handles duplicate project paths gracefully | Important |
| test_new_missing_registry | Works when registry.json missing | Nice-to-have |
| test_new_hook_failure | Continues on install hook failure (non-fatal) | Important |
| test_new_components_tracked | All components marked as installed | Critical |

#### Schema Validation Tests (IMPORTANT)

| Test | What it validates | Priority |
|------|------------------|----------|
| test_manifest_schema_valid | manifest.json matches manifest.schema.json | Critical |
| test_projects_schema_valid | projects.json matches projects.schema.json | Critical |
| test_registry_structure | registry.json has expected structure | Important |

#### Integration Tests (IMPORTANT)

| Test | What it validates | Priority |
|------|------------------|----------|
| test_full_update_flow | project-new -> modify -> --check -> --apply | Critical |
| test_multi_project_registry | Multiple projects registered correctly | Important |
| test_update_after_starter_change | Detects changes after starter update | Important |

### Summary
- **Critical tests missing:** 12
- **Important tests missing:** 9  
- **Nice-to-have tests missing:** 3
- **Total new tests needed:** 24

---

**Note:** Use `./tools/collaboration-respond "claude/agents/collaboration/FROM-housekeeping-captain-COLLABORATE-0009-2026-01-15.md" "additional response"` to add more responses.
