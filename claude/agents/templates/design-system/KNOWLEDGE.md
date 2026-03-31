# {{AGENT_NAME}} Knowledge

## Primary Knowledge Base

- [Design Systems](../../knowledge/design-systems/INDEX.md) - Design token documentation
- [Extraction Guide](../../knowledge/design-systems/_template/EXTRACTION-GUIDE.md) - Workflow best practices
- [UI Development](../../knowledge/ui-development/INDEX.md) - Implementation patterns

---

## Extraction Workflow

### Phase 1: API Extraction

```bash
# Store Figma token (one-time)
./claude/tools/secret create figma-token --type=api_key --service=Figma

# Extract from Figma file
./claude/tools/figma-extract <file-key> --name=<brand> --version=001
```

**What you get:**
- Unique hex colors (exact values)
- Font families with usage counts
- Template files for organizing

### Phase 2: PDF Enhancement

Ask designer to export documentation pages from Figma:
- Colors/palette page → `source/colors.pdf`
- Typography page → `source/typography.pdf`
- Component specs → `source/components.pdf`

**Read and enhance:**
```
Read source/colors.pdf and update colors.md with:
- Token names for each color
- Organization into categories
- Usage guidelines
```

### Phase 3: Merge & Validate

- Match PDF token names to API hex values
- Generate Tailwind config with final tokens
- Run `./claude/tools/designsystem-validate`

---

## Color Extraction Checklist

- [ ] Extract colors via API (exact hex)
- [ ] Read color PDF (token names, organization)
- [ ] Match hex values to token names
- [ ] Organize: Neutrals, Brand, Semantic
- [ ] Add usage guidelines (text, background, border, state)
- [ ] Generate Tailwind color config
- [ ] Verify no placeholder values remain

## Typography Extraction Checklist

- [ ] Extract fonts via API (families, counts)
- [ ] Read typography PDF (full specs)
- [ ] Document each style:
  - [ ] Name (H1, Body 1, Button, etc.)
  - [ ] Font family
  - [ ] Font weight
  - [ ] Font size
  - [ ] Line height
  - [ ] Letter spacing
  - [ ] Text transform
- [ ] Generate Tailwind fontSize config
- [ ] Note font file locations/loading

## Spacing Extraction Checklist

- [ ] Check PDF for spacing scale
- [ ] If not documented, infer from components
- [ ] Standard scales: 4, 8, 12, 16, 24, 32, 48, 64
- [ ] Document usage (padding, margin, gap)

---

## Standard File Structure

```
claude/knowledge/design-systems/<brand>-<version>/
├── INDEX.md              # Overview, quick reference
├── colors.md             # Color palette with tokens
├── typography.md         # Text styles with specs
├── spacing.md            # Spacing scale
├── effects.md            # Shadows, borders, radii
├── assets.md             # Logos, icons, images
├── tailwind-config.md    # Ready-to-use config
├── GAPS.md               # Missing information
├── GAP-RESOLUTION.md     # How to resolve gaps
└── source/
    ├── figma-file.json   # Raw API data
    ├── figma-styles.json # Published styles
    ├── colors.json       # Extracted colors
    ├── colors.pdf        # Designer documentation
    └── typography.pdf    # Designer documentation
```

---

## Common Patterns

### Color Token Naming

```
Neutrals:
  of-black-{900|800|700|600}
  of-grey-{900|800|700|600|500|400|300|200}
  off-white

Brand:
  {color}-{900|700|600|500|400|300|200|100}

Semantic:
  primary, secondary
  success, warning, error, info
```

### Typography Scale

```
Headers:     H1 (34px) → H6 (14px)
Body:        Body 1 (18px) → Body 5 (10px)
UI:          Button, Label, Caption, Table
```

### Tailwind Mappings

```typescript
// Colors
colors: {
  'of-black': { 900: '#1A1A1A', ... },
  'brand': { primary: '#3182CE', ... },
}

// Typography
fontSize: {
  'heading-1': ['34px', { lineHeight: 'auto', fontWeight: '400' }],
  'body-1': ['18px', { lineHeight: '24px', fontWeight: '400' }],
}
```

---

## Quality Gates

Before marking extraction complete:

1. **No placeholders** - All `[TODO]` and `???` resolved
2. **Hex validation** - All colors are valid `#RRGGBB` format
3. **Font availability** - Font files exist or fallbacks documented
4. **Config validity** - Tailwind config is valid TypeScript
5. **Gap resolution** - No critical gaps in GAPS.md
