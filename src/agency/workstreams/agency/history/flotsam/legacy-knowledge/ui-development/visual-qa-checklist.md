# Visual QA Checklist

Comprehensive quality assurance process for UI implementations.

---

## Overview

Visual QA ensures that implementations match designs with high fidelity across all devices, states, and edge cases. This checklist should be completed before marking any UI work as complete.

---

## Pre-QA Setup

### 1. Prepare Reference Materials

- [ ] Figma mockups exported at target resolutions
- [ ] Design specifications documented (typography, colors, spacing)
- [ ] Interaction states defined (hover, focus, active, disabled)
- [ ] Responsive behavior specified for all breakpoints
- [ ] Edge cases identified (long text, empty states, errors)

### 2. Set Up Testing Environment

- [ ] Development server running
- [ ] Browser dev tools open
- [ ] Reference mockups accessible
- [ ] Screenshot tool ready (`./tools/browser screenshot`)
- [ ] Test devices/emulators ready

---

## Level 1: Visual Fidelity

### Typography Check

For each text element:

- [ ] **Font family** matches Figma exactly
- [ ] **Font size** matches Figma exactly
- [ ] **Font weight** matches Figma exactly
- [ ] **Line height** matches Figma exactly
- [ ] **Letter spacing** matches Figma (if specified)
- [ ] **Text color** matches Figma (exact hex)
- [ ] **Text alignment** matches Figma
- [ ] Text is readable at all sizes
- [ ] No text overflow or truncation (unless designed)

**How to verify:**
```bash
# Screenshot at each breakpoint
./tools/browser screenshot "http://localhost:3000" --viewport=375x667
./tools/browser screenshot "http://localhost:3000" --viewport=768x1024
./tools/browser screenshot "http://localhost:3000" --viewport=1440x900
```

### Color Check

For each colored element:

- [ ] **Background colors** exact hex match
- [ ] **Text colors** exact hex match
- [ ] **Border colors** exact hex match
- [ ] **Icon colors** exact hex match
- [ ] **Opacity values** correct
- [ ] **Gradients** match (direction, stops, colors)
- [ ] Colors are consistent across similar components
- [ ] No color banding or rendering artifacts

**How to verify:**
- Use ColorZilla or similar tool to sample colors
- Compare sampled hex to Figma design tokens
- Check in multiple browsers

### Spacing Check

For each component:

- [ ] **Padding** (top, right, bottom, left) matches
- [ ] **Margin** (top, right, bottom, left) matches
- [ ] **Gap** between flex/grid items matches
- [ ] Container **max-width** matches
- [ ] **Alignment** matches (left, center, right, justified)
- [ ] **Vertical rhythm** consistent throughout page
- [ ] No unexpected whitespace
- [ ] No elements touching when they shouldn't be

**How to verify:**
```
1. Open browser dev tools
2. Inspect element
3. Check computed padding/margin values
4. Compare to Figma measurements
```

### Border & Radius Check

For each element with borders:

- [ ] **Border width** matches
- [ ] **Border style** matches (solid, dashed, etc.)
- [ ] **Border color** matches (exact hex)
- [ ] **Border radius** matches all corners
- [ ] Borders render cleanly (no anti-aliasing issues)

### Shadow Check

For each shadowed element:

- [ ] **Shadow offset** (x, y) matches
- [ ] **Shadow blur** matches
- [ ] **Shadow spread** matches
- [ ] **Shadow color and opacity** match
- [ ] Multiple shadows layer correctly (if applicable)
- [ ] Shadows render smoothly across browsers

### Image & Icon Check

For all images and icons:

- [ ] **Aspect ratio** maintained
- [ ] **Object fit** behavior correct (cover, contain, fill)
- [ ] **Image quality** appropriate (not pixelated)
- [ ] **Icon size** matches design
- [ ] **Icon color** matches design
- [ ] Images load correctly
- [ ] Alt text present and descriptive
- [ ] No layout shift when images load (CLS)

---

## Level 2: Layout & Structure

### Responsive Behavior

