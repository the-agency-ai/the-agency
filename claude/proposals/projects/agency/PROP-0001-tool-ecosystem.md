# PROP-0001: Tool Ecosystem (dist vs local)

**Status:** draft
**Priority:** high
**Created:** 2026-01-06
**Author:** jordan + housekeeping
**Project:** agency

## Problem

Currently all tools live in `tools/`. When The Agency ships updates, we risk:
1. Overwriting user customizations
2. Users not knowing which tools are "theirs" vs framework
3. No clear path to upstream local tools back to The Agency

## Proposal

Separate framework tools from local/project tools following Unix FHS pattern.

### Directory Structure

```
tools/              # Framework distribution (upstream from The Agency)
tools/local/        # Project-specific tools (local customizations)
```

### Behavior

1. **Search order:** `tools/local/` before `tools/` (like PATH searches /usr/local/bin before /usr/bin)
2. **Updates:** The Agency only touches `tools/`, never `tools/local/`
3. **Registration:** Both directories register in TOOLS.yaml (or separate registries)
4. **Discovery:** TheCaptain's `how` command searches both

### Tool Registration

```yaml
# tools/TOOLS.yaml (framework tools)
- name: pre-commit-check
  purpose: "Run quality gates before commit"
  usage: "./tools/pre-commit-check"

# tools/local/TOOLS.yaml (local tools)
- name: my-custom-tool
  purpose: "Project-specific automation"
  usage: "./tools/local/my-custom-tool"
  upstream_candidate: true  # Flag for potential contribution
```

### New Tools

```bash
./tools/create-tool mytool              # Creates in tools/local/
./tools/create-tool mytool --framework  # Creates in tools/ (maintainers only)
./tools/upstream-tool mytool            # Proposes moving local → framework
```

## Key Points

- Clean separation: framework vs local
- Safe updates: never clobber local tools
- Clear contribution path: local → upstream
- TheCaptain knows about all tools

## Open Questions

- [ ] Should `tools/local/` be created by default in starter?
- [ ] How does TOOLS.yaml merge work? Two files or one with sections?
- [ ] Should local tools have a different naming convention?

## Dependencies

- Related proposals: PROP-0006 (Distribution Structure)
- Related INSTRs: none yet

## When Approved

- Becomes: INSTR-XXXX
- Assigned to: housekeeping
- Target: v0.2.0

---

## Discussion Log

### 2026-01-06 - Created
Initial proposal from pre-dawn ideas session. Captured in WORKING-NOTE-0015.
