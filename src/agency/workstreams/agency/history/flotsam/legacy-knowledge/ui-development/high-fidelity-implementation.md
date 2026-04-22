# High-Fidelity Implementation Patterns

Techniques for achieving pixel-perfect UI implementations that match designs exactly.

---

## The High-Fidelity Mindset

**High fidelity means:**
- ✅ Exact spacing (±2px tolerance maximum)
- ✅ Exact colors (no approximations)
- ✅ Exact typography (font, size, weight, line-height, letter-spacing)
- ✅ Exact border radii
- ✅ Exact shadows
- ✅ Smooth animations matching design intent

**High fidelity does NOT mean:**
- ❌ Identical DOM structure to Figma layers
- ❌ Using Figma auto-generated code (it's usually poor quality)
- ❌ Sacrificing accessibility for visual perfection
- ❌ Ignoring semantic HTML

---

## Typography Fidelity

### The Four Typography Dimensions

Every text element has four key properties:

1. **Font family** - e.g., "Inter", "SF Pro", "Roboto"
2. **Font size** - e.g., 16px, 1rem
3. **Font weight** - e.g., 400 (regular), 600 (semibold), 700 (bold)
4. **Line height** - e.g., 24px, 1.5

**Also important but often overlooked:**
5. **Letter spacing** - e.g., -0.02em, 0.05em
6. **Text transform** - e.g., uppercase, capitalize

### Extracting from Figma

**Figma shows:**
```
Inter
Semibold
18px
Line height: 28px
Letter spacing: -0.01em
```

**Translates to Tailwind:**
```jsx
<h2 className="font-sans font-semibold text-lg leading-7 tracking-tight">
  Heading Text
</h2>
```

**If not in Tailwind scale, extend config:**
```typescript
// tailwind.config.ts
theme: {
  extend: {
    fontSize: {
      'lg-custom': ['18px', { lineHeight: '28px', letterSpacing: '-0.01em' }]
    }
  }
}
```

### Line Height Gotcha

Figma sometimes shows line height as percentage or "Auto":
- **Auto** - typically 1.2 for headings, 1.5 for body text
- **Percentage** - e.g., 150% = line-height: 1.5
- **Fixed px** - e.g., 28px on 18px font = 1.556

**Always specify line-height explicitly** to avoid cross-browser differences.

### Typography System

Create consistent text styles:

```typescript
// components/ui/Typography.tsx
const typography = {
  h1: "font-sans font-bold text-5xl leading-tight tracking-tight",
  h2: "font-sans font-semibold text-4xl leading-snug tracking-tight",
  h3: "font-sans font-semibold text-2xl leading-normal",
  body: "font-sans font-normal text-base leading-relaxed",
  caption: "font-sans font-normal text-sm leading-normal text-text-secondary"
}
```

---

## Spacing Fidelity

### The Spacing Ladder

Most designs use a consistent spacing scale:
```
4px → 8px → 12px → 16px → 24px → 32px → 48px → 64px → 96px
```

**In Tailwind:**
```
1 → 2 → 3 → 4 → 6 → 8 → 12 → 16 → 24
```

### Reading Spacing from Figma

**Padding:**
- Figma shows: "16 / 24" (top-bottom / left-right)
- Tailwind: `py-4 px-6`

**Margin:**
- Figma shows: "32" (all sides)
- Tailwind: `m-8`

**Gap:**
- Figma shows: "12" (between items)
- Tailwind: `gap-3`

### When Spacing Doesn't Match Scale

If Figma shows 18px padding and Tailwind only has 16px (p-4) and 20px (p-5):

**Option 1: Use arbitrary value**
```jsx
<div className="p-[18px]">
```

**Option 2: Extend Tailwind config (preferred for repeated use)**
```typescript
theme: {
  extend: {
    spacing: {
      '18': '4.5rem' // 18px = 1.125rem
    }
  }
}
```

### Negative Space is Design

Pay as much attention to **space between elements** as the elements themselves.

**Check:**
- Padding inside containers
- Margins between sections
- Gap between grid/flex items
- Line spacing (leading)
- Letter spacing (tracking)

---

## Color Fidelity

### Exact Color Matching

**Extract exact hex codes from Figma:**
```
Primary: #FF6B35
Surface: #FFFFFF
Text: #1A1A1A
Text Secondary: #666666
Border: #E5E5E5
```

**Define as design tokens in Tailwind:**
```typescript
colors: {
  primary: {
    DEFAULT: '#FF6B35',
    dark: '#E55C2A',
    light: '#FF8557'
  },
  surface: '#FFFFFF',
  text: {
    DEFAULT: '#1A1A1A',
    secondary: '#666666',
    tertiary: '#999999'
  },
  border: {
    DEFAULT: '#E5E5E5',
    strong: '#CCCCCC'
  }
}
```

### Color Opacity

If Figma shows "Black 50% opacity":

**Method 1: Opacity utility**
```jsx
<div className="bg-black opacity-50">
```

**Method 2: Alpha channel in color**
```jsx
<div className="bg-black/50">
```

**Method 3: Define in config**
```typescript
colors: {
  'overlay': 'rgba(0, 0, 0, 0.5)'
}
```

### Gradients

**Linear gradient:**
```jsx
<div className="bg-gradient-to-r from-primary to-primary-dark">
```

**Complex gradient (Figma shows multiple stops):**
```jsx
<div style={{
  background: 'linear-gradient(135deg, #FF6B35 0%, #E55C2A 50%, #CC4E1F 100%)'
}}>
```

---

## Border Radius Fidelity

### Figma Border Radius to Tailwind

| Figma | Tailwind | px Value |
|-------|----------|----------|
| 2px | rounded-sm | 2px |
| 4px | rounded | 4px |
| 6px | rounded-md | 6px |
| 8px | rounded-lg | 8px |
| 12px | rounded-xl | 12px |
| 16px | rounded-2xl | 16px |

**For odd values (e.g., 10px):**
```jsx
<div className="rounded-[10px]">
```

### Per-Corner Radius

Figma can have different radii per corner:
```
Top-left: 12px
Top-right: 12px
Bottom-right: 0px
Bottom-left: 0px
```

**Tailwind:**
```jsx
<div className="rounded-t-xl rounded-b-none">
```

---

## Shadow Fidelity

### Reading Shadows from Figma

Figma effect panel shows:
```
Type: Drop Shadow
X: 0
Y: 4
Blur: 12
Spread: 0
Color: #000000 (10% opacity)
```

**Translate to CSS:**
```css
box-shadow: 0px 4px 12px 0px rgba(0, 0, 0, 0.1);
```

**Tailwind (if matches preset):**
```jsx
<div className="shadow-md">
```

**Custom shadow in Tailwind config:**
```typescript
boxShadow: {
  'card': '0px 4px 12px 0px rgba(0, 0, 0, 0.1)',
  'card-hover': '0px 8px 24px 0px rgba(0, 0, 0, 0.15)'
}
```

### Multiple Shadows

Figma can stack multiple shadows:
```
1. Drop shadow: 0 1px 2px rgba(0,0,0,0.05)
2. Drop shadow: 0 4px 12px rgba(0,0,0,0.1)
```

**CSS:**
```css
box-shadow:
  0 1px 2px rgba(0,0,0,0.05),
  0 4px 12px rgba(0,0,0,0.1);
```

---

## Layout Fidelity

### Flexbox vs Grid: Which to Use

**Use Flexbox when:**
- Single direction layout (row or column)
- Items should shrink/grow fluidly
- Content-driven sizing
- Simple alignment needs

**Use Grid when:**
- Two-dimensional layout
- Explicit rows and columns
- Overlapping elements
- Complex alignment needs

### Matching Figma Auto-Layout

**Figma Auto-Layout horizontal with 12px gap:**
```jsx
<div className="flex flex-row gap-3">
```

**Figma Auto-Layout vertical with 24px gap:**
```jsx
<div className="flex flex-col gap-6">
```

**Figma Auto-Layout with padding 16px all sides:**
```jsx
<div className="flex flex-col gap-6 p-4">
```

### Absolute Positioning

Sometimes Figma uses absolute positioning. In code, prefer **layout-based positioning** (flex, grid) over absolute when possible for maintainability.

**When you must use absolute:**
```jsx
<div className="relative">
  <div className="absolute top-4 right-4">
    {/* Badge or icon */}
  </div>
</div>
```

---

## Image Fidelity

### Object Fit

**Figma "Fill" mode:**
```jsx
<img className="object-cover w-full h-full" />
```

**Figma "Fit" mode:**
```jsx
<img className="object-contain w-full h-full" />
```

**Figma "Crop" (centered):**
```jsx
<img className="object-cover object-center w-full h-full" />
```

### Aspect Ratio

**Maintain specific aspect ratio:**
```jsx
<div className="aspect-w-16 aspect-h-9">
  <img src={src} alt={alt} className="object-cover" />
</div>
```

**Or with modern aspect-ratio:**
```jsx
<img className="aspect-video object-cover" />
```

### Image Optimization

Even with pixel-perfect implementation, images must be optimized:
- Use next/image for Next.js projects (automatic optimization)
- Provide srcset for responsive images
- Use WebP or AVIF when possible
- Lazy load below-the-fold images

---

## Animation & Transition Fidelity

### Reading Animation from Figma

Figma prototypes show:
```
Interaction: On click
Animation: Smart animate
Easing: Ease out
Duration: 300ms
```

**Translate to Tailwind:**
```jsx
<button className="transform transition-all duration-300 ease-out hover:scale-105">
```

### Common Easing Functions

| Figma | CSS | Tailwind |
|-------|-----|----------|
| Linear | linear | ease-linear |
| Ease in | ease-in | ease-in |
| Ease out | ease-out | ease-out |
| Ease in-out | ease-in-out | ease-in-out |

### Micro-Interactions

**Card lift on hover:**
```jsx
<div className="transition-all duration-300 hover:-translate-y-1 hover:shadow-lg">
```

**Button press:**
```jsx
<button className="transition-transform active:scale-95">
```

**Fade in on mount:**
```jsx
<div className="animate-fade-in">
  {/* Custom animation in Tailwind config */}
</div>
```

---

## Responsive Fidelity

### Breakpoint-Specific Designs

If Figma has separate mobile, tablet, desktop designs, implement each explicitly:

```jsx
<div className="
  grid grid-cols-1        /* Mobile: 1 column */
  md:grid-cols-2          /* Tablet: 2 columns */
  lg:grid-cols-3          /* Desktop: 3 columns */
  gap-4 md:gap-6 lg:gap-8 /* Increasing gap */
">
```

### Responsive Typography

```jsx
<h1 className="
  text-3xl leading-tight    /* Mobile */
  md:text-4xl md:leading-snug /* Tablet */
  lg:text-5xl lg:leading-tight /* Desktop */
">
```

### Responsive Spacing

```jsx
<section className="
  py-8 px-4      /* Mobile: tight spacing */
  md:py-12 md:px-6 /* Tablet: medium spacing */
  lg:py-16 lg:px-8 /* Desktop: generous spacing */
">
```

---

## Component-Specific Patterns

### Button Fidelity

```jsx
<button className="
  /* Size */
  h-11 px-6

  /* Typography */
  font-semibold text-base leading-none

  /* Colors */
  bg-primary text-white

  /* Borders */
  rounded-lg border-0

  /* States */
  hover:bg-primary-dark
  focus:outline-none focus:ring-2 focus:ring-primary focus:ring-offset-2
  active:scale-95
  disabled:opacity-50 disabled:cursor-not-allowed

  /* Transitions */
  transition-all duration-150
">
  Button Text
</button>
```

### Input Fidelity

```jsx
<input
  type="text"
  className="
    /* Size */
    h-12 w-full px-4

    /* Typography */
    text-base leading-normal

    /* Colors */
    bg-surface text-text placeholder:text-text-tertiary

    /* Borders */
    border border-border rounded-lg

    /* States */
    focus:outline-none focus:ring-2 focus:ring-primary focus:border-primary
    disabled:bg-gray-100 disabled:cursor-not-allowed

    /* Transitions */
    transition-colors duration-200
  "
  placeholder="Enter text..."
/>
```

### Card Fidelity

```jsx
<article className="
  /* Layout */
  p-6

  /* Colors */
  bg-surface

  /* Borders */
  border border-border rounded-xl

  /* Shadow */
  shadow-card

  /* Interactions */
  hover:shadow-card-hover hover:-translate-y-1
  transition-all duration-300
">
  {/* Card content */}
</article>
```

---

## Visual QA Process

### Layer-by-Layer Comparison

1. **Screenshot your implementation** at target viewport
2. **Export Figma mockup** at same viewport size
3. **Overlay images** (use design tool or browser dev tools)
4. **Toggle between them** to spot differences

### Measurement Verification

Use browser dev tools to measure:
- Open Inspector
- Hover over elements to see computed dimensions
- Compare to Figma measurements
- Adjust until exact match

### Color Picker Verification

Use color picker tool:
- Screenshot your implementation
- Use color picker on screenshot
- Compare hex code to Figma design
- If not matching, check CSS

---

## Common Fidelity Issues

| Issue | Symptom | Cause | Fix |
|-------|---------|-------|-----|
| Text too large/small | Size mismatch | Wrong font-size or line-height | Extract exact px values from Figma |
| Spacing off by few pixels | Slight misalignment | Wrong Tailwind spacing unit | Use exact px values or extend config |
| Colors slightly different | Visual difference | Approximate color used | Copy exact hex from Figma |
| Shadows too harsh/soft | Visual difference | Wrong blur or opacity | Match Figma shadow values exactly |
| Corners too round/sharp | Visual difference | Wrong border-radius | Extract exact radius from Figma |
| Font looks different | Weight or family wrong | Wrong font-weight or fallback font | Verify font loading and weight |

---

## The 90/10 Rule

**90% of the time:** Use Tailwind utilities for speed
**10% of the time:** Use arbitrary values or custom CSS for exactness

Don't over-optimize. If Tailwind's `p-4` (16px) is close enough to Figma's 15px and no one will notice, use `p-4`.

**Save precision for:**
- Hero sections (highly visible)
- Brand elements (logo, key graphics)
- Call-to-action buttons (critical interactions)
- Typography (affects readability significantly)

**Be pragmatic with:**
- Decorative elements
- Spacing deep in component hierarchy
- Non-critical micro-interactions

---

## Tools for Fidelity Verification

| Tool | Purpose | When to Use |
|------|---------|-------------|
| **Browser Dev Tools** | Measure computed styles | Checking spacing, colors, sizing |
| **Figma Dev Mode** | Extract exact values | Getting authoritative measurements |
| **PerfectPixel (Chrome ext)** | Overlay mockup on page | Pixel-perfect visual comparison |
| **ColorZilla (Chrome ext)** | Pick colors from page | Verify color accuracy |
| **WhatFont (Chrome ext)** | Identify fonts on page | Verify font family and weight |

---

## Checklist: High-Fidelity Review

For each component:

**Typography:**
- [ ] Correct font family
- [ ] Correct font size
- [ ] Correct font weight
- [ ] Correct line height
- [ ] Correct letter spacing
- [ ] Correct text color

**Spacing:**
- [ ] Correct padding (all sides)
- [ ] Correct margin (all sides)
- [ ] Correct gap between items
- [ ] Correct container max-width

**Colors:**
- [ ] Exact background color
- [ ] Exact text color
- [ ] Exact border color
- [ ] Correct opacity values

**Borders:**
- [ ] Correct border width
- [ ] Correct border radius (all corners)
- [ ] Correct border color

**Shadows:**
- [ ] Correct shadow offset (x, y)
- [ ] Correct shadow blur
- [ ] Correct shadow spread
- [ ] Correct shadow color and opacity

**Layout:**
- [ ] Correct alignment
- [ ] Correct distribution (flex/grid)
- [ ] Correct dimensions (width, height)

**States:**
- [ ] Hover state matches design
- [ ] Focus state matches design
- [ ] Active state matches design
- [ ] Disabled state matches design

**Responsive:**
- [ ] Correct behavior at each breakpoint
- [ ] No layout breaks
- [ ] Maintains visual hierarchy

---

**Related:**
- figma-workflow.md - End-to-end Figma process
- visual-qa-checklist.md - Comprehensive QA process
- tailwind-patterns.md - Reusable Tailwind patterns