Test at each breakpoint: **375px, 768px, 1024px, 1440px**

For each breakpoint:

- [ ] Layout matches Figma design for that breakpoint
- [ ] No horizontal scrollbar
- [ ] No content overflow
- [ ] Appropriate column count (1, 2, 3, etc.)
- [ ] Text reflows correctly
- [ ] Images scale appropriately
- [ ] Navigation adapts correctly (hamburger on mobile, etc.)
- [ ] Touch targets adequate on mobile (min 44x44px)

**Test in-between breakpoints:**
- [ ] Smooth scaling between 375px and 768px
- [ ] Smooth scaling between 768px and 1024px
- [ ] Smooth scaling between 1024px and 1440px
- [ ] No awkward "snap" points

### Grid & Flexbox

- [ ] Grid columns correct at each breakpoint
- [ ] Grid gaps consistent
- [ ] Flex items align correctly
- [ ] Flex items don't grow/shrink unexpectedly
- [ ] Justify and align properties correct
- [ ] No orphaned items
- [ ] Wrapping behavior correct

### Positioning & Z-Index

- [ ] Elements layer correctly
- [ ] No unexpected overlaps
- [ ] Sticky elements stick at correct scroll position
- [ ] Fixed elements stay fixed
- [ ] Absolute positioned elements in correct spot
- [ ] Dropdowns/modals appear above other content

---

## Level 3: Interaction States

### Hover States

For every interactive element:

- [ ] Hover effect present
- [ ] Hover effect matches design
- [ ] Transition smooth (correct duration & easing)
- [ ] Cursor changes appropriately (pointer for clickable)
- [ ] No hover on touch devices (graceful degradation)

### Focus States

For every focusable element:

- [ ] Focus ring/outline visible
- [ ] Focus ring matches design (or accessibility standards)
- [ ] Focus order logical (tab through page)
- [ ] Focus not obscured by sticky headers
- [ ] Skip links present for keyboard users

### Active/Pressed States

For every interactive element:

- [ ] Active state visual feedback present
- [ ] Active state matches design
- [ ] Feels responsive (immediate feedback)

### Disabled States

For elements that can be disabled:

- [ ] Disabled appearance matches design
- [ ] Cursor shows not-allowed
- [ ] Element not focusable when disabled
- [ ] Disabled state has sufficient contrast (accessibility)

### Loading States

For async operations:

- [ ] Loading indicator present
- [ ] Loading indicator styled correctly
- [ ] Content doesn't shift when loading completes
- [ ] Loading doesn't block other interactions (if appropriate)

### Error States

For form inputs and error scenarios:

- [ ] Error styling matches design
- [ ] Error messages clear and helpful
- [ ] Error icon/indicator present
- [ ] Focus automatically on error (if appropriate)

### Empty States

For lists/grids that can be empty:

- [ ] Empty state designed and implemented
- [ ] Empty state message helpful
- [ ] Call-to-action present in empty state

---

## Level 4: Animation & Transitions

### Transition Smoothness

For all animated elements:

- [ ] Transition duration matches design (or feels natural)
- [ ] Easing function correct (ease-in, ease-out, etc.)
- [ ] No janky animations (60fps)
- [ ] Animations don't cause layout shift
- [ ] Animations respect prefers-reduced-motion

### Micro-Interactions

- [ ] Button press feedback present
- [ ] Card lift on hover smooth
- [ ] Menu open/close smooth
- [ ] Modal fade in/out smooth
- [ ] Tooltip appears with delay (not instant)
- [ ] Page transitions smooth (if applicable)

### Loading Animations

- [ ] Skeleton screens or spinners present
- [ ] Loading animations loop smoothly
- [ ] Loading doesn't feel too fast or too slow

---

## Level 5: Cross-Browser Testing

Test in: **Chrome, Firefox, Safari, Edge** (minimum)

For each browser:

- [ ] Layout renders correctly
- [ ] Colors render correctly
- [ ] Fonts render correctly (no missing web fonts)
- [ ] Animations work
- [ ] Interactions work
- [ ] No console errors
- [ ] Performance acceptable

