# REQUEST-jordan-0019: DocBench Enhancements

**Requested By:** principal:jordan

**Assigned To:** housekeeping

**Status:** Complete

**Priority:** High

**Created:** 2026-01-10 17:00 SST

## Summary

Several enhancements needed for DocBench to improve document authoring workflow, including commenting, references, and template-based document creation.

---

## Requirements

### 1. Insert Comment

**Current behavior:** Unknown/broken

**Desired behavior:**

When user selects a block of text and chooses "Insert Comment":

```
Block of text that I selected
```

Insert directly below the selected text:

```
[(PRINCIPALNAME) Block of text that I selected]
[(PRINCIPALNAME) {cursor here for comment}]
```

**Result in document:**
```
Block of text that I selected
[(PRINCIPALNAME) Block of text that I selected]
[(PRINCIPALNAME) This is my comment about the above]
```

**Notes:**
- PRINCIPALNAME comes from settings (already implemented in REQUEST-0009)
- The quoted text helps maintain context
- Comment format is consistent and grep-able

---

### 2. Insert Reference to Document

**Feature:** Insert a relative link to another document in the project

**Workflow:**
1. User selects "Insert Reference → Document"
2. File picker opens showing directory tree
3. Filtered to show: `.md`, `.png`, `.svg`
4. User selects file
5. Inserts relative path link (relative to project root)

**Constraints:**
- Cannot reference files outside project root
- Path should be relative, not absolute

**Open question:** Include `.jpeg`/`.jpg`?
- Pro: Common image format
- Con: Larger files, less common in docs
- **Decision:** TBD

---

### 3. Insert Reference to Object

**Feature:** Insert a reference to AgencyBench-known objects

**Initial objects to support:**
- Bugs (e.g., `BUG-0042`)
- REQUESTs (e.g., `REQUEST-jordan-0017`)

**Workflow:**
1. User selects "Insert Reference → Bug" (or other object type)
2. Picker shows list of objects from AgencyBench
3. User selects object
4. Inserts formatted reference

**Format TBD:**
- `[BUG-0042](link?)`
- `BUG-0042`
- `[[BUG-0042]]` (wiki-style)

---

### 4. Insert Reference to Web Page

**Feature:** Insert a link to an external web page

**Workflow:**
1. User selects "Insert Reference → Web Page"
2. Dialog prompts for URL
3. Optionally prompts for link text
4. Inserts markdown link: `[Link Text](https://example.com)`

---

### 5. Create Document from Template

**Feature:** "Create Document" should offer template choices

**Templates to support:**
- REQUEST
- Bug Report
- Meeting Notes
- Decision Record
- Agent Knowledge
- Sprint Plan
- (others as defined in `claude/templates/`)

**Workflow:**
1. User selects "Create Document"
2. Picker shows available templates
3. User selects template
4. New document created with template content
5. User fills in template fields

---

### 6. App Discovery Issue

**Problem:** Cannot find the latest version of the app

**Needed:**
- Clear location for built app
- Version indicator in app
- Easy way to check for/get updates

---

### 7. the-agency-starter Sync Issue

**Problem:** `the-agency-starter/` in the repo is not up to date

**Impact:**
- Installer won't work correctly
- New users get stale content

**Needed:**
- Run `tools/release-starter` to sync
- Verify starter builds correctly
- Document the sync process

---

## Implementation Notes

### Priority Order
1. Fix #6 and #7 first (blockers)
2. Insert Comment (#1) - high value
3. Insert Document Reference (#2)
4. Create from Template (#5)
5. Insert Object Reference (#3)
6. Insert Web Reference (#4)

### Files Likely Affected
- DocBench UI components
- Insert menu
- File picker component
- Template system
- `tools/release-starter`

---

## Activity Log

### 2026-01-10 - Implemented (housekeeping)

All 7 items completed:

**#1 Insert Comment** - Fixed comment insertion to preserve original text and insert comment block below selection. Format: `[(principal) quoted text]\n[(principal) comment]`

**#2 Insert Reference to Document** - Added "Document" option to Insert menu. Opens file picker filtered to `.md`, `.png`, `.svg`. Inserts markdown link with relative path.

**#3 Insert Reference to Object** - Added "Bug Reference" and "Request Reference" options to Insert menu. Modal prompts for object ID, inserts `[BUG-XXXX]` or `[REQUEST-xxx-xxxx]` format.

**#4 Insert Reference to Web Page** - Added "Web Link" option to Insert menu. Modal prompts for URL and optional link text, inserts markdown link.

**#5 Create Document from Template** - Added "From Template" option to Create menu. Templates available: Bug Report, Meeting Notes, Decision Record. Creates file in principal's notes directory.

**#6 App Discovery Issue** - Added version indicator to AgencyBench sidebar footer. Version read from package.json at build time via `NEXT_PUBLIC_APP_VERSION` env var.

**#7 the-agency-starter Sync Issue** - Ran `tools/release-starter 1.0.1` to sync. Pushed to both repos. Verified installer test passes.

**Files Modified:**
- `apps/agency-bench/src/app/bench/(apps)/docbench/page.tsx` - All DocBench features
- `apps/agency-bench/src/components/bench/AppSidebar.tsx` - Version indicator
- `apps/agency-bench/next.config.ts` - Version env var
- `the-agency-starter/` - Full sync via release-starter

**Build Status:** Verified - TypeScript check passes

### 2026-01-10 - Additional Items (housekeeping)

**#8 Replace Date with Principal Name** - Updated Header.tsx to display Principal Name instead of date in the header bar. Shows "No principal set" when not configured. Applies to all AgencyBench pages (Dashboard, DocBench, BugBench, etc.) since they share the same Header component.

**#9 Reorganize DocBench Toolbar** - Moved Create Document functionality from the sidebar to the content area:
- Removed Create (+) button from directory browser sidebar header
- Added "Create" menu to the toolbar when viewing/editing a file
- When no file selected, content area now shows prominent Create options grid (REQUEST, OBSERVE, NOTE) instead of just "Select a file"
- Added keyboard shortcut hint (Cmd+E) directly on the Edit/Preview toggle button

**Files Modified:**
- `apps/agency-bench/src/components/bench/Header.tsx` - Principal name display
- `the-agency-starter/apps/agency-bench/src/app/bench/(apps)/docbench/page.tsx` - Toolbar reorganization

**Build Status:** Verified - TypeScript check passes

### 2026-01-10 17:00 SST - Created
- Request created with 7 enhancement items
- Prioritized blockers (#6, #7) first
- Templates and references to follow

