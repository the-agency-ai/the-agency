# REQUEST-jordan-0040-housekeeping-unified-work-item-tracker

**Status:** In Progress
**Priority:** High
**Requested By:** jordan
**Assigned To:** housekeeping
**Created:** 2026-01-11
**Updated:** 2026-01-11

## Summary

Unified Work Item Tracker - consolidate Bugs, Ideas, Requests, and Observations into a cohesive system with unified APIs and CLI tools.

## Details

Create a unified approach to work item management across The Agency. All work item types (Bug, Idea, Request, Observation) should share common patterns, APIs, and UI components while maintaining their specific semantics.

---

## Work Item Types

| Type | Purpose | Service Status |
|------|---------|----------------|
| **Bug** | Track defects and issues | Exists |
| **Idea** | Capture ideas before they become requests | Exists |
| **Request** | Formal work requests from principals | **To Build** |
| **Observation** | Notes, findings, insights during work | **To Build** |

---

## Phase 1: API Unification

### 1.1 Common Work Item Schema

All work item types should share:

```typescript
interface WorkItemBase {
  id: string;                    // e.g., BUG-0001, IDEA-0042, REQUEST-jordan-0035
  type: 'bug' | 'idea' | 'request' | 'observation';
  title: string;
  summary: string;
  status: string;                // Type-specific statuses

  // Attribution
  reporterType: 'agent' | 'principal' | 'system';
  reporterName: string;
  assigneeType?: 'agent' | 'principal';
  assigneeName?: string;

  // Organization
  workstream?: string;
  tags: string[];

  // Timestamps
  createdAt: string;
  updatedAt: string;

  // Content
  filePath: string;              // Path to markdown file
  content?: string;              // Full markdown content
}
```

### 1.2 Unified API Pattern

Each service should implement consistent endpoints:

```
POST   /api/{type}/create
GET    /api/{type}/list
GET    /api/{type}/get/:id
POST   /api/{type}/update/:id
POST   /api/{type}/update-status/:id
POST   /api/{type}/assign/:id
POST   /api/{type}/delete/:id
GET    /api/{type}/stats
```

### 1.3 Unified Query Parameters for /list

All services should support:

| Parameter | Description |
|-----------|-------------|
| `status` | Filter by status |
| `assignee` | Filter by assignee name |
| `reporter` | Filter by reporter name |
| `workstream` | Filter by workstream |
| `tags` | Filter by tags (comma-separated) |
| `sortBy` | Sort field: `createdAt`, `updatedAt`, `title`, `status` |
| `sortOrder` | `asc` or `desc` |
| `search` | Text search in title/summary |
| `limit` | Pagination limit (default 50) |
| `offset` | Pagination offset (default 0) |

### 1.4 Service Work Required

#### bug-service (enhance)
- [ ] Add `sortBy`, `sortOrder` parameters
- [ ] Add `search` parameter
- [ ] Add `tags` filter
- [ ] Ensure schema matches WorkItemBase

#### idea-service (enhance)
- [ ] Add `sortBy`, `sortOrder` parameters
- [ ] Add `search` parameter
- [ ] Ensure consistent endpoint naming
- [ ] Ensure schema matches WorkItemBase

#### request-service (build new)
- [ ] Create full service following unified pattern
- [ ] Repository, service, routes, types
- [ ] File-based storage in `claude/principals/*/requests/`

#### observation-service (build new)
- [ ] Create full service following unified pattern
- [ ] Define observation statuses and workflow
- [ ] File-based storage location TBD

---

## Phase 2: CLI Tools (`/agency` namespace)

### 2.1 Unified CLI Pattern

```bash
# Create work items
./tools/agency bug "Title" --description "Details"
./tools/agency idea "Title" --description "Details"
./tools/agency request "Title" --principal jordan
./tools/agency observation "Title" --context "file.md"

# List work items
./tools/agency bugs [--status open] [--assignee me]
./tools/agency ideas [--status exploring]
./tools/agency requests [--principal jordan] [--status open]
./tools/agency observations [--workstream housekeeping]

# View single item
./tools/agency bug BUG-0001
./tools/agency request REQUEST-jordan-0035

# Update status
./tools/agency bug BUG-0001 --status fixed
./tools/agency request REQUEST-jordan-0035 --status complete

# Assign
./tools/agency bug BUG-0001 --assign agent:web
./tools/agency request REQUEST-jordan-0035 --assign agent:housekeeping
```

### 2.2 CLI Tools to Create

- [ ] `./tools/agency` - Main entry point with subcommands
- [ ] Subcommands: `bug`, `bugs`, `idea`, `ideas`, `request`, `requests`, `observation`, `observations`
- [ ] Common flags across all types
- [ ] Output formatting (table, json, minimal)

---

## Phase 3: Unified Tracker UI (AgencyBench)

### 3.1 Work Items DevApp

