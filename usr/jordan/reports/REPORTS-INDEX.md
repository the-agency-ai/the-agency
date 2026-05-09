# Principal Reports Index

Reports filed externally (Anthropic Claude Code, the-agency GitHub, etc.) by or on behalf of jordan.

Each row is one filing. Click through to the per-report markdown for full context, current state, and response log.

**Location:** `usr/jordan/reports/` (principal-scoped)
**Naming convention:** `report-{kind}-{slug}-{YYYYMMDD}.md`

---

## Filed Reports

<!-- AGENCY-ISSUE-INDEX-START — agency-issue tool appends rows above the END marker -->

| Date | Title | Kind | Target | External ID | Local Report | Status |
|------|-------|------|--------|-------------|--------------|--------|
| 2026-04-21 | session-end skill writes handoff but never commits it — leaves tree dirty, blocks next session-resume | bug | the-agency-ai/the-agency | #393 | [report-agency-issue-session-end-skill-writes-handoff-but-never-commits-20260421](usr/jordan/reports/report-agency-issue-session-end-skill-writes-handoff-but-never-commits-20260421.md) | open |
| 2026-04-21 | Python tools fail on Apple-stock + brew-only python@3.13 host (no unversioned python3 link) | bug | the-agency-ai/the-agency | #394 | [report-agency-issue-python-tools-fail-on-apple-stock-brew-only-python--20260421](usr/jordan/reports/report-agency-issue-python-tools-fail-on-apple-stock-brew-only-python--20260421.md) | open |
| 2026-04-21 | git-safe-commit: add --coord convenience flag (alias for coord-commit happy path) | friction | the-agency-ai/the-agency | #395 | [report-agency-issue-git-safe-commit-add-coord-convenience-flag-alias-f-20260421](usr/jordan/reports/report-agency-issue-git-safe-commit-add-coord-convenience-flag-alias-f-20260421.md) | open |
| 2026-04-22 | Consolidate dependency YAMLs + ship /agency-dependency-manage + dependency-manage tool | feature | the-agency-ai/the-agency | #412 | [report-agency-issue-consolidate-dependency-yamls-ship-agency-dependenc-20260422](usr/jordan/reports/report-agency-issue-consolidate-dependency-yamls-ship-agency-dependenc-20260422.md) | open |
| 2026-04-22 | License consolidation (src→build) + joint copyright (Jordan + TheAgencyGroup) + trademark reservation | feature | the-agency-ai/the-agency | #413 | [report-agency-issue-license-consolidation-src-build-joint-copyright-jo-20260422](usr/jordan/reports/report-agency-issue-license-consolidation-src-build-joint-copyright-jo-20260422.md) | open |
| 2026-04-22 | Design + build unified `msg` dispatcher (real form, TBD — old spec swept) | feature | the-agency-ai/the-agency | #414 | [report-agency-issue-design-build-unified-msg-dispatcher-real-form-tbd--20260422](usr/jordan/reports/report-agency-issue-design-build-unified-msg-dispatcher-real-form-tbd--20260422.md) | open |
| 2026-04-22 | Migrate usr/jordan/{mdpal,mdslidepal,mock-and-mark} → agency/workstreams/ (1B1 Item 3 remainder) | feature | the-agency-ai/the-agency | #415 | [report-agency-issue-migrate-usr-jordan-mdpal-mdslidepal-mock-and-mark--20260422](usr/jordan/reports/report-agency-issue-migrate-usr-jordan-mdpal-mdslidepal-mock-and-mark--20260422.md) | open |
| 2026-04-22 | Add Python unit + integration tests for src/tools/build (on top of existing BATS) | feature | the-agency-ai/the-agency | #417 | [report-agency-issue-add-python-unit-integration-tests-for-src-tools-bu-20260422](usr/jordan/reports/report-agency-issue-add-python-unit-integration-tests-for-src-tools-bu-20260422.md) | open |
| 2026-04-22 | Pre-existing pollution cleanup at agency/ build-product side (testname, test; rm -rf, test-auto QGRs, housekeeping workstream) | bug | the-agency-ai/the-agency | #419 | [report-agency-issue-pre-existing-pollution-cleanup-at-agency-build-pro-20260422](usr/jordan/reports/report-agency-issue-pre-existing-pollution-cleanup-at-agency-build-pro-20260422.md) | open |
| 2026-04-22 | src/ top-level taxonomy drift — resolve 4 dirs outside V5 allowlist (assets, integrations, spec-provider, tools-developer) | friction | the-agency-ai/the-agency | #420 | [report-agency-issue-src-top-level-taxonomy-drift-resolve-4-dirs-outsid-20260422](usr/jordan/reports/report-agency-issue-src-top-level-taxonomy-drift-resolve-4-dirs-outsid-20260422.md) | open |
| 2026-05-09 | git-safe family lacks 'init' subcommand — blocks bare-repo bootstrap | friction | the-agency-ai/the-agency | #437 | [report-agency-issue-git-safe-family-lacks-init-subcommand-blocks-bare--20260509](usr/jordan/reports/report-agency-issue-git-safe-family-lacks-init-subcommand-blocks-bare--20260509.md) | open |
<!-- AGENCY-ISSUE-INDEX-END -->

## How to add an entry

1. Draft the report with captain, following `agency/REFERENCE/FEEDBACK-FORMAT.md`
2. File via the appropriate channel:
   - `agency-issue file` → the-agency GitHub (auto-appends to this index)
   - `/feedback` → Anthropic Claude Code (manually create the report file + append a row)
3. The per-report markdown lives in this directory with full text, response log, and frontmatter linking back to the source seed
4. This index is the at-a-glance view; the per-report file is the source of truth

## Principle

Reports are the record of what we asked the outside world for. Every gap we find in an external tool that we can't close in userspace becomes a report. Every response from the other side gets appended to its report file so we have a full narrative.