### Mobile Browser Testing

Test on actual devices or emulators:

- [ ] **iOS Safari** (iPhone, iPad)
- [ ] **Android Chrome** (phone, tablet)
- [ ] Touch interactions work
- [ ] Viewport meta tag correct (no pinch zoom issues)
- [ ] No text too small to read
- [ ] No tap targets too small

---

## Level 6: Accessibility

### Semantic HTML

- [ ] Proper heading hierarchy (h1 → h2 → h3, no skipping)
- [ ] Buttons are `<button>` not `<div onclick>`
- [ ] Links are `<a>` with href
- [ ] Form inputs have associated `<label>`
- [ ] Lists use `<ul>/<ol>/<li>`
- [ ] Regions have proper landmarks (header, nav, main, footer)

### ARIA

- [ ] ARIA labels present where needed
- [ ] ARIA roles appropriate
- [ ] ARIA expanded/pressed states toggle correctly
- [ ] ARIA live regions announce changes

### Keyboard Navigation

- [ ] Can tab to all interactive elements
- [ ] Tab order logical
- [ ] Can activate elements with Enter/Space
- [ ] Can close modals with Escape
- [ ] Can use arrow keys in menus/lists
- [ ] Focus visible at all times

### Screen Reader Testing

Test with **VoiceOver (Mac)** or **NVDA (Windows)**:

- [ ] All content announced correctly
- [ ] Interactive elements labeled clearly
- [ ] Images have appropriate alt text
- [ ] Form errors announced
- [ ] Dynamic content changes announced

### Color Contrast

Use WebAIM Contrast Checker:

- [ ] Normal text: 4.5:1 minimum (WCAG AA)
- [ ] Large text (18pt+): 3:1 minimum (WCAG AA)
- [ ] UI components: 3:1 minimum
- [ ] Disabled text has appropriate contrast
- [ ] Links distinguishable from text (not just by color)

---

## Level 7: Performance

### Load Performance

- [ ] First Contentful Paint < 1.8s
- [ ] Largest Contentful Paint < 2.5s
- [ ] Time to Interactive < 3.8s
- [ ] No layout shifts (CLS < 0.1)
- [ ] Images lazy loaded below fold
- [ ] Fonts don't cause FOIT (Flash of Invisible Text)

### Runtime Performance

- [ ] Smooth scrolling (no jank)
- [ ] Animations hit 60fps
- [ ] No memory leaks (long sessions work fine)
- [ ] Interactions feel instant (< 100ms)

### Bundle Size

- [ ] JavaScript bundle size reasonable
- [ ] CSS bundle size reasonable
- [ ] Images optimized (WebP, AVIF)
- [ ] Unused code removed (tree shaking)

---

## Level 8: Edge Cases

### Long Content

- [ ] Long names/titles don't break layout
- [ ] Long paragraphs wrap correctly
- [ ] Long lists scroll correctly
- [ ] Truncation with ellipsis where appropriate

### Short Content

- [ ] One-word headings don't look awkward
- [ ] Empty or short cards don't collapse
- [ ] Single-item lists render correctly

### Extreme Viewports

- [ ] Works on very small screens (320px width)
- [ ] Works on very large screens (2560px+ width)
- [ ] Works on portrait and landscape
- [ ] Works on very short viewport height

### Data Edge Cases

- [ ] Handles missing data gracefully
- [ ] Handles null/undefined values
- [ ] Handles very large numbers
- [ ] Handles special characters in text
- [ ] Handles emojis correctly

---

## QA Sign-Off

### Pre-Deployment Checklist

- [ ] All Level 1-8 checks completed
- [ ] All critical issues fixed
- [ ] All medium issues fixed or documented
- [ ] Low issues documented for future iteration
- [ ] Visual regression tests pass (if set up)
- [ ] Lighthouse score > 90 (or documented exceptions)
- [ ] Accessibility audit pass (aXe, Lighthouse)
- [ ] Code review completed
- [ ] Design review completed

