# Transcript: agency-init Design Review

**Date:** 2026-03-31
**Participants:** jordan (principal), captain (agent)
**Context:** Review/revise/finalize cycle on `agency-init-design-20260331.md`
**Trigger:** Multi-agent review (design, code, security) produced findings; resolving items needing principal input

---

## Multi-Agent Review Summary

Three parallel reviewers (design, code, security) reviewed the design document. Consolidated findings:

- **3 CRITICAL:** workstream path relocation (undocumented breaking change), no update rollback/atomicity, no source authentication
- **7 MAJOR:** tier rule ambiguity, settings.json divergence, manifest schema gap, incomplete tool list, unsigned manifest, supply-chain escalation path, KNOWLEDGE.md migration missing
- **8 MINOR:** various (all addressed in revision)

---

## Item 1: Workstream & usr/ Location + Worktrees

**Decision: Option A — everything under `claude/`.** Single namespace. Good neighbor in someone else's repo. No breaking change from current `agency/workstreams/` layout.

Worktrees stay at `.claude/worktrees/` — transient, gitignored, Claude Code's concern. ISS-012 (worktrees in two locations in monofolk) noted as open item.

## Item 2: Source Authentication

**Decision: Option A for v1 — trust the source.** Document the trust model explicitly. Same as Rails and gstack.

**Post-v1 (public release): Option C or D** — signed checksums or GPG-signed manifests. Deferred to that milestone.

## Item 3: Update Atomicity / Rollback

**Decision: Option A — git is the rollback.** Updates don't auto-commit. `git checkout -- claude/` is the undo. Add `--dry-run` flag to agency-update. No custom staging or backup mechanism.

**Init preconditions clarified:** Bare repo: `git init` → `claude init` → `agency-init`. Existing repo: `claude init` (if needed) → `agency-init`. agency-init validates git exists, does not create it.

## Item 4: settings.json Divergence

**Decision: Option D + A fallback.** Ship `claude/config/settings-template.json` as framework tier (always current). Provide `settings-merge` tool that diffs template against current `.claude/settings.json` and adds missing entries. User runs it explicitly after update. If merge fails (malformed JSON), emit exact JSON fragments for manual paste.

---

## Additional Findings Addressed in Revision

All minor/nit findings resolved without principal input:
- Tier precedence rule added (more specific patterns win)
- Deleted config-tier file handling specified (treat as intentional deletion, skip)
- Tool list completed (added dependencies-check, dependencies-install, settings-merge, telemetry, agency-init, agency-update)
- Manifest `source.path` field added
- Schema version validation added
- `--dev` flag interaction with agency-update specified
- KNOWLEDGE.md migration path documented
- Ghostty-specific hook moved to open items (should be conditional on terminal.provider)
- Hookify shipped vs user rules: distinguished by manifest presence
- Init commit scoped to manifest file list (not git add -A)
- chmod +x applied per explicit file list (not glob)
- Input validation for --principal specified
- Error suppression patterns noted for fix

---

## Decisions Summary

1. **Namespace:** Everything under `claude/`. Single top-level directory.
2. **Source auth:** Trust the source for v1. Signed checksums post-v1.
3. **Rollback:** Git is the safety net. Add `--dry-run`. No custom backup.
4. **settings.json:** Template + merge tool. Manual fallback for broken JSON.
