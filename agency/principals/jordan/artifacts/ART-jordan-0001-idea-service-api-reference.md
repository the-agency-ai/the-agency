# ART-jordan-0001: Idea Service API Reference

**Created:** 2026-01-10
**Author:** housekeeping
**REQUEST:** REQUEST-jordan-0011 (Phase 3)
**Status:** Complete

## Overview

The **idea-service** is an embedded service within TheAgencyService for capturing and managing ideas. Ideas can be promoted to REQUESTs when they're ready to become actionable work items.

## Base URL

```
http://localhost:3456/api/idea
```

## API Endpoints

### Create Idea

Capture a new idea.

```
POST /api/idea/create
```

**Request Body:**
```json
{
  "title": "Visual workflow editor for agents",
  "description": "Optional detailed description...",
  "sourceType": "principal",
  "sourceName": "jordan",
  "tags": ["ui", "tooling"]
}
```

**Response (201 Created):**
```json
{
  "id": 1,
  "ideaId": "IDEA-00001",
  "title": "Visual workflow editor for agents",
  "description": "Optional detailed description...",
  "status": "captured",
  "sourceType": "principal",
  "sourceName": "jordan",
  "tags": ["ui", "tooling"],
  "promotedTo": null,
  "createdAt": "2026-01-10T10:30:00.000Z",
  "updatedAt": "2026-01-10T10:30:00.000Z"
}
```

### List Ideas

List ideas with optional filters.

```
GET /api/idea/list?status=captured&source=jordan&tag=ui&search=workflow&limit=50&offset=0
```

**Query Parameters:**
| Parameter | Type | Description |
|-----------|------|-------------|
| status | enum | Filter by status: `captured`, `exploring`, `promoted`, `parked`, `discarded` |
| source | string | Filter by source name |
| tag | string | Filter by tag |
| search | string | Search in title and description |
| limit | number | Max results (1-100, default 50) |
| offset | number | Pagination offset (default 0) |

**Response (200 OK):**
```json
{
  "ideas": [...],
  "total": 42,
  "limit": 50,
  "offset": 0
}
```

### Get Idea

Get a specific idea by ID.

```
GET /api/idea/get/:ideaId
```

**Response (200 OK):** Full idea object

**Response (400 Bad Request):** Invalid ideaId format

**Response (404 Not Found):** Idea not found

### Update Idea

Update an idea's fields.

```
POST /api/idea/update/:ideaId
```

**Request Body:**
```json
{
  "title": "Updated title",
  "description": "Updated description",
  "status": "exploring"
}
```

**Note:** Promoted ideas cannot be updated except to `parked` or `discarded` status.

### Promote Idea

Promote an idea to a REQUEST.

```
POST /api/idea/promote/:ideaId
```

**Request Body:**
```json
{
  "requestId": "REQUEST-jordan-0025"
}
```

**Response (200 OK):**
```json
{
  "ideaId": "IDEA-00001",
  "status": "promoted",
  "promotedTo": "REQUEST-jordan-0025",
  ...
}
```

**Note:** Already promoted or discarded ideas cannot be promoted.

### Status Transitions

Convenience endpoints for common status changes:

```
POST /api/idea/explore/:ideaId   # captured → exploring
POST /api/idea/park/:ideaId      # any → parked
POST /api/idea/discard/:ideaId   # any → discarded
```

### Tag Management

```
POST /api/idea/add-tags/:ideaId
POST /api/idea/remove-tags/:ideaId
```

**Request Body:**
```json
{
  "tags": ["new-tag", "another"]
}
```

**Note:** Tags must be alphanumeric with hyphens and underscores only (max 50 chars each, max 20 tags total).

### Delete Idea

```
POST /api/idea/delete/:ideaId
```

**Response (200 OK):**
```json
{
  "success": true,
  "ideaId": "IDEA-00001"
}
```

### Get Statistics

```
GET /api/idea/stats
```

**Response (200 OK):**
```json
{
  "total": 42,
  "captured": 20,
  "exploring": 10,
  "promoted": 8,
  "parked": 3,
  "discarded": 1
}
```

## Idea Status Workflow

```
captured → exploring → promoted (linked to REQUEST)
    ↓          ↓           ↓
  parked     parked      parked
    ↓          ↓           ↓
discarded  discarded   discarded
```

- **captured**: Initial state when idea is created
- **exploring**: Actively investigating feasibility
- **promoted**: Converted to an actionable REQUEST
- **parked**: Saved for later consideration
- **discarded**: Rejected, no longer relevant

## Validation

- `title`: Required, 1-200 characters
- `description`: Optional, max 5000 characters
- `sourceType`: Required, one of `agent`, `principal`, `system`
- `sourceName`: Required, 1-100 characters
- `tags`: Array of alphanumeric strings (hyphens/underscores allowed), max 20 tags, each max 50 chars
- `ideaId`: Must match pattern `IDEA-XXXXX` (e.g., `IDEA-00001`)

## Error Responses

**400 Bad Request:**
```json
{
  "error": "Bad Request",
  "message": "Invalid idea ID format (expected IDEA-XXXXX)"
}
```

**404 Not Found:**
```json
{
  "error": "Not Found",
  "message": "Idea IDEA-99999 not found"
}
```

**500 Internal Server Error:**
```json
{
  "error": "Internal Server Error",
  "message": "An unexpected error occurred"
}
```

## Test Coverage

The idea-service has 67 tests across 3 test files:
- `repository.test.ts`: CRUD operations, pagination, tag search
- `service.test.ts`: Business logic, status transitions, promotion guards
- `routes.test.ts`: API endpoints, validation, error handling

All tests passing (218 total tests in agency-service).
