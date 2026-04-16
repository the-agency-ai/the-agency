# Responsive Design Patterns

Strategies and patterns for building interfaces that work beautifully across all device sizes.

---

## Core Principles

### 1. Mobile-First Approach

Always start with the mobile layout, then enhance for larger screens.

**Why:**
- Forces prioritization of content
- Easier to add than remove
- Better performance on mobile
- Progressive enhancement philosophy

**How:**
```jsx
// Base styles = mobile (no prefix)
<div className="p-4 text-base">

  // Tablet and up (md: prefix)
  <div className="md:p-6 md:text-lg">

    // Desktop and up (lg: prefix)
    <div className="lg:p-8 lg:text-xl">
      Content
    </div>
  </div>
</div>
```

### 2. Content-First Design

Let content dictate breakpoints, not devices.

**Bad:** "We need layouts for iPhone, iPad, and desktop"
**Good:** "The design breaks at 640px and 1024px based on content flow"

### 3. Fluid by Default

Use flexible units (%, rem, vh/vw) over fixed pixels where appropriate.

**Fixed (use sparingly):**
```jsx
<div className="w-[320px]"> // Only when exact size needed
```

**Fluid (prefer):**
```jsx
<div className="w-full max-w-7xl mx-auto"> // Adapts to container
```

---

## Breakpoint System

### Standard Tailwind Breakpoints

| Prefix | Min Width | Device | Typical Use |
|--------|-----------|--------|-------------|
| (none) | 0px | Mobile | Base styles |
| `sm:` | 640px | Large mobile | Landscape phones |
| `md:` | 768px | Tablet | iPads, tablets |
| `lg:` | 1024px | Desktop | Laptops |
| `xl:` | 1280px | Large desktop | Desktop monitors |
| `2xl:` | 1536px | Extra large | Wide monitors |

### Common Breakpoint Usage

**Content width progression:**
```jsx
<div className="
  w-full          /* Mobile: full width */
  sm:w-full       /* Large mobile: still full */
  md:w-3/4        /* Tablet: 75% width */
  lg:w-2/3        /* Desktop: 66% width */
  xl:max-w-6xl    /* Large: capped at 1152px */
">
```

**Column progression:**
```jsx
<div className="
  grid
  grid-cols-1     /* Mobile: 1 column */
  sm:grid-cols-2  /* Large mobile: 2 columns */
  md:grid-cols-3  /* Tablet: 3 columns */
  lg:grid-cols-4  /* Desktop: 4 columns */
  gap-4 md:gap-6 lg:gap-8
">
```

---

## Layout Patterns

### Pattern 1: Stacked → Side-by-Side

**Mobile:** Vertical stack
**Desktop:** Horizontal layout

```jsx
<div className="
  flex
  flex-col       /* Mobile: vertical */
  lg:flex-row    /* Desktop: horizontal */
  gap-6
">
  <div className="lg:w-2/3">Main content</div>
  <div className="lg:w-1/3">Sidebar</div>
</div>
```

### Pattern 2: Single Column → Multi-Column Grid

```jsx
<div className="
  grid
  grid-cols-1           /* Mobile */
  md:grid-cols-2        /* Tablet */
  lg:grid-cols-3        /* Desktop */
  gap-4 md:gap-6
">
  {items.map(item => <Card key={item.id} {...item} />)}
</div>
```

### Pattern 3: Centered Content with Max Width

```jsx
<section className="
  w-full
  max-w-7xl             /* Limit width on large screens */
  mx-auto               /* Center horizontally */
  px-4 md:px-6 lg:px-8  /* Responsive padding */
">
  {/* Content always centered, never too wide */}
</section>
```

### Pattern 4: Hamburger Menu → Horizontal Nav

```jsx
// Mobile: Hamburger menu
// Desktop: Horizontal navigation

<nav>
  {/* Mobile menu button */}
  <button className="md:hidden" onClick={toggleMenu}>
    <MenuIcon />
  </button>

  {/* Mobile menu (full screen overlay) */}
  <div className={`
    fixed inset-0 bg-white z-50
    ${isOpen ? 'block' : 'hidden'}
    md:hidden
  `}>
    {/* Mobile nav items */}
  </div>

  {/* Desktop menu (always visible) */}
  <ul className="hidden md:flex md:gap-6">
    <li><a href="/about">About</a></li>
    <li><a href="/contact">Contact</a></li>
  </ul>
</nav>
```

