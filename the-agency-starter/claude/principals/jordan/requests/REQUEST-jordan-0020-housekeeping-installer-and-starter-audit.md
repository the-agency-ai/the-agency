# REQUEST-jordan-0020: Installer & Starter Audit

**Requested By:** principal:jordan

**Assigned To:** housekeeping

**Status:** Open - URGENT

**Priority:** Critical

**Created:** 2026-01-10 17:30 SST

## Summary

The installer and the-agency-starter are severely out of date. AgencyBench is at v0.1.0 (Jan 9) and missing BugBench and all recent work. The starter is missing apps/ and services/ entirely. This is blocking users from having a turnkey experience.

---

## Problems Identified

### 1. AgencyBench is Stale (v0.1.0)

**Current state:**
- Version: 0.1.0 (built Jan 9)
- Missing: BugBench, LogBench, TestBench
- Missing: All API changes (explicit operations)
- Missing: Secret service
- Missing: Messages improvements

**What should be there:**
- BugBench (REQUEST-0010)
- All embedded services (bug, messages, log, test, product, secret)
- Explicit API pattern
- Current version should be ~0.6.0+

### 2. the-agency-starter Missing Critical Content

**Current state:**
- Version: 0.2.0
- Has: tools/, claude/, CLAUDE.md
- Missing: apps/ (AgencyBench source)
- Missing: services/ (agency-service)

**What should be there:**
- Everything needed to be turnkey
- apps/agency-bench/ (full source)
- services/agency-service/ (full source)
- Pre-built AgencyBench binary OR build instructions

### 3. release-starter Tool Incomplete

The `tools/release-starter` script only syncs:
- CLAUDE.md, README, tools/
- claude/ subdirectories

It does NOT sync:
- apps/
- services/

### 4. No Build Pipeline

There's no automated or documented process for:
- Building AgencyBench after changes
- Syncing builds to starter
- Versioning the app with the project

---

## Requirements

### Turnkey Experience

Users who clone/install the-agency-starter should get:
1. All tools working immediately
2. AgencyBench ready to run (or easy one-command build)
3. agency-service ready to run
4. All DevApps functional (DocBench, BugBench, etc.)

### What Must Be Included in Starter

```
the-agency-starter/
├── CLAUDE.md
├── README.md
├── tools/                    # All CLI tools
├── claude/                   # Agents, principals, docs, etc.
├── apps/
│   └── agency-bench/         # Full Tauri app source
├── services/
│   └── agency-service/       # Full service source
└── install.sh                # Sets everything up
```

### Build & Release Process

1. When we make changes to AgencyBench → rebuild
2. When we cut a release → sync to starter
3. Starter should have source AND optionally pre-built binaries

---

## Immediate Actions

### Phase 1: Rebuild AgencyBench
- [ ] Build AgencyBench with all current changes
- [ ] Verify BugBench, DocBench, all features work
- [ ] Update version to match project (0.6.x or 0.7.0)

### Phase 2: Fix release-starter
- [ ] Add apps/ to sync list
- [ ] Add services/ to sync list
- [ ] Test full sync

### Phase 3: Update Starter
- [ ] Run updated release-starter
- [ ] Verify starter has everything
- [ ] Test fresh clone + install

### Phase 4: Push to GitHub
- [ ] Commit all changes
- [ ] Push to main
- [ ] Create release with proper notes

---

## Open Questions

1. **Pre-built binaries in starter?**
   - Option A: Include .app/.dmg in starter (larger repo)
   - Option B: Build on install (requires Rust/Tauri toolchain)
   - Option C: Separate download location for binaries

2. **Version alignment**
   - Should AgencyBench version match project version?
   - Or independent versioning?

---

## Activity Log

### 2026-01-10 17:30 SST - Created
- User discovered AgencyBench is at v0.1.0, missing BugBench
- Starter missing apps/ and services/ entirely
- Created as URGENT/Critical priority

