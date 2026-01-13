# Figma to High-Fidelity Code Strategy

**Artifact ID:** ART-jordan-0002
**Created:** 2026-01-13
**Principal:** Jordan
**Agent:** housekeeping
**Status:** Draft

## Executive Summary

This document outlines a comprehensive strategy for translating Figma mockups into high-fidelity user experiences within The Agency's multi-agent development framework. The strategy emphasizes **structured input over raw screenshots**, **tool-assisted initial conversion**, and **iterative refinement through specialized agents**.

## Core Principles

### 1. Structured Input Beats Raw Screenshots

When Claude only receives screenshots, it must infer:
- Layout grids and spacing systems
- Typography scales and font stacks
- Color systems and design tokens
- Component hierarchy and relationships
- Responsive breakpoints and behavior

**Solution:** Provide both visual mockups AND structured specifications.

### 2. Tool-Assisted First Pass + Claude Refinement

Rather than asking Claude to go from pixels to production code in one step:
1. Use Figma-to-code tools to generate structured initial output
2. Pass that to Claude for cleanup, optimization, and alignment with project standards

### 3. Multi-Agent Specialization

Different aspects of implementation benefit from specialized agent focus:
- **Structural agents** - Semantic HTML, accessibility, component architecture
- **Styling agents** - CSS/Tailwind implementation, responsive design, visual fidelity
- **Testing agents** - Visual regression, responsive behavior, interaction states

## The Agency Tech Stack Context

Current primary stack for web applications:
- **Next.js 15** - React framework
- **React 19** - UI library
- **Tailwind CSS** - Utility-first styling
- **TypeScript** - Type safety
- **Tauri** - Desktop app wrapper (where applicable)

This informs our tooling and workflow choices.

## Recommended Workflow

### Phase 1: Preparation & Export

**Actor:** Designer / Principal
**Tools:** Figma, Figma Dev Mode

**Steps:**
1. **Clean the Figma file**
   - Consistent auto-layout usage
   - Clear, semantic naming conventions
   - Reusable components for common patterns
   - Defined text styles and color styles
   - Proper constraints and responsive behavior rules

2. **Export visual assets**
   - Per-screen high-resolution PNG exports (2x or 3x)
   - Named clearly: `home-desktop-1440px.png`, `home-mobile-375px.png`
   - Save to principal's cloud storage: `claude/principals/jordan/resources/cloud/figma-exports/[project]/`

3. **Extract structured specifications**
   - Create companion markdown files for each screen
   - Format: `home-desktop-spec.md`, `home-mobile-spec.md`

   **Template:**
   ```markdown
   # [Screen Name] - [Viewport]

   ## Layout
   - Grid: 12-column, 24px gutters
   - Max width: 1200px
   - Breakpoints: 375px (mobile), 768px (tablet), 1024px (desktop), 1440px (wide)
   - Container padding: 16px mobile, 24px tablet, 32px desktop

   ## Typography
   - Heading 1: Inter Bold, 48px/56px, tracking -0.02em
   - Heading 2: Inter Semibold, 32px/40px
   - Body: Inter Regular, 16px/24px
   - Caption: Inter Regular, 14px/20px

   ## Colors
   - Primary: #FF6B35 (design token: --color-primary)
   - Surface: #FFFFFF (--color-surface)
   - Text: #1A1A1A (--color-text)
   - Border subtle: #E5E5E5 (--color-border-subtle)

   ## Components
   - Header: Fixed position, 72px height, blur backdrop
   - CTA Button: 44px height, 12px border radius, 16px horizontal padding
   - Card: 16px padding, 8px border radius, subtle shadow

   ## Interactions
   - Sticky header on scroll
   - Cards hover: lift 4px, increase shadow
   - Buttons hover: darken 10%
   ```

### Phase 2: Initial Code Generation

**Actor:** Specialized agent or Figma plugin
**Tools:** Figma plugins (Convert Figma to HTML/CSS, Anima, etc.) OR Claude with structured input

**Option A: Figma Plugin Route**
1. Use a Figma Community plugin like "Convert Figma Design to HTML/CSS"
2. Export HTML/CSS or React components
3. Save to project directory: `source/apps/[project]/figma-export/`
4. This provides structural skeleton with layer hierarchy intact