### Pattern 5: Image Above Text → Image Beside Text

```jsx
<article className="
  flex flex-col         /* Mobile: image on top */
  md:flex-row           /* Desktop: image beside text */
  gap-6
">
  <img
    src={imageSrc}
    alt={alt}
    className="
      w-full                 /* Mobile: full width */
      md:w-1/3               /* Desktop: 1/3 width */
      object-cover
      rounded-lg
    "
  />
  <div className="md:w-2/3">
    <h2>Title</h2>
    <p>Description...</p>
  </div>
</article>
```

---

## Typography Scaling

### Responsive Font Sizes

Scale typography based on viewport:

```jsx
<h1 className="
  text-2xl leading-tight       /* Mobile: 24px */
  sm:text-3xl sm:leading-tight /* Large mobile: 30px */
  md:text-4xl md:leading-snug  /* Tablet: 36px */
  lg:text-5xl lg:leading-tight /* Desktop: 48px */
  xl:text-6xl xl:leading-none  /* Large: 60px */
">
  Headline
</h1>

<p className="
  text-sm leading-normal       /* Mobile: 14px */
  md:text-base md:leading-relaxed  /* Tablet: 16px */
  lg:text-lg lg:leading-relaxed    /* Desktop: 18px */
">
  Body text
</p>
```

### Responsive Line Height

Adjust line height for readability at different sizes:

```jsx
<p className="
  text-base
  leading-normal       /* Mobile: tighter (1.5) */
  md:leading-relaxed   /* Desktop: looser (1.625) for readability */
">
```

### Responsive Letter Spacing

```jsx
<h1 className="
  tracking-tight       /* Mobile: tight */
  lg:tracking-tighter  /* Desktop: even tighter for large text */
">
```

---

## Spacing Patterns

### Responsive Padding

```jsx
<section className="
  py-8 px-4          /* Mobile: tight */
  md:py-12 md:px-6   /* Tablet: medium */
  lg:py-16 lg:px-8   /* Desktop: generous */
  xl:py-20           /* Large: extra generous vertical */
">
```

### Responsive Gaps

```jsx
<div className="
  flex flex-col
  gap-4              /* Mobile: tight */
  md:gap-6           /* Tablet: medium */
  lg:gap-8           /* Desktop: generous */
">
```

### Responsive Margins

```jsx
<h2 className="
  mb-4               /* Mobile */
  md:mb-6            /* Tablet */
  lg:mb-8            /* Desktop */
">
```

---

## Component-Specific Patterns

### Responsive Cards

```jsx
<div className="
  bg-white rounded-lg shadow-md
  p-4 md:p-6              /* More padding on larger screens */
  space-y-3 md:space-y-4  /* More space between items */
">
  <img className="
    w-full
    h-48 md:h-64          /* Taller images on tablet/desktop */
    object-cover rounded
  " />
  <h3 className="
    text-lg md:text-xl    /* Larger heading on tablet/desktop */
  ">
    Card Title
  </h3>
  <p className="
    text-sm md:text-base  /* Larger body text on tablet/desktop */
  ">
    Card description
  </p>
</div>
```

### Responsive Buttons

```jsx
<button className="
  w-full md:w-auto      /* Full width on mobile, auto on desktop */
  px-4 py-2 md:px-6 md:py-3  /* Larger on desktop */
  text-sm md:text-base  /* Readable text size */
  rounded-lg
  bg-primary text-white
">
  Call to Action
</button>
```

### Responsive Forms

```jsx
<form className="
  space-y-4 md:space-y-6
">
  <input className="
    w-full
    h-12 md:h-14          /* Taller on desktop */
    px-4
    text-base
    border rounded-lg
  " />

  <div className="
    flex flex-col md:flex-row
    gap-4
  ">
    <input className="w-full" type="text" placeholder="First name" />
    <input className="w-full" type="text" placeholder="Last name" />
  </div>

  <button className="
    w-full md:w-auto
    px-6 py-3
    bg-primary text-white rounded-lg
  ">
    Submit
  </button>
</form>
```