New DevApp in AgencyBench: **Work Items** (or **Tracker**)

Features:
- [ ] Unified list view across all work item types
- [ ] Type tabs/filter (All | Bugs | Ideas | Requests | Observations)
- [ ] Status filter chips
- [ ] Assignee/reporter filters
- [ ] Workstream filter
- [ ] Sort controls
- [ ] Search bar
- [ ] List view with columns: Type, ID, Title, Status, Assignee, Updated
- [ ] Click to view/edit details
- [ ] Quick actions (assign, change status)

### 3.2 Kanban View (Future)

- [ ] Board view grouped by status
- [ ] Drag-and-drop status changes
- [ ] Swimlanes by type or workstream

### 3.3 DocBench Integration

Update Insert menu pickers (from REQUEST-0035):
- [ ] Unified work item picker
- [ ] Type selector
- [ ] All filters/sort/search
- [ ] Insert reference to selected item

---

## Phase 4: Slash Commands (from REQUEST-0038)

Integrate with `/agency` slash command namespace:

```
/agency bug "Title"           # Quick create bug
/agency idea "Title"          # Quick create idea
/agency request "Title"       # Quick create request
/agency observation "Note"    # Quick create observation

/agency bugs                  # List my bugs
/agency requests --open       # List open requests
```

---

## Service Inventory (Current State)

| Service | Exists | Unified Schema | Sort | Search | Tags |
|---------|--------|----------------|------|--------|------|
| bug-service | Yes | Partial | No | No | No |
| idea-service | Yes | Partial | ? | ? | Yes |
| request-service | **Yes** | **Yes** | **Yes** | **Yes** | **Yes** |
| observation-service | **Yes** | **Yes** | **Yes** | **Yes** | **Yes** |

---

## Acceptance Criteria

- [ ] All four services implement unified API pattern
- [ ] All services support common query parameters
- [ ] `./tools/agency` CLI works for all types
- [ ] Work Items DevApp in AgencyBench
- [ ] DocBench picker uses unified API
- [ ] `/agency` slash commands work in Claude Code

## Dependencies

- REQUEST-jordan-0035 (DocBench integration - picker dialogs)
- REQUEST-jordan-0038 (Slash commands)

## Notes

- Observation workflow/statuses TBD - may be simpler than bugs/requests
- Consider: should observations auto-link to the file/context they're about?
- Consider: work item relationships (idea promotes to request, request spawns bugs)

---

## Activity Log

### 2026-01-11 - Created
- Initial request capturing unified tracker vision
- Identified 4 work item types: Bug, Idea, Request, Observation

### 2026-01-11 - Phase 1 Implementation Complete
- **TAG**: `REQUEST-jordan-0040-phase1-impl`
- Built request-service with unified API pattern
- Implemented: types, repository, service, routes
- 47 tests passing (repository, service, routes)
- Endpoints: create, list, get, update, update-status, assign, delete, stats
- Full support for: filters, sorting (sortBy/sortOrder), search, pagination, tags

### 2026-01-11 - Phase 1 Code Review Complete
- **TAG**: `REQUEST-jordan-0040-phase1-review`
- Code review with 2 subagents identified security issues
- Applied fixes:
  - CRITICAL: Atomic UPSERT for sequence ID (race condition fix)
  - CRITICAL: Escape SQL LIKE patterns (%, _, \\) to prevent injection
  - HIGH: Validate sort direction to prevent SQL injection
  - HIGH: Safe JSON parsing with fallback for malformed tags
- Added 3 new security tests
- 50 tests passing

### 2026-01-11 - Phase 1 Test Review Complete
- **TAG**: `REQUEST-jordan-0040-phase1-tests`
- Test review with 2 subagents identified coverage gaps
- Applied improvements:
  - Added 404 tests for update, update-status, assign, delete routes
  - Added all valid status values transition test
  - Added pagination edge cases (offset > total, limit = 0)
  - Added filter combination tests (principal AND status)
  - Added assignee and reporter filter tests
- 60 tests passing (10 new tests added)

### 2026-01-11 - Phase 2 Implementation Complete
- **TAG**: `REQUEST-jordan-0040-phase2-impl`
- Built observation-service following unified API pattern
- Simpler workflow: Open, Acknowledged, Noted, Archived
- Categories: insight, pattern, concern, improvement, note, finding
- Context linking: contextPath, contextLine, contextRef
- 52 tests passing (repository, service, routes)

### 2026-01-11 - Phase 2 Code Review Complete
- **TAG**: `REQUEST-jordan-0040-phase2-review`
- Code review with 2 subagents identified issues
- Applied fixes:
  - CRITICAL: Atomic increment-then-read for sequence ID
  - HIGH: Added ObservationListResponse with pagination metadata
  - MEDIUM: Fixed limit min(0) to min(1)
- 52 tests passing
