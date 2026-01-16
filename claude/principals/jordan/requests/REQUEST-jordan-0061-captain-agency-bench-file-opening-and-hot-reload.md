# REQUEST-jordan-0061: Agency-bench file opening and hot-reload

**Status:** Open
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
1. Auto-navigate to DocBench (fixed in this session)
2. Open the specified file (fixed in this session)
3. Work when app is already running (NOT YET IMPLEMENTED)

### Work Completed
- Updated BenchLayout.tsx to check pending-open.json on startup
- Updated docbench/page.tsx to check sessionStorage fallback
- Rebuilt and installed app

### Remaining Work
- Add mechanism for already-running app to detect new file requests
- Options: file watcher, deep links, IPC

### Files Changed
- source/apps/agency-bench/src/components/bench/BenchLayout.tsx
- source/apps/agency-bench/src/app/bench/(apps)/docbench/page.tsx

## Acceptance Criteria

- [ ] Criteria 1
- [ ] Criteria 2

## Work Completed

<!-- Document completed work here -->

---

## Activity Log

### 2026-01-16 - Created
- Request created by jordan
