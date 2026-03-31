# {{AGENT_NAME}} Knowledge

## Imported Knowledge Bases

- [UI Development](../../../knowledge/ui-development/INDEX.md) - Implementation patterns
- [Design Systems](../../../knowledge/design-systems/INDEX.md) - Design tokens and specs

## Visual Fidelity Standards

### Target Metrics
- **Pixel match:** 95%+ against design
- **Color accuracy:** Exact hex values from design system
- **Spacing:** Within 2px of spec
- **Typography:** Exact font sizes, weights, line heights

### Verification Process
1. Implement component/page
2. Screenshot at specified viewports
3. Compare against mockup (visual or tool-assisted)
4. Iterate until 95%+ match

## Design System Integration

### Always
1. Reference active design system for project
2. Use exact token values from Tailwind config
3. Report gaps via GAPS.md in design system
4. Update GAP-RESOLUTION.md when gaps are filled

### Never
- Hardcode colors (use tokens: `bg-primary`, `text-secondary`)
- Hardcode spacing (use tokens: `p-4`, `gap-6`)
- Guess at missing values (document in GAPS.md)

## Responsive Patterns

### Breakpoints (Tailwind defaults)
- `sm`: 640px
- `md`: 768px
- `lg`: 1024px
- `xl`: 1280px
- `2xl`: 1536px

### Mobile-First Approach
1. Start with mobile layout (base styles)
2. Add tablet breakpoint (`md:`)
3. Add desktop breakpoint (`lg:`)
4. Test at each breakpoint

## Common Patterns

### Layout
- Flexbox for 1D layouts
- Grid for 2D layouts
- Container with max-width for content

### Spacing
- Consistent padding on cards
- Gap utilities for flex/grid children
- Margin for section separation

### Typography
- Heading hierarchy (h1 > h2 > h3)
- Body text with proper line-height
- Caption text for secondary info

## Troubleshooting

### Colors Don't Match
1. Check design system colors.md for exact hex
2. Verify Tailwind config has correct value
3. Check for opacity modifiers

### Spacing Off
1. Check design system spacing.md
2. Verify rem vs px (Tailwind uses rem)
3. Account for line-height in text spacing

### Fonts Wrong
1. Check font is loaded (network tab)
2. Verify font-family in Tailwind config
3. Check for fallback font differences
