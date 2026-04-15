# Extending The Agency

This guide covers how to extend The Agency with custom functionality.

## Creating Agents

Agents are specialized Claude Code instances with context and memory.

```bash
./tools/agent-create <agent-name> <workstream>
```

**Example:**
```bash
./tools/agent-create frontend web
```

Creates:
- `claude/agents/frontend/agent.md` - Identity and capabilities

**Agent spec (`agent.md`) should include:**
- Purpose and role
- Capabilities and tools available
- Interaction patterns
- Knowledge sources

## Creating Workstreams

Workstreams organize related work areas.

```bash
./tools/workstream-create <workstream-name>
```

**Example:**
```bash
./tools/workstream-create analytics
```

Creates:
- `claude/workstreams/analytics/` - Workstream directory
- Sprint directories for planned work

## Building Tools

Tools are shell scripts in the `claude/tools/` directory that follow specific patterns for consistency and observability.

### Creating a New Tool

```bash
./claude/tools/tool-create <tool-name> "<description>"
```

This generates a tool from the template at `claude/templates/TOOL.sh` with:
- Argument parsing (--help, --version, --verbose)
- JSONL logging integration
- Run ID tracking
- Context-efficient output

### Tool Output Standard

**Critical:** Tools must minimize stdout to save context window tokens.

```bash
# stdout format (what Claude sees)
tool-name [run: abc123]
✓                          # or ✗ for failure

# That's it! 2-3 lines max.
```

| Location | Content | Token Impact |
|----------|---------|--------------|
| stdout | 10-20 tokens | In context |
| Log service | Full verbose output | Zero (database) |

### Tool Structure

```bash
#!/bin/bash
# my-tool - Brief description
set -euo pipefail

# Source log helper
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/_log-helper"

# Start tracking (gets run ID)
RUN_ID=$(log_start "my-tool" "agency-tool" "$@")

# Parse arguments
VERBOSE=false
while [[ $# -gt 0 ]]; do
    case $1 in
        --verbose|-v) VERBOSE=true; shift ;;
        --help|-h) show_help; exit 0 ;;
        *) shift ;;
    esac
done

# Do work...
# Use log_info, log_warn, log_error for verbose output

# End tracking
log_end "$RUN_ID" "success" "0" "" "Completed"

# Output (context-efficient)
echo "my-tool [run: $RUN_ID]"
echo "✓"
```

### Debugging Failed Tools

```bash
# View full output from a run
./tools/agency-service log run <run-id>

# View only errors
./tools/agency-service log run <run-id> errors
```

## Logging System

The Agency uses a centralized log service for tool observability.

### Architecture

```
Tool runs → _log-helper → Log Service API → SQLite
                              ↓
                     ./tools/agency-service log
```

### Using _log-helper

Source it at the top of your tool:

```bash
source "$(dirname "$0")/_log-helper"

# Start a run (returns run ID)
RUN_ID=$(log_start "tool-name" "agency-tool" "$@")

# Log during execution (goes to database, not stdout)
log_info "$RUN_ID" "Processing file: $file"
log_warn "$RUN_ID" "Skipped invalid entry"
log_error "$RUN_ID" "Failed to connect"

# End the run
log_end "$RUN_ID" "success" "$exit_code" "$output_size" "Summary message"
```

### Log Service CLI

```bash
# View recent runs
./tools/agency-service log list

# View specific run
./tools/agency-service log run <run-id>

# View errors only
./tools/agency-service log run <run-id> errors

# Search logs
./tools/agency-service log search "error message"
```

### Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `LOG_SERVICE_URL` | `http://127.0.0.1:3141` | Log service endpoint |
| `LOG_TOOL_DEBUG` | (unset) | Set to "1" for debug output |
| `AGENT_NAME` | (unset) | Current agent name |
| `WORKSTREAM` | (unset) | Current workstream |

## Test Infrastructure

The Agency uses a test-service for test execution and tracking.

**Full documentation:** See `claude/REFERENCE-TESTING.md`

### Quick Reference

```bash
# Run all tests
./tools/test-run

# Run via service (with tracking)
./tools/agency-service test run

# Run specific suite
./tools/agency-service test run core

# View results
./tools/agency-service test latest
./tools/agency-service test get <run-id>

# Statistics
./tools/agency-service test stats
./tools/agency-service test flaky
```

### Configuration

Test suites are defined in `.agency/test-config.yaml`:

```yaml
version: "1.0"

runners:
  - id: bun
    command: [bun, test]
    outputFormat: bun

targets:
  - id: agency-service
    path: source/services/agency-service
    runner: bun

suites:
  - id: core
    name: Core Tests
    target: agency-service
    path: tests/core
    tags: [unit, fast]
    enabled: true
```

