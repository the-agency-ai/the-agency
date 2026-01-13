# {{AGENT_NAME}} Onboarding

## Quick Start

1. Launch the agent:
   ```bash
   ./tools/myclaude {{WORKSTREAM}} {{AGENT_NAME}}
   ```

2. Familiarize with knowledge bases:
   - Read `claude/knowledge/ui-development/INDEX.md`
   - Review active design systems in `claude/knowledge/design-systems/`

3. Check available design systems:
   ```bash
   ls claude/knowledge/design-systems/
   ```

## Typical Workflow

### 1. Receive Design Task
- Design system path (e.g., `design-systems/acme-001/`)
- Mockup references (PNG/PDF exports)
- Target viewports (mobile, tablet, desktop)

### 2. Review Design System
```bash
./tools/designsystem-validate claude/knowledge/design-systems/acme-001
```

### 3. Implement Component
- Reference colors.md for color tokens
- Reference typography.md for text styles
- Reference spacing.md for spacing scale
- Use tailwind-config.md for exact values

### 4. Visual Verification
- Screenshot at specified viewports
- Compare against mockup
- Document any gaps in GAPS.md

### 5. Handoff
- Run visual QA checklist
- Request accessibility review if needed
- Create PR with design comparison notes

## Key Commands

```bash
# Validate design system
./tools/designsystem-validate <path>

# Create new design system
./tools/designsystem-add <brand> <version>

# Visual capture (when available)
./tools/browser screenshot <url> --viewport=1440x900

# Request collaboration
./tools/collaborate <workstream> <agent> "message"
```

## Resources

- [UI Development Knowledge](../../../knowledge/ui-development/INDEX.md)
- [Design Systems](../../../knowledge/design-systems/INDEX.md)
- [Visual QA Checklist](../../../knowledge/ui-development/visual-qa-checklist.md)
- [Tailwind Patterns](../../../knowledge/ui-development/tailwind-patterns.md)

## Getting Help

```bash
./tools/collaborate housekeeping housekeeping "I need help with UI implementation"
```
