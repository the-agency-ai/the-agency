# REQUEST-jordan-0016: Product Service + API Refactor

**Requested By:** principal:jordan

**Assigned To:** housekeeping

**Status:** Complete

**Priority:** High

**Created:** 2026-01-10 14:30 SST

**Completed:** 2026-01-10 14:45 SST

## Summary

Create a product service for managing PRDs (Product Requirement Documents) with explicit API operations. Then refactor all existing services to use explicit operation names instead of relying on HTTP verb semantics.

## Tasks

### Phase 1: Product Service
- [x] Create product-service types
- [x] Create product repository
- [x] Create product service
- [x] Create product routes (explicit operations)
- [x] Register in main app
- [x] Fix race condition in PRD ID generation
- [x] Add global error handler with sanitized messages

### Phase 2: API Refactor
- [x] Refactor bug-service to explicit operations
- [x] Refactor messages-service to explicit operations
- [x] Refactor log-service to explicit operations
- [x] Refactor test-service to explicit operations
- [x] Update tests for new route paths
- [x] All 151 tests passing

## API Design

### Product Service (new)
```
POST /api/products/create
GET  /api/products/list
GET  /api/products/get/:id
POST /api/products/update/:id
POST /api/products/add-contributor/:id
POST /api/products/remove-contributor/:id
POST /api/products/approve/:id
POST /api/products/archive/:id
POST /api/products/delete/:id
GET  /api/products/stats
```

### Bug Service (refactored)
```
POST /api/bug/create
GET  /api/bug/list
GET  /api/bug/get/:bugId
POST /api/bug/update/:bugId
POST /api/bug/update-status/:bugId
POST /api/bug/assign/:bugId
POST /api/bug/delete/:bugId
GET  /api/bug/stats
```

### Messages Service (refactored)
```
POST /api/message/send
GET  /api/message/list
GET  /api/message/get/:id
GET  /api/message/inbox/:recipientType/:recipientName
GET  /api/message/stats/:recipientType/:recipientName
POST /api/message/mark-read/:id
POST /api/message/mark-all-read
POST /api/message/delete/:id
```

### Log Service (refactored)
```
POST /api/log/ingest
POST /api/log/ingest-batch
GET  /api/log/query
GET  /api/log/stats
GET  /api/log/services
GET  /api/log/search
POST /api/log/run/start
POST /api/log/run/end/:runId
GET  /api/log/run/get/:runId
GET  /api/log/run/logs/:runId
GET  /api/log/run/errors/:runId
POST /api/log/cleanup
```

### Test Service (refactored)
```
POST /api/test/run/execute
POST /api/test/run/start
POST /api/test/run/execute/:id
POST /api/test/run/cancel/:id
GET  /api/test/run/list
GET  /api/test/run/latest
GET  /api/test/run/get/:id
GET  /api/test/run/results/:id
GET  /api/test/run/failures/:id
GET  /api/test/stats
GET  /api/test/flaky
GET  /api/test/suites
POST /api/test/cleanup
```

### Pattern (now standard)
- `/create` - create new resource
- `/list` - list resources with filters
- `/get/:id` - get single resource
- `/update/:id` - update resource
- `/delete/:id` - delete resource
- `/action/:id` - specific actions

## Acceptance Criteria

- [x] Product service working with all endpoints
- [x] All services use explicit operation names
- [x] Tests passing (151/151)
- [x] Pattern documented in CLAUDE.md
- [x] Pattern enforced in tools/code-review

## Releases

- **v0.2.0** - Phase 1 complete (product-service + bug-service refactor)
- **v0.2.1** - Phase 2 complete (all services using explicit API)

---

## Activity Log

### 2026-01-10 14:30 SST - Created
- Request created for product service and API refactor

### 2026-01-10 14:35 SST - Phase 1 Complete
- Created product-service with all endpoints
- Refactored bug-service to explicit operations
- Fixed race condition in PRD ID generation (atomic increment)
- Added global error handlers with sanitized messages
- Updated CLAUDE.md with API Design section
- Added API pattern check to tools/code-review
- Tagged v0.2.0

### 2026-01-10 14:45 SST - Phase 2 Complete
- Refactored messages-service routes
- Refactored log-service routes
- Refactored test-service routes
- Updated messages-service tests
- All 151 tests passing
- Tagged v0.2.1
- Pushed to remote
