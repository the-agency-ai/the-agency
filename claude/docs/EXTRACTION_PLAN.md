# Workbench Component Extraction Plan

Components from ordinaryfolk-nextgen workbench that will be extracted and open-sourced as standalone packages for The Agency.

**Target:** Open-source Workbench with Staff Manager, Agent Manager, Content Manager, Pulse Beat, and potentially Catalog.

## Candidates for Extraction

### 0. Staff Manager

**Source:** `apps/internal/agent-manager/` (authentication and staff management)

**Purpose:** Manages internal staff access, authentication, and permissions.

**Extraction Value:**
- Team access control for Agency projects
- Role-based permissions
- Audit logging for compliance

**Dependencies to Resolve:**
- Auth integration needs to be pluggable (Supabase, Auth0, etc.)
- Staff model needs generalization

### 1. Content Manager

**Source:** `apps/internal/agent-manager/src/app/workbench/(auth)/content-manager/`

**Purpose:** Manages content, prompts, and templates for AI agents.

**Extraction Value:**
- Generic content management for any Agency project
- Template system for agent prompts
- Version control for AI instructions

**Dependencies to Resolve:**
- Supabase schema needs generalization
- UI components need theming/branding removal

### 2. Agent Catalog

**Source:** `apps/internal/agent-manager/src/app/workbench/(auth)/catalog/`

**Purpose:** Browse, configure, and manage available agents.

**Extraction Value:**
- Agent discovery and configuration UI
- Agent capability declarations
- Agent health monitoring

### 3. Session Viewer

**Source:** Agent session replay and inspection tools

**Purpose:** View, replay, and analyze agent sessions.

**Extraction Value:**
- Debugging and understanding agent behavior
- Session export/archival
- Token usage analysis

### 4. MOTD System

**Source:** `apps/internal/agent-manager/src/lib/motd/`

**Purpose:** Message of the day for agents - cross-agent announcements.

**Extraction Value:**
- Team-wide announcements
- Agent coordination messages
- System status broadcasts

### 5. Pulse Beat Dashboard

**Source:** `apps/internal/agent-manager/src/components/workbench/PulseBeatDashboard.tsx`

**Purpose:** Real-time metrics and health monitoring.

**Extraction Value:**
- Agency health at a glance
- Multi-source metric aggregation
- Information radiator pattern

## Extraction Principles

1. **Remove branding** - No ordinaryfolk/noah/zoey references
2. **Generalize schemas** - Abstract from specific business domain
3. **Preserve patterns** - Keep the underlying architectural patterns
4. **Document dependencies** - Clear list of required infrastructure

## Phased Approach

### Phase 1: Core Tools (Current)
- Shell scripts for agent coordination
- No UI required
- Works with any project

### Phase 2: Workbench (Included)
The Agency Starter will ship WITH the workbench components:
- **Staff Manager** - Team authentication and permissions
- **Agent Manager** - Configure and monitor agents
- **Content Manager** - Manage prompts and templates
- **Pulse Beat** - Real-time metrics dashboard
- **Catalog** - Browse available agents (TBD)

Workbench runs as a separate Next.js app that can be deployed alongside your project.

### Phase 3: Integrations
- Claude Desktop via MCP
- Claude in Chrome automation
- CI/CD templates

## Integration with Starter Packs

Each starter pack (next, react-native, swift, python) can optionally include workbench components:

```bash
# Install base Agency
./tools/create-project my-app --pack next

# Add optional workbench
./tools/add-workbench content-manager
./tools/add-workbench session-viewer
```

---

*Part of The Agency framework*
