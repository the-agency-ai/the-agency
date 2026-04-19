# REQUEST-jordan-0061: Agency-bench file opening and hot-reload

**Status:** Complete
**Priority:** Normal
**Requested By:** jordan
**Assigned To:** captain
**Created:** 2026-01-16
**Updated:** 2026-01-16

## Summary

Agency-bench file opening and hot-reload

## Details

### Background
When launching agency-bench with --file parameter, the app needs to:
1. Auto-navigate to DocBench (fixed)
2. Open the specified file (fixed)
3. Work when app is already running (IMPLEMENTED)

### Files Changed
- source/apps/agency-bench/src/components/bench/BenchLayout.tsx
- source/apps/agency-bench/src/app/bench/(apps)/docbench/page.tsx
- source/apps/agency-bench/src/lib/tauri.ts

## Acceptance Criteria

- [x] Auto-navigate to DocBench on file open
- [x] Open specified file from CLI
- [x] Hot-reload for already-running app

## Work Completed

### 2026-01-18 - Hot-reload Implementation

**BenchLayout.tsx:**
- Added window focus listener to check for pending files
- Added periodic polling (every 2 seconds) for pending files
- Refactored `checkPendingOpen` as reusable callback

**docbench/page.tsx:**
- Added periodic check for sessionStorage changes (every 500ms)
- Detects files added by BenchLayout and opens them

**tauri.ts:**
- Fixed browser fallback to reference captain instead of housekeeping

**How it works:**
1. CLI tool writes to pending-open.json
2. BenchLayout polls for pending files every 2s (also on window focus)
3. If file found, stores in sessionStorage and navigates to docbench
4. DocBench polls sessionStorage every 500ms and opens new files

---

## Activity Log

### 2026-01-16 - Created
- Request created by jordan

### 2026-01-18 - Complete
- Implemented hot-reload for already-running app
- Uses polling + window focus events
- Updated housekeeping references to captain
