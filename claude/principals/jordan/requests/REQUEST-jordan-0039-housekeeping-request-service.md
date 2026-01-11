# REQUEST-jordan-0039-housekeeping-request-service

**Status:** Open
**Priority:** High
**Requested By:** jordan
**Assigned To:** housekeeping
**Created:** 2026-01-11
**Updated:** 2026-01-11

## Summary

Request Service - API-based REQUEST management
[(jordan) Request Service - API-based REQUEST management]
[(jordan) ]

## Details

Create a proper backend service for managing REQUESTs, similar to Bug Service, Idea Service, etc. The current `./tools/requests` tool parses markdown files directly, but we should have a proper service with:

- Database storage for metadata
- API endpoints for CRUD operations
- Cross-principal visibility
- Status tracking and filtering
- Integration with other services (Ideas promote to REQUESTs)

## Current State

`./tools/requests` exists but:
- Parses markdown files directly
- No API backend
- Limited filtering capabilities
- No cross-principal aggregation

## Requirements

### Core Features

1. **CRUD Operations**
   - Create REQUEST
   - List REQUESTs (with filters)
   - Get REQUEST by ID
   - Update REQUEST
   - Delete REQUEST

2. **Filtering**
   - By principal (default: current, option: all)
   - By status (Open, In Progress, Completed, Blocked)
   - By priority (Critical, High, Normal, Low)
   - By assigned agent
   - By workstream
   - By date range

3. **Status Workflow**
   ```
   Open → In Progress → Review → Testing → Completed
                    ↘ Blocked ↗
   ```

4. **Cross-Principal Visibility**
   - See own REQUESTs by default
   - Option to see all REQUESTs
   - Permissions for editing others' REQUESTs

5. **Integration Points**
   - Idea Service: Promote idea to REQUEST
   - Bug Service: Link bugs to REQUESTs
   - Test Service: Link test runs to REQUESTs

### API Design

Following the explicit operations pattern:

```
POST /api/request/create
GET  /api/request/list
GET  /api/request/get/:id
POST /api/request/update/:id
POST /api/request/update-status/:id
POST /api/request/assign/:id
POST /api/request/delete/:id
GET  /api/request/stats
GET  /api/request/by-principal/:name
```

### Data Model

```typescript
interface Request {
  id: string;              // e.g., "REQUEST-jordan-0039"
  principal: string;       // e.g., "jordan"
  number: number;          // e.g., 39
  title: string;
  summary: string;
  status: Status;
  priority: Priority;
  assignedTo?: string;     // agent name
  workstream?: string;
  createdAt: Date;
  updatedAt: Date;
  completedAt?: Date;

  // Relations
  linkedBugs?: string[];
  linkedIdeas?: string[];
  linkedTests?: string[];
}
```

### CLI Tool Updates

Update `./tools/requests` to use the API:
```bash
./tools/requests                    # List my open REQUESTs
./tools/requests --all              # List all open REQUESTs
./tools/requests --principal=alex   # List Alex's REQUESTs
./tools/requests completed          # List completed
./tools/requests show 0039          # Show details
./tools/requests create "Title"     # Create new REQUEST
```

## Deliverables

- [ ] Request Service (repository, service, routes)
- [ ] Database schema and migrations
- [ ] API endpoints
- [ ] Updated `./tools/requests` CLI to use API
- [ ] `/agency request` slash command integration
- [ ] Tests (unit + integration)
- [ ] Documentation

## Acceptance Criteria

- [ ] Can create REQUEST via API
- [ ] Can list REQUESTs with filters
- [ ] Can view cross-principal REQUESTs
- [ ] CLI tool uses API backend
- [ ] Ideas can be promoted to REQUESTs
- [ ] Bugs can be linked to REQUESTs
- [ ] Status transitions work correctly

## Notes

This completes the service ecosystem - we have Bug, Idea, Product, etc. but REQUEST is fundamental to how work is tracked in The Agency.

The file-based REQUESTs can continue to exist as the source of truth for detailed documentation, but the service provides fast querying and status tracking.

---

## Activity Log

### 2026-01-11 - Created
- Request created by jordan
- Need for API-based REQUEST management identified
- Current ./tools/requests parses files directly

[(jordan) ]
[(jordan) ]
[(jordan) ]
[(jordan) ]