**Option B: Claude with Structured Input Route**
1. Create an INSTRUCTION for a UI implementation agent
2. Attach both the PNG mockup AND the spec markdown
3. Prompt pattern:
   ```
   You are implementing [Screen Name] for The Agency [Project].

   Stack: Next.js 15, React 19, Tailwind CSS, TypeScript

   Attached:
   - Visual mockup: home-desktop-1440px.png
   - Structured spec: home-desktop-spec.md

   Task:
   1. First, output semantic HTML structure only (no styling)
   2. Then, implement Tailwind classes section by section
   3. Finally, create responsive variants per the spec breakpoints

   Requirements:
   - Mobile-first approach (min-width media queries)
   - Use existing design tokens from tailwind.config.ts
   - Match spacing and typography exactly per spec
   - Accessibility: semantic HTML, ARIA labels, keyboard navigation
   ```

### Phase 3: Multi-Agent Refinement

**Actors:** Specialized agents (ui-dev, architect, accessibility-specialist)
**Tools:** The Agency collaboration tools, browser screenshots for validation

**Iteration Cycle:**

1. **Structure Review**
   - Agent: `architect` or `ui-dev`
   - Focus: Semantic HTML, component architecture, data flow
   - Output: Structural improvements, component extraction recommendations

2. **Visual Fidelity Review**
   - Agent: `ui-dev`
   - Tools: `./tools/browser screenshot` for side-by-side comparison
   - Method:
     - Deploy to local dev server
     - Screenshot actual implementation
     - Compare pixel-by-pixel with Figma export
     - Document discrepancies: spacing, colors, typography, sizing
   - Output: List of specific style adjustments

3. **Responsive Behavior Review**
   - Agent: `ui-dev`
   - Test at each breakpoint: 375px, 768px, 1024px, 1440px
   - Verify: layout shifts, text reflow, image scaling, component reordering
   - Output: Responsive fixes

4. **Interaction & State Review**
   - Agent: `ui-dev` or `interaction-specialist`
   - Test: Hover states, focus states, active states, disabled states
   - Verify: Transitions, animations, micro-interactions
   - Output: Interaction polish

5. **Accessibility Review**
   - Agent: `accessibility-specialist`
   - Verify: Keyboard navigation, screen reader support, color contrast, focus indicators
   - Output: A11y improvements

### Phase 4: Integration & Testing

**Actor:** Integration agent
**Focus:** Connect to real data, handle edge cases, performance

1. Replace mock data with API calls
2. Handle loading states, error states, empty states
3. Add analytics/tracking if needed
4. Performance optimization (lazy loading, code splitting)
5. Cross-browser testing

### Phase 5: Visual Regression Protection

**Actor:** Test automation agent
**Tools:** Playwright + visual regression tools

1. Capture baseline screenshots at key breakpoints
2. Set up visual regression tests in CI/CD
3. Any design changes trigger visual diff review

## Tooling Gaps & Proposals

### Gap 1: Figma API Integration

**Current State:** Manual export from Figma
**Desired State:** Direct Figma file inspection via API

**Proposal:** Create `./tools/figma-extract`
- Uses Figma REST API to fetch file data
- Extracts design tokens (colors, typography, spacing)
- Generates spec markdown automatically
- Optionally exports assets

**Implementation Path:**
- Requires Figma Personal Access Token (store in Secret Service)
- Use Figma REST API: `GET /v1/files/:file_key`
- Parse nodes to extract styles and layout info
- Output structured spec files

### Gap 2: Visual Comparison Tool

**Current State:** Manual side-by-side comparison
**Desired State:** Automated visual diff with overlay

**Proposal:** Create `./tools/figma-diff`
- Takes Figma export PNG + deployed URL
- Screenshots deployed version at same viewport
- Generates overlay showing differences
- Highlights spacing, color, and typography variances

**Implementation Path:**
- Extend `./tools/browser` with comparison mode
- Use image diff libraries (pixelmatch, resemblejs)
- Output annotated diff images to cloud storage