### Documentation

- [ ] Known issues documented
- [ ] Browser support documented
- [ ] Accessibility features documented
- [ ] Performance baseline recorded

---

## Issue Severity Levels

**Critical (Must fix before deploy):**
- Layout completely broken
- Content not accessible
- Functional interaction broken
- Major accessibility violation (WCAG A)

**Medium (Should fix before deploy):**
- Visual fidelity significantly off (>5px)
- Minor layout issues
- Missing hover/focus states
- Accessibility enhancement needed (WCAG AA)

**Low (Can defer to next iteration):**
- Visual fidelity slightly off (2-5px)
- Missing micro-interactions
- Nice-to-have accessibility features (WCAG AAA)
- Performance optimization opportunities

---

## Testing Frequency

### Every Commit

- [ ] Visual spot check at primary breakpoint
- [ ] Functional testing of changed components
- [ ] No console errors

### Before PR/Merge

- [ ] Full responsive testing (all breakpoints)
- [ ] Cross-browser testing (Chrome, Firefox, Safari)
- [ ] Accessibility spot check (keyboard nav, screen reader)

### Before Deploy

- [ ] Complete QA checklist (all levels)
- [ ] Lighthouse audit
- [ ] Full accessibility audit
- [ ] Performance baseline check

---

## Tools Reference

| Tool | Purpose | Usage |
|------|---------|-------|
| **Browser Dev Tools** | Inspect, measure, debug | Always open during QA |
| **./tools/browser screenshot** | Capture implementation | Compare to mockups |
| **Lighthouse** | Performance, A11y, SEO audit | Run before deploy |
| **aXe DevTools** | Accessibility testing | Find A11y issues |
| **ColorZilla** | Sample colors from page | Verify color accuracy |
| **WhatFont** | Identify fonts | Verify typography |
| **PerfectPixel** | Overlay mockup on implementation | Pixel-perfect comparison |
| **Responsive Design Mode** | Test breakpoints | Check responsive behavior |
| **VoiceOver / NVDA** | Screen reader testing | Test for blind users |

---

## QA Workflow Example

```bash
# 1. Start local dev server
cd source/apps/my-app
npm run dev

# 2. Open in browser
open http://localhost:3000

# 3. Run through checklist with dev tools open
# - Check typography
# - Check spacing
# - Check colors
# - Test responsive
# - Test interactions

# 4. Screenshot at each breakpoint
./tools/browser screenshot "http://localhost:3000" --viewport=375x667
./tools/browser screenshot "http://localhost:3000" --viewport=768x1024
./tools/browser screenshot "http://localhost:3000" --viewport=1440x900

# 5. Compare screenshots to Figma mockups

# 6. Run Lighthouse audit
npx lighthouse http://localhost:3000 --view

# 7. Run accessibility audit
# (Use aXe DevTools in browser)

# 8. Document any issues

# 9. Fix issues and repeat
```

---

## Common QA Failures

| Issue | How to Catch | How to Fix |
|-------|--------------|------------|
| Font not loading | Check Network tab for 404s | Verify font file path, add font-display |
| Wrong spacing | Measure with dev tools | Adjust Tailwind classes or custom values |
| Missing hover state | Hover over every interactive element | Add hover: utilities |
| Layout break on mobile | Test at 375px width | Adjust grid/flex at mobile breakpoint |
| Poor contrast | Run Lighthouse accessibility | Adjust color values |
| Keyboard trap | Tab through entire page | Fix focus management |
| Content overflow | Test with long text | Add truncation or scrolling |

---

## Continuous Improvement

After each QA cycle:

1. **Note patterns** - Which issues recur?
2. **Update checklist** - Add new edge cases discovered
3. **Improve process** - Automate checks where possible
4. **Share learnings** - Document in KNOWLEDGE base
5. **Refine standards** - Raise the bar over time

---

**Related:**
- figma-workflow.md - Design handoff process
- high-fidelity-implementation.md - Implementation techniques
- responsive-design.md - Multi-device patterns
