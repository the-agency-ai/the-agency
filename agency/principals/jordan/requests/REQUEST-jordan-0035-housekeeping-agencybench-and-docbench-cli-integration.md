# REQUEST-jordan-0035-housekeeping-agencybench-and-docbench-cli-integration

**Status:** In Progress
**Priority:** High
**Requested By:** agent:housekeeping (on behalf of jordan)
**Assigned To:** housekeeping
**Created:** 2026-01-11
**Updated:** 2026-01-11

## Summary

AgencyBench and DocBench CLI integration, Insert menu improvements, and work item services.

## Details

Improve AgencyBench and DocBench CLI integration for seamless document workflow. Fix Insert menu functionality in DocBench. Build request-service and enhance bug-service for picker dialogs.

---

## Work Items

### Phase 1: CLI Tools (COMPLETE)

- [x] `./tools/agency-bench` - launch AgencyBench app
- [x] `./tools/docbench` - CLI for DocBench operations
- [x] `./tools/docbench open <path>` - open document
- [x] `./tools/docbench save-as <path>` - save as
- [x] `./tools/bench-build` - build tool with version management
- [x] App icon fixed (using logo.svg)
- [x] Version format: MAJOR.MINOR.PATCH-YYYYMMDD-BUILDNUMBER
- [x] All DevApps now 1.x.x versions

### Phase 2: Insert Comment Fixes

- [x] ~~2.1 Insert Comment - Edit Mode~~ - Working correctly
- [x] ~~2.2 Insert Comment - Markdown Rendering~~ - Insertion correct; Preview rendering is separate concern
- [ ] 2.3 Insert Comment - Preview Mode Bug
  - Insert Comment does not work from Preview/Rich Text view
  - Currently just switches to Edit mode without inserting
  - Should capture selection and insert comment block

### Phase 3: Insert Image Fix

- [ ] 3.1 Forbidden Path Error
  - Insert Image fails with "forbidden path" error
  - Tauri security/permissions issue
  - Need to configure Tauri `fs` scope to allow project directories
  - Error: `forbidden path: /Users/jdm/code/the-agency/claude/assets/images/...`

### Phase 4: Request Service (NEW)

Build new embedded service in agency-service for REQUEST file management.

#### 4.1 Core Service
- [ ] Create `services/agency-service/src/embedded/request-service/`
- [ ] Repository layer (file-based, like bug-service)
- [ ] Service layer with business logic
- [ ] Types and schemas

#### 4.2 API Endpoints
- [ ] `POST /api/request/create` - Create REQUEST
- [ ] `GET /api/request/list` - List with filters
- [ ] `GET /api/request/get/:requestId` - Get single REQUEST
- [ ] `POST /api/request/update/:requestId` - Update REQUEST
- [ ] `POST /api/request/update-status/:requestId` - Change status
- [ ] `POST /api/request/assign/:requestId` - Assign to agent/principal
- [ ] `POST /api/request/delete/:requestId` - Delete REQUEST
- [ ] `GET /api/request/stats` - Statistics

#### 4.3 Query Parameters for /list
- [ ] `status` - Filter by status (Open, In Progress, Complete, etc.)
- [ ] `principal` - Filter by requesting principal
- [ ] `assignee` - Filter by assigned agent/principal
- [ ] `workstream` - Filter by workstream
- [ ] `sortBy` - Sort field (createdAt, modifiedAt, filename)
- [ ] `sortOrder` - Sort direction (asc, desc)
- [ ] `search` - Text search in title/summary
- [ ] `limit`, `offset` - Pagination

### Phase 5: Bug Service Enhancements

Enhance existing bug-service with missing query capabilities.

- [ ] 5.1 Add `sortBy` parameter (createdAt, modifiedAt, filename, status)
- [ ] 5.2 Add `sortOrder` parameter (asc, desc)
- [ ] 5.3 Add `search` parameter (text search in title/description)
- [ ] 5.4 Add `principal` filter (if not already present)

### Phase 6: AgencyBench Integration

Integrate services into DocBench Insert menu.

#### 6.1 Bug Picker Dialog
- [ ] Replace simple insert with browse dialog
- [ ] List all BUG files from bug-service API
- [ ] Filter controls: status, workstream, assignee, reporter
- [ ] Sort controls: createdAt, modifiedAt, filename (asc/desc)
- [ ] Search input
- [ ] Select and insert reference

#### 6.2 Request Picker Dialog
- [ ] Replace simple insert with browse dialog
- [ ] List all REQUEST files from request-service API
- [ ] Filter controls: status, principal, assignee, workstream
- [ ] Sort controls: createdAt, modifiedAt, filename (asc/desc)
- [ ] Search input
- [ ] Select and insert reference

#### 6.3 UI Considerations
- [ ] **Discussion point**: Unified picker UI for both Bugs and Requests?
  - Type selector (Bug / Request / Both)
  - Shared filter/sort/search controls
  - Consistent UX across work item types
  - Decision to be made when reaching this phase

### Phase 7: Final Integration

- [ ] Integration with Claude Code (tool use)
- [ ] End-to-end testing
- [ ] Documentation updates

---

## Current Service Inventory

| Service | Status | Filters | Sort | Search |
|---------|--------|---------|------|--------|
| bug-service | Exists | workstream, status, assignee, reporter | **NO** | **NO** |
| request-service | **MISSING** | - | - | - |

---

## Acceptance Criteria

- [ ] Insert Comment works from Preview mode
- [ ] Insert Image works without permission errors
- [ ] request-service API fully functional
- [ ] bug-service enhanced with sort/search
- [ ] Insert Bug shows picker with filters/sort/search
- [ ] Insert Request shows picker with filters/sort/search
- [ ] All CLI tools working

## Notes

- Insert Document works (inserts full path)
- Insert Comment works correctly in Edit/Markdown mode
- rsvg-convert documented as dependency in CLAUDE.md
- Consider unified Bug/Request picker UI (discuss at Phase 6)

---

## Activity Log

### 2026-01-11 - Created
- Request created by agent:housekeeping (on behalf of jordan)

### 2026-01-11 - Phase 1 Complete
- Created `./tools/agency-bench`, `./tools/docbench`, `./tools/bench-build`
- Fixed app icon using logo.svg
- Implemented version system with build numbers
- All DevApps updated to 1.x.x versions

### 2026-01-11 - Phase 2 Partial
- Fixed Insert Comment in Edit mode (correct behavior now)
- Identified Preview mode bug (2.3 remaining)

### 2026-01-11 - Service Assessment
- bug-service exists but needs sort/search enhancements
- request-service needs to be built from scratch
- Expanded scope to include service work (Phases 4-6)
