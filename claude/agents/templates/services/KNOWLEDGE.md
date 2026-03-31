# {{AGENT_NAME}} Knowledge

## Imported Knowledge Bases

- [Services Patterns](../../../knowledge/services-patterns/INDEX.md) - Service design patterns (when available)

## API Design Principles

### RESTful Conventions

**Resource Naming:**
```
GET    /api/users              # List users
POST   /api/users/create       # Create user (explicit operation)
GET    /api/users/get/:id      # Get single user
POST   /api/users/update/:id   # Update user
POST   /api/users/delete/:id   # Delete user
```

**Why explicit operations:**
- Self-documenting URLs
- Clear intent without HTTP verb semantics
- Easier to search/grep
- Consistent across all services

**Query Parameters:**
```
GET /api/users/list?page=1&limit=20&sort=created_at&order=desc
GET /api/users/search?q=john&status=active
```

**Response Format:**
```json
{
  "data": { ... },
  "meta": {
    "page": 1,
    "limit": 20,
    "total": 100
  },
  "error": null
}
```

### Error Handling

**Error Response:**
```json
{
  "data": null,
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Invalid email format",
    "details": {
      "field": "email",
      "value": "invalid",
      "constraint": "email_format"
    }
  }
}
```

**HTTP Status Codes:**
| Code | Usage |
|------|-------|
| 200 | Success |
| 201 | Created |
| 400 | Client error (validation, bad request) |
| 401 | Unauthorized |
| 403 | Forbidden |
| 404 | Not found |
| 409 | Conflict |
| 500 | Server error |

## Database Design

### Schema Principles

**Naming Conventions:**
```sql
-- Tables: plural, snake_case
CREATE TABLE users (...);
CREATE TABLE order_items (...);

-- Columns: snake_case
user_id, created_at, is_active

-- Indexes: table_column_idx
CREATE INDEX users_email_idx ON users(email);

-- Foreign keys: table_column_fk
CONSTRAINT order_items_order_id_fk FOREIGN KEY (order_id) REFERENCES orders(id)
```

**Standard Columns:**
```sql
CREATE TABLE example (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  -- ... entity columns ...
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  deleted_at TIMESTAMP WITH TIME ZONE  -- Soft delete
);
```

### Normalization Guidelines

**When to Normalize:**
- Data integrity is critical
- Updates are frequent
- Storage efficiency matters
- Relationships are complex

**When to Denormalize:**
- Read performance is critical
- Data rarely changes
- Reporting/analytics queries
- Caching layer exists

### Index Strategy

**Index When:**
- Column appears in WHERE clauses
- Column used for JOIN conditions
- Column used for ORDER BY
- Column has high selectivity

**Index Types:**
```sql
-- B-tree (default): equality and range queries
CREATE INDEX users_email_idx ON users(email);

-- Composite: multiple columns
CREATE INDEX orders_user_status_idx ON orders(user_id, status);

-- Partial: filtered subset
CREATE INDEX active_users_idx ON users(email) WHERE is_active = true;

-- Unique: enforce uniqueness
CREATE UNIQUE INDEX users_email_unique ON users(email);
```

## Data Modeling

### Entity Relationships

**One-to-Many:**
```sql
-- Users have many orders
CREATE TABLE orders (
  id UUID PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES users(id),
  ...
);
```

**Many-to-Many:**
```sql
-- Users have many roles, roles have many users
CREATE TABLE user_roles (
  user_id UUID REFERENCES users(id),
  role_id UUID REFERENCES roles(id),
  granted_at TIMESTAMP DEFAULT NOW(),
  PRIMARY KEY (user_id, role_id)
);
```

**Self-Referential:**
```sql
-- Categories with parent categories
CREATE TABLE categories (
  id UUID PRIMARY KEY,
  parent_id UUID REFERENCES categories(id),
  name TEXT NOT NULL
);
```

### Constraints

```sql
-- Not null
email TEXT NOT NULL

-- Unique
UNIQUE (email)

-- Check
CHECK (age >= 0)
CHECK (status IN ('pending', 'active', 'inactive'))

-- Foreign key with cascade
FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE

-- Default values
created_at TIMESTAMP DEFAULT NOW()
status TEXT DEFAULT 'pending'
```

## Migration Patterns

### Safe Migrations

**Adding Columns:**
```sql
-- Safe: nullable column
ALTER TABLE users ADD COLUMN phone TEXT;

-- Safe: column with default
ALTER TABLE users ADD COLUMN is_verified BOOLEAN DEFAULT false;
```

**Removing Columns:**
```sql
-- Step 1: Stop using column in code
-- Step 2: Deploy code changes
-- Step 3: Drop column
ALTER TABLE users DROP COLUMN deprecated_field;
```

**Renaming Columns:**
```sql
-- Step 1: Add new column
ALTER TABLE users ADD COLUMN full_name TEXT;
-- Step 2: Copy data
UPDATE users SET full_name = name;
-- Step 3: Update code to use new column
-- Step 4: Drop old column
ALTER TABLE users DROP COLUMN name;
```

### Migration Checklist

- [ ] Migration is reversible (or documented why not)
- [ ] No locks on large tables during peak hours
- [ ] Indexes added for new foreign keys
- [ ] Default values provided for NOT NULL columns
- [ ] Data migration script tested on production copy

## Service Architecture

### Service Boundaries

**Good Boundaries:**
- Aligned with business domains
- Minimal cross-service transactions
- Clear ownership
- Independent deployment

**Warning Signs:**
- Circular dependencies
- Shared databases
- Chatty communication
- Distributed transactions

### Contract-First Design

```yaml
# OpenAPI specification
openapi: 3.0.0
info:
  title: User Service
  version: 1.0.0

paths:
  /api/users/create:
    post:
      summary: Create a new user
      requestBody:
        required: true
        content:
          application/json:
            schema:
              $ref: '#/components/schemas/CreateUserRequest'
      responses:
        '201':
          description: User created
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/User'

components:
  schemas:
    CreateUserRequest:
      type: object
      required:
        - email
        - name
      properties:
        email:
          type: string
          format: email
        name:
          type: string
```

## Design Checklist

### API Design
- [ ] Follows explicit operation naming
- [ ] Consistent error format
- [ ] Appropriate status codes
- [ ] Versioning strategy defined
- [ ] Rate limiting considered

### Database Design
- [ ] Tables properly normalized (or intentionally denormalized)
- [ ] Indexes on frequently queried columns
- [ ] Foreign keys with appropriate cascades
- [ ] Soft delete if needed
- [ ] Audit columns (created_at, updated_at)

### Data Modeling
- [ ] Entity relationships clear
- [ ] Constraints enforce business rules
- [ ] Data types appropriate
- [ ] Nullable vs required clear
- [ ] Default values sensible
