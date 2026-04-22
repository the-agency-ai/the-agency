# REQUEST-jordan-0036-housekeeping-project-handoff-mechanism

**Status:** Open - Deferred
**Priority:** Low
**Requested By:** agent:housekeeping (on behalf of jordan)
**Assigned To:** housekeeping
**Created:** 2026-01-11
**Updated:** 2026-01-11

## Summary

Project hand-off mechanism between Agency instances

## Details

Create a tool and mechanism to do a "hand-off" of a project or scope of work from one instance of The Agency to another. This would produce a document that acts as a seed or starter for that new Agency project.

## Requirements

### 1. Hand-off Document Generation
- Tool to generate a comprehensive hand-off document
- Captures current project state, context, and scope
- Acts as a "seed" for initializing a new Agency instance
- Example: `./tools/handoff create --scope=feature-x`

### 2. Hand-off Document Content
Should include:
- Project overview and goals
- Current state/progress
- Key decisions made and rationale
- Outstanding work items (REQUESTs, bugs)
- Important context and constraints
- Relevant file paths and structures
- Dependencies and environment requirements
- Principal information and preferences

### 3. Hand-off Import
- Tool to import a hand-off document into a new Agency
- Initializes the new Agency with the context
- Creates appropriate REQUESTs/work items
- Example: `./tools/handoff import handoff-doc.md`

### 4. Scope Selection
- Hand-off a full project vs specific scope of work
- Support for partial hand-offs (just one workstream, one feature)
- Example: `./tools/handoff create --workstream=web`

### 5. Use Cases
- Transitioning a project to a new developer
- Splitting a large project into multiple Agencies
- Creating a "snapshot" for onboarding new team members
- Disaster recovery / project recreation

## Deliverables
- [ ] `./tools/handoff create` - generate hand-off document
- [ ] `./tools/handoff import` - import hand-off into new Agency
- [ ] Hand-off document template/format specification
- [ ] Documentation for hand-off process

## Acceptance Criteria

- [ ] Can generate a hand-off document from current project
- [ ] Can import a hand-off document to bootstrap a new Agency
- [ ] Hand-off document is human-readable and editable
- [ ] Supports both full-project and scoped hand-offs
- [ ] New Agency can continue work without losing context

## Notes

This is important for:
- Team transitions
- Project scaling (one Agency becomes many)
- Backup and recovery
- Knowledge transfer

---

## Activity Log

### 2026-01-20 - Deferred
- Reviewed with principal jordan
- Valid feature but not urgent - more relevant when multiple users need project handoffs
- Keeping open at low priority for when demand emerges

### 2026-01-11 - Created
- Request created by agent:housekeeping (on behalf of jordan)
