# REQUEST-jordan-0016: Product Service + API Refactor

**Requested By:** principal:jordan

**Assigned To:** housekeeping

**Status:** Open

**Priority:** High

**Created:** 2026-01-10 14:30 SST

## Summary

Create a product service for managing PRDs (Product Requirement Documents) with explicit API operations. Then refactor all existing services to use explicit operation names instead of relying on HTTP verb semantics.

## Tasks

### Phase 1: Product Service
- [ ] Create product-service types
- [ ] Create product repository
- [ ] Create product service
- [ ] Create product routes (explicit operations)
- [ ] Register in main app
- [ ] Add CLI commands
- [ ] Write tests

### Phase 2: API Refactor
- [ ] Refactor bug-service to explicit operations
- [ ] Refactor messages-service to explicit operations
- [ ] Refactor log-service to explicit operations
- [ ] Refactor test-service to explicit operations
- [ ] Update CLI tools if needed
- [ ] Run tests

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
```

### Pattern for all services
- `/create` - create new resource
- `/list` - list resources with filters
- `/get/:id` - get single resource
- `/update/:id` - update resource
- `/delete/:id` - delete resource
- `/action/:id` - specific actions

## Acceptance Criteria

- [ ] Product service working with all endpoints
- [ ] All services use explicit operation names
- [ ] Tests passing
- [ ] CLI updated if needed

---

## Activity Log

### 2026-01-10 14:30 SST - Created
- Request created for product service and API refactor