---

## Image Responsive Patterns

### Responsive Images with srcset

```jsx
<img
  src="/image-800.jpg"
  srcSet="
    /image-400.jpg 400w,
    /image-800.jpg 800w,
    /image-1200.jpg 1200w
  "
  sizes="
    (max-width: 640px) 400px,
    (max-width: 1024px) 800px,
    1200px
  "
  alt="Description"
  className="w-full h-auto"
/>
```

### Next.js Image Responsive

```jsx
import Image from 'next/image';

<Image
  src="/image.jpg"
  alt="Description"
  width={1200}
  height={800}
  sizes="(max-width: 640px) 100vw, (max-width: 1024px) 80vw, 1200px"
  className="rounded-lg"
/>
```

### Background Images (Responsive)

```jsx
<div className="
  bg-cover bg-center
  h-64 md:h-96 lg:h-[500px]  /* Responsive height */
  rounded-lg
" style={{
  backgroundImage: `url(${imageSrc})`
}}>
```

### Art Direction (Different Images)

```jsx
<picture>
  <source
    media="(min-width: 1024px)"
    srcSet="/hero-desktop.jpg"
  />
  <source
    media="(min-width: 640px)"
    srcSet="/hero-tablet.jpg"
  />
  <img
    src="/hero-mobile.jpg"
    alt="Hero"
    className="w-full h-auto"
  />
</picture>
```

---

## Container Queries (Modern Approach)

Instead of viewport-based responsive (media queries), use container-based (container queries).

**Setup:**
```jsx
<div className="@container">
  <div className="
    grid
    @sm:grid-cols-2     /* When container is > 640px */
    @lg:grid-cols-3     /* When container is > 1024px */
    gap-4
  ">
    {/* Content responds to container width, not viewport */}
  </div>
</div>
```

**When to use:**
- Reusable components that appear in different container sizes
- Sidebars vs main content areas
- Card layouts in variable-width containers

---

## Testing Responsive Designs

### Browser DevTools

```
1. Open DevTools
2. Click device toolbar icon (Cmd+Shift+M)
3. Select device or enter custom dimensions
4. Test at each breakpoint:
   - 375px (iPhone SE)
   - 640px (sm breakpoint)
   - 768px (md breakpoint, iPad portrait)
   - 1024px (lg breakpoint, iPad landscape)
   - 1280px (xl breakpoint)
   - 1440px (common desktop)
```

### Real Device Testing

**Minimum devices to test:**
- iPhone (small screen)
- iPad (tablet)
- Android phone (touch behavior)
- Laptop (common desktop size)

### Responsive Testing Checklist

For each breakpoint:
- [ ] Layout looks intentional (not broken)
- [ ] Text is readable (not too small)
- [ ] Touch targets adequate (44x44px minimum on mobile)
- [ ] No horizontal scroll
- [ ] Images scale appropriately
- [ ] Navigation works (hamburger on mobile, etc.)
- [ ] Forms are usable
- [ ] Buttons accessible
- [ ] No content cut off

---

## Common Responsive Issues

### Issue: Content Overflows

**Symptom:** Horizontal scrollbar on mobile
**Cause:** Fixed width element wider than viewport
**Fix:** Use `max-w-full` or `w-full` instead of fixed width

```jsx
// ❌ Bad
<div className="w-[800px]">

// ✅ Good
<div className="w-full max-w-[800px]">
```

### Issue: Text Too Small on Mobile

**Symptom:** Text unreadable on small screens
**Cause:** Same font size on all screens
**Fix:** Use responsive font sizes

```jsx
// ❌ Bad
<p className="text-xs">

// ✅ Good
<p className="text-sm md:text-base">
```

### Issue: Touch Targets Too Small

**Symptom:** Hard to tap buttons/links on mobile
**Cause:** Small padding/size
**Fix:** Minimum 44x44px touch target

