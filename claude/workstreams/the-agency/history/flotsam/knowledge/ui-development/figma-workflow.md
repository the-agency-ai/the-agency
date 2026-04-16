# Figma Workflow for Agents

How to effectively translate Figma designs into high-fidelity code.

---

## Phase 1: Understand the Design

### Before Writing Any Code

1. **Inspect the Figma file structure**
   - Look for reusable components
   - Identify the grid system
   - Note auto-layout usage
   - Check for consistent naming

2. **Extract design tokens**
   - Colors (with semantic names: primary, surface, text, border)
   - Typography (font families, sizes, weights, line-heights)
   - Spacing scale (4px, 8px, 12px, 16px, 24px, etc.)
   - Border radii (for buttons, cards, inputs)
   - Shadows (elevation levels)

3. **Identify breakpoints**
   - Mobile: typically 375px base
   - Tablet: typically 768px
   - Desktop: typically 1024px or 1280px
   - Wide: typically 1440px or 1920px

### Request Structured Specs

If you only have screenshots, request:
```markdown
## [Screen Name] Specification

### Layout
- Grid system: [columns, gutters, max-width]
- Container padding: [mobile / tablet / desktop]
- Section spacing: [vertical rhythm]

### Typography
- H1: [font, size, weight, line-height, letter-spacing]
- H2: [font, size, weight, line-height, letter-spacing]
- Body: [font, size, weight, line-height]
- Caption: [font, size, weight, line-height]

### Colors
- Primary: [hex] (token: --color-primary)
- Surface: [hex] (token: --color-surface)
- Text: [hex] (token: --color-text)
- Border: [hex] (token: --color-border)

### Components
- Button primary: [height, padding, radius, font-size]
- Button secondary: [height, padding, radius, font-size]
- Input field: [height, padding, radius, border]
- Card: [padding, radius, shadow]

### Interactions
- [Component]: [hover/focus/active behavior]
```

---

## Phase 2: Structure the Implementation

### Create Semantic HTML First

**Do this:**
```html
<header role="banner" class="site-header">
  <nav role="navigation" aria-label="Main navigation">
    <a href="/" aria-label="Home">Logo</a>
    <ul>
      <li><a href="/about">About</a></li>
      <li><a href="/contact">Contact</a></li>
    </ul>
  </nav>
</header>
```

**Not this:**
```html
<div class="header">
  <div class="nav">
    <div class="logo">Logo</div>
    <div class="links">
      <div class="link">About</div>
      <div class="link">Contact</div>
    </div>
  </div>
</div>
```

### Component Hierarchy

Break the design into logical components:

```
Page
├── Header
│   ├── Logo
│   ├── Navigation
│   └── CTAButton
├── Hero
│   ├── Headline
│   ├── Subheadline
│   └── HeroImage
├── Features
│   ├── FeatureCard
│   ├── FeatureCard
│   └── FeatureCard
└── Footer
    ├── FooterLinks
    └── Copyright
```

### Identify Reusable Components

**Look for:**
- Buttons (primary, secondary, ghost)
- Form inputs (text, email, textarea)
- Cards (with consistent padding/radius/shadow)
- Icons (system)
- Typography components (heading levels, body text, captions)

**Create once, reuse everywhere.**

---

## Phase 3: Implement Styling

### Mobile-First Approach

Always start with mobile, then enhance for larger screens.

**Tailwind example:**
```jsx
// Mobile base (applies to all screens)
<div className="p-4 space-y-6">

  // Tablet and up
  <div className="md:p-6 md:space-y-8">

    // Desktop and up
    <div className="lg:p-8 lg:space-y-12">
      {/* Content */}
    </div>
  </div>
</div>
```

### Match Exact Measurements

Use Figma Dev Mode (or specs) to get exact values:

**From Figma:**
- Padding: 24px
- Border radius: 12px
- Font size: 18px
- Line height: 28px

**In Tailwind:**
```jsx
<button className="px-6 py-3 rounded-xl text-lg leading-7">
  Click me
</button>
```

**If exact value not in Tailwind scale:**
```jsx
// Add to tailwind.config.ts
theme: {
  extend: {
    spacing: {
      '18': '4.5rem', // 72px
    },
    borderRadius: {
      'xl2': '0.875rem', // 14px
    }
  }
}
```

### Design Tokens in Tailwind Config

**Don't use magic hex values in code:**
```jsx
// ❌ Bad
<div className="bg-[#FF6B35] text-[#1A1A1A]">
```

**Use semantic tokens:**
```jsx
// ✅ Good
<div className="bg-primary text-text">
```

**Define in tailwind.config.ts:**
```typescript
theme: {
  extend: {
    colors: {
      primary: '#FF6B35',
      surface: '#FFFFFF',
      text: '#1A1A1A',
      'text-secondary': '#666666',
      border: '#E5E5E5',
      'border-strong': '#CCCCCC',
    }
  }
}
```

---

## Phase 4: Handle Responsive Behavior

### Layout Shifts

Understand how the design changes between breakpoints:

| Element | Mobile | Tablet | Desktop |
|---------|--------|--------|---------|
| Grid | 1 column | 2 columns | 3 columns |
| Navigation | Hamburger menu | Horizontal | Horizontal + CTA |
| Images | Stack | Side-by-side | Side-by-side |
| Text alignment | Center | Left | Left |

### Implement Container Queries (when applicable)

For component-based responsive design:

```jsx
<div className="@container">
  <div className="@lg:grid @lg:grid-cols-2">
    {/* Responds to container width, not viewport */}
  </div>
</div>
```

### Test at Real Breakpoints