### Adding Tests

1. Create test file in appropriate `tests/` directory
2. Register suite if new directory:
   ```bash
   ./tools/agency-service test register my-suite "My Suite" agency-service tests/my-suite
   ```
3. Run to verify:
   ```bash
   ./tools/agency-service test run my-suite
   ```

## Adding Starter Packs

Starter packs provide framework-specific conventions.

Location: `claude/starter-packs/<framework>/`

**Structure:**
```
claude/starter-packs/nextjs/
├── CONVENTIONS.md      # Framework conventions
├── PATTERNS.md         # Common patterns
└── templates/          # File templates
```

## Extending Agency Service

The agency-service is the central API layer for The Agency. CLI tools and AgencyBench call it instead of direct database access.

**Location:** `source/services/agency-service/`

### Architecture

```
src/
├── core/              # Infrastructure (database, queue, config)
│   ├── adapters/      # Database and queue implementations
│   ├── lib/           # Shared utilities (logger)
│   └── middleware/    # Auth and logging middleware
├── embedded/          # Embedded services
│   ├── bug-service/
│   ├── idea-service/
│   ├── log-service/
│   ├── messages-service/
│   ├── observation-service/
│   ├── product-service/
│   ├── request-service/
│   ├── secret-service/
│   └── test-service/
└── index.ts           # Main entry point
```

### Adding an Embedded Service

Each embedded service follows the same pattern:

```
my-service/
├── index.ts           # Service factory (createMyService)
├── types.ts           # TypeScript interfaces
├── repository/        # Data access layer
│   └── index.ts
├── routes/            # HTTP endpoints
│   └── index.ts
└── service/           # Business logic
    └── index.ts
```

**1. Create the service structure:**
```bash
mkdir -p source/services/agency-service/src/embedded/my-service/{repository,routes,service}
```

**2. Define types (`types.ts`):**
```typescript
export interface MyEntity {
  id: string;
  name: string;
  createdAt: Date;
}
```

**3. Implement repository (`repository/index.ts`):**
```typescript
export function createMyRepository(db: Database) {
  return {
    async create(entity: MyEntity) { /* ... */ },
    async findById(id: string) { /* ... */ },
    async list() { /* ... */ },
  };
}
```

**4. Implement service (`service/index.ts`):**
```typescript
export function createMyServiceLogic(repo: MyRepository) {
  return {
    async createEntity(data: CreateInput) { /* business logic */ },
  };
}
```

**5. Define routes (`routes/index.ts`):**
```typescript
export function createMyRoutes(service: MyService) {
  const router = new Hono();
  router.post('/api/my-service/create', async (c) => { /* ... */ });
  router.get('/api/my-service/list', async (c) => { /* ... */ });
  return router;
}
```

**6. Wire it up (`index.ts`):**
```typescript
export function createMyService({ db, queue }: ServiceDeps) {
  const repo = createMyRepository(db);
  const service = createMyServiceLogic(repo);
  const routes = createMyRoutes(service);

  return {
    initialize: async () => { /* migrations, etc */ },
    routes,
  };
}
```

**7. Register in main (`src/index.ts`):**
```typescript
import { createMyService } from './embedded/my-service';

const myService = createMyService({ db, queue });
await myService.initialize();
app.route('/', myService.routes);
```

### API Design Pattern

All endpoints use explicit operations (see `CLAUDE.md`):

```
POST /api/my-service/create      # Create
GET  /api/my-service/list        # List
GET  /api/my-service/get/:id     # Get single
POST /api/my-service/update/:id  # Update
POST /api/my-service/delete/:id  # Delete
```

### Running the Service

```bash
./tools/agency-service start     # Start service
./tools/agency-service stop      # Stop service
./tools/agency-service status    # Check status
```

## MCP Server Integration

MCP servers extend Claude's capabilities.

Configuration: `.claude/settings.json` or project-level MCP config.

**Common integrations:**
- Browser MCP - Authenticated web access
- Database MCP - Direct database queries
- Custom MCPs - Project-specific tools

See `claude/REFERENCE-BROWSER-MCP.md` for browser integration details.

## Custom Slash Commands

Add commands to `.claude/commands/`:

```
.claude/commands/
└── my-command.md    # /my-command
```

The markdown file contains instructions for Claude to execute.

See existing commands in `.claude/commands/agency*.md` for examples.

## Best Practices

1. **Follow conventions** - Match existing patterns
2. **Document as you go** - Update relevant documentation
3. **Test your extensions** - Verify they work across sessions
4. **Keep it simple** - Minimal complexity for the task

## Questions?

```bash
./tools/myclaude housekeeping captain "How do I extend X?"
```