```jsx
// ❌ Bad
<button className="px-2 py-1 text-xs">

// ✅ Good
<button className="px-4 py-3 text-base">
```

### Issue: Images Not Scaling

**Symptom:** Images overflow container or look stretched
**Cause:** Missing width/height constraints
**Fix:** Add responsive image classes

```jsx
// ❌ Bad
<img src={src} alt={alt} />

// ✅ Good
<img src={src} alt={alt} className="w-full h-auto object-cover" />
```

### Issue: Layout Breaks at Specific Width

**Symptom:** Design looks good at breakpoints but breaks in between
**Cause:** Content doesn't fit in between breakpoint sizes
**Fix:** Test at intermediate sizes, add custom breakpoint if needed

```typescript
// tailwind.config.ts
theme: {
  extend: {
    screens: {
      '2md': '896px', // Custom breakpoint between md and lg
    }
  }
}
```

---

## Responsive Utilities Reference

### Display

```jsx
<div className="
  block md:hidden        /* Show on mobile, hide on tablet+ */
  hidden md:block        /* Hide on mobile, show on tablet+ */
  hidden lg:flex         /* Hide until desktop, then flex */
">
```

### Flexbox Direction

```jsx
<div className="
  flex
  flex-col md:flex-row   /* Vertical on mobile, horizontal on tablet+ */
">
```

### Grid Columns

```jsx
<div className="
  grid
  grid-cols-1 sm:grid-cols-2 md:grid-cols-3 lg:grid-cols-4
">
```

### Width

```jsx
<div className="
  w-full md:w-3/4 lg:w-1/2  /* Full width mobile, narrower on larger screens */
">
```

### Padding

```jsx
<div className="
  p-4 md:p-6 lg:p-8         /* Increasing padding */
">
```

### Text Alignment

```jsx
<p className="
  text-center md:text-left  /* Center on mobile, left on tablet+ */
">
```

---

## Advanced Patterns

### Responsive Aspect Ratios

```jsx
<div className="
  aspect-square           /* Mobile: square */
  md:aspect-video         /* Tablet+: 16:9 */
">
  <img src={src} alt={alt} className="w-full h-full object-cover" />
</div>
```

### Responsive Z-Index

```jsx
<div className="
  z-10                    /* Mobile: normal z-index */
  md:z-20                 /* Tablet+: higher z-index */
">
```

### Responsive Position

```jsx
<div className="
  relative md:absolute    /* Relative on mobile, absolute on tablet+ */
  top-0 md:top-4
">
```

### Responsive Overflow

```jsx
<div className="
  overflow-scroll         /* Mobile: scroll */
  md:overflow-visible     /* Tablet+: no scroll */
">
```

---

## Performance Considerations

### Lazy Load Images Below Fold

```jsx
<img
  src={src}
  alt={alt}
  loading="lazy"          /* Browser native lazy loading */
  className="w-full h-auto"
/>
```

### Responsive Image Loading

```jsx
// Next.js optimizes this automatically
<Image
  src={src}
  alt={alt}
  sizes="(max-width: 640px) 100vw, (max-width: 1024px) 50vw, 33vw"
  priority={false}        /* Don't load eagerly */
/>
```

### Reduce Motion (Accessibility)

```jsx
<div className="
  transition-transform duration-300
  motion-reduce:transition-none  /* Disable animation for users who prefer reduced motion */
">
```

---

## Checklist: Responsive Implementation

- [ ] Mobile design implemented first
- [ ] Tested at all standard breakpoints (375, 640, 768, 1024, 1280, 1440)
- [ ] Tested at in-between sizes
- [ ] No horizontal scroll at any width
- [ ] Text readable at all sizes (min 14px)
- [ ] Touch targets adequate on mobile (44x44px)
- [ ] Images scale appropriately
- [ ] Forms usable on mobile
- [ ] Navigation works at all sizes
- [ ] Content hierarchy maintained
- [ ] Performance acceptable on mobile network

---

**Related:**
- figma-workflow.md - Getting responsive specs from Figma
- high-fidelity-implementation.md - Pixel-perfect at each breakpoint
- visual-qa-checklist.md - Testing responsive behavior
