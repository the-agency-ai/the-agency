# REQUEST-jordan-0008-housekeeping-docbench-issues

**Requested By:** principal:jordan

**Assigned To:** housekeeping

**Status:** Complete

**Priority:** Normal

**Created:** 2026-01-09 20:25 SST

**Updated:** 2026-01-09 20:25 SST

## Summary

DocBench Issues

Some  Issues:
- First, the pop-up menu is still around! It should have gone away!
- Second, we need a copy tool to allo us to copy the path to the file current in the Preview (Rich Text) / Edit View.
- Third, favourite, open, trash, and copy icons should be aligned with the file tile. 
- Fourth, the file name should be the file name, not the path. If I mouse over, then the "tool tip" should be the full file name.

And one addition:
- My principals/{PRINCIPALNAME}/ directory should always be a standing favourite.
- We should consider also making notes/ projects/ requests/ as well?

## Details

<!-- Detailed description of what you're requesting -->

## Acceptance Criteria

<!-- How will we know when this is complete? -->
- [x] Comment pop-up is gone
- [x] Copy tool is available for currently open document.
- [x] Icons are aligned with the file name.
- [x] File name is the actual file name, not the full path name.
- [x] principals/{PRINCIPALNAME}/ is always a favourite
- [x] principals/{PRINCIPALNAME}/notes, /requests, /observations are in Quick Access.

## Notes

<!-- Any additional context, constraints, or preferences -->

---

## Discussion & Planning

### 2026-01-09 - Analysis (housekeeping)

**Issue 1: Pop-up menu still around**
- The old text selection popup that appears when you select text is still active
- This was supposed to be replaced by the Insert > Comment menu item
- **Fix**: Remove the `selectionPopup` rendering and the `handleTextSelection`/`handlePreviewSelection` handlers, or at minimum disable the automatic popup appearance
- The comment form modal can stay since it's now triggered from the Insert menu

**Issue 2: Copy tool for current file**
- There IS already a copy button next to the file path in the header
- **Clarification (Jordan)**: Need a copy button in the Preview/Edit view area itself, not just in the header
- **Fix**: Add a floating or fixed copy button in the content area that copies the current file path

**Issue 3: Icons alignment with file title**
- Currently the header has: file path on left, buttons (Insert, ★, external, trash, Save, Edit) on right
- The buttons are flex-aligned but may not align well with the file title text
- **Fix**: Review the header layout to ensure proper vertical alignment

**Issue 4: File name instead of path**
- Currently shows: `claude/principals/jordan/requests/REQUEST-...md`
- Should show: `REQUEST-...md` with full path in tooltip
- **Fix**: Change the display to show only `selectedFile.split('/').pop()` with `title={selectedFile}` for tooltip

**Addition 5: Standing favorites for principal directory**
- When principal name is set, automatically add `principals/{name}/` to favorites
- This should persist and not be removable (or re-add on startup)
- **Decision (Jordan)**: Always show, make it a "Quick Access" section

**Addition 6: Principal subdirectories as favorites**
- Also auto-favorite: `notes/`, `projects/`, `requests/` under the principal
- **Decision (Jordan)**: Always show in the Quick Access section
- **Implementation**: Create a separate "Quick Access" section above Favorites that shows:
  - `principals/{name}/`
  - `principals/{name}/notes/`
  - `principals/{name}/projects/`
  - `principals/{name}/requests/`
- These are always visible when principal name is set, not removable by user

---

## Activity Log

### 2026-01-09 - Implemented (housekeeping)

**Changes Made:**

1. **Removed auto popup** - Removed `onMouseUp={handleTextSelection}` and `onMouseUp={handlePreviewSelection}` from textarea and preview div. Comment feature now only accessible via Insert menu.

2. **Added floating copy button** - Added a floating copy button in the bottom-right of the content area (Preview/Edit view) that copies the current file path.

3. **Aligned icons** - Changed header button container from `gap-2` to `gap-1 items-center` for tighter, aligned icons.

4. **Filename instead of path** - Changed header to show just `selectedFile.split('/').pop()` (filename only), with relative path in tooltip.

5. **Quick Access section** - Added new "Quick Access" section above Favorites that shows (when principal name is set):
   - `{principalName}/`
   - `notes/`
   - `requests/`
   - `observations/`

   These are always visible and not removable. Clicking expands to that directory in the tree.

**Build Status:** Verified - Build successful, Tauri app bundled

### 2026-01-09 20:25 SST - Created
- Request created by principal:jordan