### Gap 3: Design Token Sync

**Current State:** Manual translation of Figma styles to Tailwind config
**Desired State:** Automated sync of design tokens

**Proposal:** Create `./tools/figma-tokens`
- Extracts color styles, text styles, effects from Figma
- Generates `design-tokens.json`
- Updates `tailwind.config.ts` automatically
- Maintains sync between Figma source of truth and code

**Implementation Path:**
- Use Figma API to fetch styles
- Transform to Tailwind theme format
- Generate TypeScript types for tokens
- Provide CLI to sync on demand

### Gap 4: Agent Specialization

**Current State:** General-purpose agents
**Desired State:** UI/UX specialist agents

**Proposal:** Create dedicated UI agents
- `ui-dev` - Visual implementation specialist
- `responsive-specialist` - Multi-device optimization
- `accessibility-specialist` - WCAG compliance
- `animation-specialist` - Motion design implementation

**Implementation Path:**
- Create agent definitions in `claude/agents/`
- Provide specialized KNOWLEDGE.md with patterns
- Define collaboration handoff protocols

## Mobile Web Specific Considerations

When implementing for mobile web:

1. **Hard Viewport Constraints**
   - Always specify exact base width in prompts (e.g., "375px base design")
   - Test on real devices, not just browser DevTools
   - Account for mobile browser chrome (URL bar, bottom nav)

2. **Touch Interactions**
   - Minimum touch target: 44x44px
   - Generous spacing between interactive elements
   - No hover states (progressive enhancement only)
   - Handle touch gestures explicitly

3. **Performance**
   - Lazy load images below the fold
   - Optimize for 3G connections
   - Minimize layout shifts (CLS)
   - Test on mid-range Android devices

4. **Sticky Elements**
   - Call out explicitly in specs: "Header sticky on scroll"
   - Account for mobile browser behavior (expanding/collapsing URL bars)
   - Test scroll behavior thoroughly

## Recommended Agent Workflow Example

**Scenario:** Implement landing page from Figma mockup

```bash
# 1. Principal prepares exports
# Saves to: claude/principals/jordan/resources/cloud/figma-exports/landing-page/

# 2. Principal creates REQUEST
./tools/create-request "Implement landing page from Figma mockup"
# Creates: claude/principals/jordan/requests/REQUEST-jordan-0042-landing-page.md

# 3. Housekeeping creates specialized agent
./tools/create-agent ui-dev --workstream=web

# 4. Launch ui-dev agent with context
./tools/myclaude web ui-dev

# 5. Agent workflow (ui-dev perspective):
#    a. Read the REQUEST
#    b. Locate Figma exports in cloud storage
#    c. Create TodoWrite list:
#       - Extract layout structure
#       - Implement desktop version
#       - Implement tablet responsive
#       - Implement mobile responsive
#       - Review visual fidelity
#       - Accessibility check
#    d. Implement step by step
#    e. Use ./tools/browser screenshot to verify
#    f. Collaborate with architect for review
#    g. Mark REQUEST as complete

# 6. Review workflow
./tools/collaborate architect "Review landing page structure" --ref=REQUEST-jordan-0042
./tools/collaborate accessibility-specialist "A11y audit landing page" --ref=REQUEST-jordan-0042

# 7. Principal reviews deployed version
# Provides feedback in REQUEST file

# 8. ui-dev iterates based on feedback

# 9. Tag and release
./tools/tag REQUEST-jordan-0042 complete
./tools/release 0.8.0
```

## Prompt Patterns That Work

### Pattern 1: Structure-First Approach

```
You are implementing [Component] for The Agency.

Phase 1: Semantic Structure
- Output HTML with semantic elements only
- No styling yet
- Focus on accessibility and hierarchy
- Use proper ARIA labels

[After structure is approved]

Phase 2: Styling
- Implement Tailwind classes
- Match the attached spec exactly
- Mobile-first approach
```

### Pattern 2: Section-by-Section

```
We will implement this page in sections:
1. Header (fixed, 72px height)
2. Hero section (full viewport height)
3. Features grid (3 columns desktop, 1 column mobile)
4. CTA section
5. Footer

Let's start with the Header. Refer to header-spec.md for exact measurements.
```

