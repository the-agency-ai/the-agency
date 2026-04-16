# Design Systems Knowledge Base

**Purpose:** Store and manage design system documentation for UI implementation.

**Location:** `claude/knowledge/design-systems/`

---

## Overview

Design systems provide the tokens, patterns, and specifications needed for high-fidelity UI implementation. Each design system is versioned and project-specific.

## Directory Structure

```
claude/knowledge/design-systems/
├── INDEX.md                    # This file
├── _template/                  # Template for new design systems
│   ├── INDEX.md
│   ├── GAPS.md
│   ├── GAP-RESOLUTION.md
│   ├── colors.md
│   ├── typography.md
│   ├── spacing.md
│   ├── effects.md
│   ├── assets.md
│   ├── tailwind-config.md
│   └── source/                 # For original exports
└── [brand-version]/            # Project-specific systems
    └── ...
```

## Quick Start

### Create a New Design System

```bash
./tools/designsystem-add <brand-name> <version>

# Example:
./tools/designsystem-add acme 001
# Creates: claude/knowledge/design-systems/acme-001/
```

### Validate a Design System

```bash
./tools/designsystem-validate <path>

# Example:
./tools/designsystem-validate claude/knowledge/design-systems/acme-001
```

## Design System Contents

Each design system contains:

| File | Purpose | Required |
|------|---------|----------|
| `INDEX.md` | Overview and quick reference | Yes |
| `GAPS.md` | Missing/unclear information | Yes |
| `GAP-RESOLUTION.md` | How to fill gaps | Yes |
| `colors.md` | Color palette with tokens | Yes |
| `typography.md` | Font family and text styles | Yes |
| `spacing.md` | Spacing scale (padding, margin) | Yes |
| `effects.md` | Shadows, borders, effects | Optional |
| `assets.md` | SVGs, logos, images | Optional |
| `tailwind-config.md` | Ready-to-use Tailwind theme | Yes |
| `source/` | Original Figma exports, PDFs | Optional |

## Naming Convention

```
{brand-name}-{version}
```

Examples:
- `acme-001` - First version for Acme project
- `acme-002` - Updated version
- `ordinaryfolk-001` - Ordinary Folk design system v1

## Workflow

### 1. Export from Figma

Export design tokens from Figma:
- Colors as JSON/CSS (exact hex values)
- Typography specs
- Spacing scale
- Component specifications
- Asset exports (SVG, PNG)

Save exports to `source/` directory.

### 2. Create Design System

```bash
./tools/designsystem-add mybrand 001
```

### 3. Fill in Templates

Work through each template file:
1. `colors.md` - Add color tokens
2. `typography.md` - Add text styles
3. `spacing.md` - Add spacing scale
4. `effects.md` - Add shadows/effects
5. `tailwind-config.md` - Generate Tailwind theme

### 4. Track Gaps

Document unknowns in `GAPS.md`:
- Missing hex values
- Unclear specifications
- Assumptions made

### 5. Validate

```bash
./tools/designsystem-validate claude/knowledge/design-systems/mybrand-001
```

### 6. Implement

Reference the design system during UI implementation:
- Use tokens from `tailwind-config.md`
- Follow patterns from `typography.md`
- Check `GAPS.md` for known limitations

## Best Practices

1. **Never guess hex values** - If not available, mark as gap
2. **Version everything** - Create new version for major changes
3. **Track assumptions** - Document in GAPS.md
4. **Keep source files** - Store original exports in source/
5. **Validate before using** - Run validation tool

## Related Resources

- `claude/knowledge/ui-development/` - Implementation patterns
- `ART-jordan-0002` - Figma-to-code strategy document

---

**Last Updated:** 2026-01-13
**Maintainer:** housekeeping agent
