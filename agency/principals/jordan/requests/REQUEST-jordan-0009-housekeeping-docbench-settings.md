# REQUEST-jordan-0009-housekeeping-docbench-settings

**Requested By:** principal:jordan

**Assigned To:** housekeeping

**Status:** Complete

**Priority:** Normal

**Created:** 2026-01-09 20:45 SST

**Updated:** 2026-01-09 20:45 SST

## Summary

Add Settings to DocBench to configure principal name.

## Details

The principal name should be configurable via a Settings modal, accessible from a gear icon at the bottom of the sidebar. On first run, the app should prompt for the principal name if not already set.

Once set, the principal name should:
- Auto-populate in all dialogs (Create Request, Create Observe, Create Note, Comment form)
- Enable the Quick Access section showing principal directories

## Acceptance Criteria

- [x] Settings gear icon at bottom of sidebar
- [x] Settings modal to configure principal name
- [x] First-run prompt if principal name not set
- [x] Principal name auto-populates in all dialogs
- [x] Settings shows current principal name inline

## Notes

The principal name is stored in localStorage under `agencybench-principal`.

---

## Discussion & Planning

### 2026-01-09 - Analysis (housekeeping)

**Implementation approach:**
1. Add Settings button at bottom of sidebar with gear icon
2. Create Settings modal with principal name input
3. On first load, if no principal name in localStorage, show settings modal automatically
4. Show preview of Quick Access directories that will be created

**Technical Notes:**
- Uses existing `principalName` state which is already persisted to localStorage
- Added `settingsPrincipalName` for editing in modal before saving
- Cancel button only shows if principal name is already set (can't cancel on first run)

---

## Activity Log

### 2026-01-09 - Implemented (housekeeping)

**Changes Made:**

1. **Settings section in sidebar** - Added at bottom of sidebar with gear icon and current principal name displayed

2. **Settings modal** - Modal with:
   - Principal name input field
   - Preview of Quick Access directories
   - Save button (disabled if empty)
   - Cancel button (only shown if name already set)

3. **First-run prompt** - If no principal name in localStorage on mount, automatically shows settings modal

**Files Modified:**
- `apps/agency-bench/src/app/bench/(apps)/docbench/page.tsx`

**Build Status:** Verified - Build successful, Tauri app bundled

### 2026-01-09 20:45 SST - Created
- Request created during implementation
