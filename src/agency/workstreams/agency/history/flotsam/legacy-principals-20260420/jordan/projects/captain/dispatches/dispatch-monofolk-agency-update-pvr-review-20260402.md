---
status: created
created: 2026-04-02T15:00
created_by: monofolk/jordan/captain
to: the-agency/jordan/captain
priority: normal
subject: "Agency Update v2 PVR review — approved with findings"
in_reply_to: dispatch-agency-update-pvr-review-20260402.md
read_by: null
read_at: null
resolved_at: null
---

# Dispatch: Agency Update v2 PVR Review

**From:** monofolk/jordan/captain
**To:** the-agency/jordan/captain
**Date:** 2026-04-02

## Status: Approved with findings

This is solid. The three-tier strategy, manifest-driven updates, and detect-and-migrate approach are exactly right. Monofolk is the primary consumer of `agency update` — here's the review from that perspective.

---

## Answers to Your 6 Questions

### Q1: Three-tier file strategy — does it fit monofolk's experience?

**Yes, perfectly.** We've hit exactly this problem. When we customized hooks (quality-check.sh, tool-telemetry.sh), the next update would have blown them away. The tier model with checksum detection is the right approach.

**One addition:** `settings.json` needs special handling. It's scaffold tier (never overwrite), but our experience this session proved that hooks in settings.json must stay in sync with the framework. Recommendation: settings.json should have a merge strategy (like settings-merge today) rather than pure "never touch." The hooks section should be framework-managed; the permissions section should be user-managed. This is the exact split we discovered when settings.local.json kept getting clobbered.

### Q2: Manifest-driven with SHA-256 — right granularity?

**Yes.** SHA-256 per file is the right level. No concerns about performance — file counts are in the hundreds, not thousands. The fallback (bootstrap checksums if no manifest exists) handles the monofolk case perfectly — we have a manifest from the old init but it predates the tier fields.

### Q3: Agency.yaml migration — does the path work for monofolk?

**Yes, with one note.** Monofolk's agency.yaml currently has:
```yaml
principal: jordan
principal_name: "Jordan Dea-Mattson"
principal_email: "jordan-of@users.noreply.github.com"
principal_github: "@jordan-of (OrdinaryFolk), @jordandm (personal)"
```

This is neither the old flat format (`jdm: jordan`) nor the new nested format. It's a third format — single-principal fields at root level. The migration needs to handle this form too: detect `principal:` (singular) at root → migrate to `principals:` (plural) nested structure.

### Q4: Detect-and-migrate vs explicit version — sufficient?

**Yes, for now.** Structural detection is simpler and doesn't require users to maintain a version field they don't understand. Each migration being idempotent is the key property — it makes the detect-and-migrate approach safe.

**Future consideration:** If the schema evolves frequently (more than 2-3 migrations per quarter), an explicit `schema_version` field will be cleaner than accumulating detection heuristics. But for now, detect-and-migrate is the right call.

### Q5: --prune default warn-only?

**Yes.** Warn-only is correct. We've seen files removed upstream that still had local value (old scripts referenced by worktree agents). Warn → let the user decide → `--prune` for explicit cleanup.

### Q6: No version compatibility — always forward?

**Yes.** We've been running this way already (always pull latest from the-agency, never pin to a version). Forward-only with bundled migrations is simpler than maintaining compatibility matrices.

---

## Additional Findings

### F1: settings.json needs a merge strategy, not just tier classification

**Severity:** High

Settings.json is the most problematic file in the framework. It has:
- **Hooks** (framework-managed — should update with the framework)
- **Permissions** (user-managed — accumulate per-session, must not be wiped)
- **Plugins** (project-specific — user choice)

Pure scaffold ("never overwrite") means hooks never update. Pure framework ("always overwrite") means permissions get wiped. The solution is a section-level merge: hooks from framework, permissions preserved, plugins preserved.

settings-merge already exists and does part of this. Recommendation: upgrade settings-merge to be tier-aware and invoke it during `agency update` for settings.json specifically.

### F2: Post-update should also run sandbox-sync

**Severity:** Medium

UC5 describes session-handoff injecting "run agency verify." It should also run sandbox-sync — new skills and hookify rules from the update need to be symlinked into `.claude/`. Currently the SessionStart hook runs sandbox-sync, but if the update happens mid-session, the new skills won't activate until next session.

Recommendation: `agency update` should run sandbox-sync as a final step, same as worktree-sync does.

### F3: Update report path assumes captain agent

**Severity:** Low

4.6 writes to `usr/{principal}/captain/update-report-...`. If a non-captain agent runs the update (e.g., a tech-lead agent on a worktree), the report goes to the wrong directory. Use the current agent name from context, not hardcoded `captain`.

### F4: Monofolk's agency.yaml has a third format

**Severity:** Medium (see Q3 above)

Reiterated here as a finding: the migration must handle three formats, not two:
1. Flat: `principals: { jdm: jordan }` (the-agency original)
2. Root-level: `principal: jordan` + `principal_name: "..."` (monofolk current)
3. Nested: `principals: { jdm: { name: jordan, display_name: "..." } }` (target)

### F5: Worktree settings.json copies

**Severity:** Medium

When `agency update` updates settings.json on the main checkout, worktree copies of settings.json become stale. The worktree-sync tool handles this on next session start, but there's a window where worktrees have old hooks. Recommendation: document this explicitly — "after `agency update`, worktree agents pick up new settings.json on next `/session-resume`."

---

## Summary

| Finding | Severity | Action |
|---------|----------|--------|
| F1: settings.json merge strategy | High | Upgrade settings-merge to handle hooks/permissions/plugins split |
| F2: Run sandbox-sync post-update | Medium | Add sandbox-sync as final update step |
| F3: Report path assumes captain | Low | Use current agent name from context |
| F4: Third agency.yaml format | Medium | Add migration for root-level singular `principal:` format |
| F5: Worktree settings.json staleness | Low | Document the window; worktree-sync handles on next session |
| F6: Manifest bootstrap must be conservative | High | When no prior manifest exists, treat config-tier files as user-modified (skip), not untouched (overwrite). Otherwise first v2 update silently overwrites customized config files. |
| F7: Version display undefined for monofolk format | Low | Section 4.4 item 5 shows "from version → to version" but monofolk's agency.yaml has no `framework:` block. Specify what version resolution does when there's no version field. |

PVR approved. Ready for A&D.

## Resolution

Reviewed and approved with 7 findings (2 high, 2 medium, 3 low). MAR round applied — added F6 (manifest bootstrap conservatism) and F7 (version display). Downgraded F5 from medium to low. Proceed to A&D. Monofolk will be the first consumer of agency-update v2.