Don't just resize browser arbitrarily. Test at:
- 375px (iPhone SE, small phones)
- 768px (iPad portrait, tablets)
- 1024px (iPad landscape, small laptops)
- 1280px (common laptop)
- 1440px (large desktop)

---

## Phase 5: Implement Interaction States

### Every Interactive Element Needs:

1. **Default state** (resting)
2. **Hover state** (mouse over)
3. **Focus state** (keyboard navigation)
4. **Active state** (clicking/pressing)
5. **Disabled state** (not interactive)

**Example button:**
```jsx
<button
  className="
    px-6 py-3 rounded-lg
    bg-primary text-white
    hover:bg-primary-dark
    focus:outline-none focus:ring-2 focus:ring-primary focus:ring-offset-2
    active:scale-95
    disabled:opacity-50 disabled:cursor-not-allowed
    transition-all duration-150
  "
>
  Click me
</button>
```

### Micro-Interactions

Common patterns from Figma:
- **Cards on hover:** Lift (translateY) + increase shadow
- **Buttons on hover:** Darken color + scale slightly
- **Links on hover:** Underline + color change
- **Images on hover:** Scale up slightly (zoom effect)

**Implementation:**
```jsx
<div className="
  transform transition-all duration-300
  hover:-translate-y-1 hover:shadow-lg
">
  {/* Card content */}
</div>
```

---

## Phase 6: Visual QA

### Side-by-Side Comparison

1. Export PNG from Figma at target viewport size
2. Screenshot your implementation at same viewport
3. Overlay the two images
4. Note discrepancies

**Use:**
```bash
./tools/browser screenshot "http://localhost:3000"
```

### Pixel-Perfect Checklist

For each component:
- [ ] Correct spacing (margin, padding)
- [ ] Correct sizing (width, height)
- [ ] Correct typography (font, size, weight, line-height)
- [ ] Correct colors (exact hex match)
- [ ] Correct border radius
- [ ] Correct shadows
- [ ] Correct alignment
- [ ] Correct responsive behavior

### Common Discrepancies

| Issue | Likely Cause | Fix |
|-------|--------------|-----|
| Text too small/large | Wrong font-size or line-height | Check Figma Dev Mode for exact values |
| Spacing off | Wrong Tailwind spacing unit | Use exact px values or extend Tailwind config |
| Colors don't match | Using approximate color | Copy exact hex from Figma |
| Alignment wrong | Wrong flexbox/grid settings | Check Figma auto-layout settings |
| Responsive breaks | Wrong breakpoint | Verify breakpoint values in design |

---

## Common Patterns

### Pattern: Sticky Header

```jsx
<header className="sticky top-0 z-50 bg-white/80 backdrop-blur-md">
  {/* Header content */}
</header>
```

### Pattern: Full-Height Hero

```jsx
<section className="min-h-screen flex items-center justify-center">
  {/* Hero content */}
</section>
```

### Pattern: Card Grid

```jsx
<div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
  {cards.map(card => <Card key={card.id} {...card} />)}
</div>
```

### Pattern: Centered Container

```jsx
<div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
  {/* Content */}
</div>
```

### Pattern: Aspect Ratio Images

```jsx
<div className="aspect-w-16 aspect-h-9">
  <img src={src} alt={alt} className="object-cover" />
</div>
```

---

## When to Ask for Help

### Ask the designer/principal if:
- Design specs are missing or unclear
- Responsive behavior is not defined
- Interaction states are not designed
- Accessibility requirements are ambiguous
- Edge cases are not covered (long text, empty states, errors)

### Collaborate with other agents if:
- Architectural decisions needed (component structure)
- Performance concerns (image optimization, lazy loading)
- Accessibility review needed (screen reader testing)
- Visual regression testing setup (automated screenshots)

### Use visual diff tools if:
- Subtle spacing/alignment issues
- Color matching difficulties
- Cross-browser rendering differences

---

## Tools Reference

| Tool | Purpose | Usage |
|------|---------|-------|
| `./tools/browser screenshot` | Capture webpage | Compare implementation to design |
| `./tools/figma-extract` | Extract Figma data | Get design tokens automatically |
| `./tools/figma-diff` | Visual comparison | Overlay implementation on mockup |

---

## Anti-Patterns to Avoid

### ❌ Guessing Measurements
```jsx
// Bad: arbitrary values
<div className="pt-7 pb-9 px-11">
```

### ❌ Inline Styles
```jsx
// Bad: not using design system
<div style={{ color: '#FF6B35', padding: '24px' }}>
```

### ❌ Desktop-Only Implementation
```jsx
// Bad: only works on desktop
<div className="grid grid-cols-3">
```

### ❌ Divitis
```jsx
// Bad: unnecessary wrapper divs
<div>
  <div>
    <div>
      <p>Hello</p>
    </div>
  </div>
</div>
```

### ❌ Missing Accessibility
```jsx
// Bad: no semantic HTML or ARIA
<div onClick={handleClick}>Click me</div>
```

---

## Checklist: Starting a Figma Implementation

- [ ] Reviewed Figma file structure
- [ ] Extracted design tokens (colors, typography, spacing)
- [ ] Identified breakpoints and responsive behavior
- [ ] Noted all interaction states
- [ ] Listed reusable components
- [ ] Created semantic HTML structure
- [ ] Implemented mobile-first styles
- [ ] Tested at all breakpoints
- [ ] Verified all interaction states
- [ ] Compared visually to mockup
- [ ] Accessibility check passed
- [ ] Code review completed

---

**Related:**
- high-fidelity-implementation.md - Pixel-perfect patterns
- responsive-design.md - Multi-device strategies
- visual-qa-checklist.md - Quality assurance process
