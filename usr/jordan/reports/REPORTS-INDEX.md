# Principal Reports Index

Reports filed externally (Anthropic Claude Code, the-agency GitHub, etc.) by or on behalf of jordan.

Each row is one filing. Click through to the per-report markdown for full context, current state, and response log.

**Location:** `usr/jordan/reports/` (principal-scoped — moved from `usr/jordan/captain/reports/` on 2026-04-08)
**Naming convention:** `report-{kind}-{slug}-{YYYYMMDD}.md`

---

## Filed Reports

<!-- AGENCY-ISSUE-INDEX-START — agency-issue tool appends rows above the END marker -->

| Date | Title | Kind | Target | External ID | Local Report | Status |
|------|-------|------|--------|-------------|--------------|--------|
| 2026-04-08 | Periodic silent execution primitive for autonomous agents | feedback | anthropic/claude-code | feedback `8dd67e96…` + GH [#45017](https://github.com/anthropics/claude-code/issues/45017) | [report-silent-periodic-tool-calls-20260408](report-silent-periodic-tool-calls-20260408.md) | filed |
| 2026-04-08 | agency-issue v1: new skill for two-way GitHub issue tracking | feature | the-agency-ai/the-agency | [#52](https://github.com/the-agency-ai/the-agency/issues/52) | [report-agency-issue-agency-issue-v1-new-skill-for-two-way-github-issue-20260408](report-agency-issue-agency-issue-v1-new-skill-for-two-way-github-issue-20260408.md) | open |

| 2026-04-08 | agency update does not propagate new top-level YAML sections from agency.yaml | bug | the-agency-ai/the-agency | #56 | [report-agency-issue-agency-update-does-not-propagate-new-top-level-yam-20260408](usr/jordan/reports/report-agency-issue-agency-update-does-not-propagate-new-top-level-yam-20260408.md) | open |
| 2026-04-09 | worktree-sync: misleading 'resolve manually' message after successful conflict-abort | bug | the-agency-ai/the-agency | #57 | [report-agency-issue-worktree-sync-misleading-resolve-manually-message--20260409](usr/jordan/reports/report-agency-issue-worktree-sync-misleading-resolve-manually-message--20260409.md) | open |
<!-- AGENCY-ISSUE-INDEX-END -->

## How to add an entry

1. Draft the report with captain, following `claude/docs/FEEDBACK-FORMAT.md`
2. File via the appropriate channel:
   - `agency-issue file` → the-agency GitHub (auto-appends to this index)
   - `/feedback` → Anthropic Claude Code (manually create the report file + append a row)
3. The per-report markdown lives in this directory with full text, response log, and frontmatter linking back to the source seed
4. This index is the at-a-glance view; the per-report file is the source of truth

## Principle

Reports are the record of what we asked the outside world for. Every gap we find in an external tool that we can't close in userspace becomes a report. Every response from the other side gets appended to its report file so we have a full narrative.