### Pattern 3: Iterative Refinement

```
I've deployed the initial version. Here is a screenshot of the current state.
Here is the Figma mockup for comparison.

Identify all visual discrepancies:
- Spacing differences (margin, padding)
- Typography differences (size, weight, line-height)
- Color differences
- Border radius differences
- Shadow differences

Provide specific Tailwind class changes needed.
```

## Success Metrics

A high-fidelity Figma-to-code implementation should achieve:

1. **Visual Fidelity**
   - Pixel-perfect match at specified breakpoints (±2px tolerance)
   - Exact color values (no approximations)
   - Correct typography (font, size, weight, line-height, letter-spacing)

2. **Responsive Behavior**
   - Smooth transitions between breakpoints
   - No horizontal scroll on any viewport
   - Content reflows appropriately
   - Images scale correctly

3. **Interaction Fidelity**
   - All hover states implemented
   - Correct transition durations and easings
   - Focus states for keyboard navigation
   - Loading/error states designed

4. **Code Quality**
   - Semantic HTML structure
   - Proper component extraction (no duplication)
   - Accessible (WCAG AA minimum)
   - Performant (Lighthouse score >90)

5. **Maintainability**
   - Design tokens in Tailwind config (not magic values)
   - Components properly typed (TypeScript)
   - Clear component hierarchy
   - Documented edge cases

## Recommendations Summary

### Immediate Actions

1. **Standardize Figma export process**
   - Create template for spec markdown files
   - Establish cloud storage location for exports
   - Document export checklist for designers

2. **Create ui-dev agent**
   - Specialize in visual implementation
   - Knowledge base with Tailwind patterns
   - Trained on Agency stack (Next.js + React + Tailwind)

3. **Extend browser tool**
   - Add comparison mode for visual diffs
   - Add multi-viewport screenshot capability
   - Integrate with cloud storage for baseline management

### Short-Term Improvements

1. **Implement Figma API integration**
   - Build `./tools/figma-extract`
   - Automate spec generation
   - Sync design tokens

2. **Build visual regression testing**
   - Playwright + visual snapshots
   - CI/CD integration
   - Automated diff reports

3. **Create agent collaboration protocols**
   - Define handoff patterns for UI work
   - Standard review checklists
   - Feedback format templates

### Long-Term Vision

1. **Real-time Figma collaboration**
   - MCP server for Figma (if feasible)
   - Claude can inspect Figma files directly
   - Bidirectional sync (code changes → Figma annotations)

2. **AI-assisted design QA**
   - Automated accessibility audits
   - Responsive behavior validation
   - Performance optimization suggestions

3. **Learning system**
   - Capture patterns that work well
   - Build library of proven implementations
   - Train agents on project-specific conventions

## Conclusion

High-fidelity Figma-to-code translation is achievable through:
1. **Structured input** (specs + visuals, not just screenshots)
2. **Tool-assisted initial pass** (Figma plugins or focused prompts)
3. **Multi-agent iterative refinement** (structure → style → responsive → interaction → a11y)
4. **Automated validation** (visual regression, accessibility audits)

The Agency's multi-agent architecture is well-suited for this workflow, as different aspects can be delegated to specialized agents with clear handoff protocols.

The key is to **never ask Claude to infer what can be specified explicitly**. Provide structure, and let Claude focus on implementation quality and refinement.

---

**Next Steps:**
1. Review this strategy with Principal Jordan
2. Prioritize tooling gaps to address
3. Create first REQUEST to implement prioritized tools
4. Test workflow on pilot project
5. Iterate based on learnings
6. Document patterns in KNOWLEDGE base

**Related:**
- PROP-0015: Capture Web Content (relevant for screenshot capabilities)
- mock-and-mark project (screenshot annotation, may be useful for visual diff workflows)

**Questions for Jordan:**
- Which tools should we prioritize first?
- Do you have Figma API access we can use?
- Should we test this workflow on an existing project or a new one?
- Do you want specialized UI agents created now, or after tool foundation is built?
