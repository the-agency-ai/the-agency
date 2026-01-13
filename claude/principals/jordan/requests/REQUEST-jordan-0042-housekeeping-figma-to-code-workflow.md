# REQUEST-jordan-0042: Figma-to-Code Workflow Implementation

**Principal:** Jordan
**Workstream:** housekeeping
**Agent:** housekeeping
**Status:** In Progress
**Created:** 2026-01-13
**Priority:** High

---

## Summary

Implement the tools and processes needed to operationalize the Figma-to-code workflow documented in ART-jordan-0002 and tested in the ordinaryfolk-001 design system extraction.

---

## Background

### Work Already Completed

1. **Strategy Document** - `ART-jordan-0002-figma-to-code-strategy.md`
   - Comprehensive strategy for translating Figma to high-fidelity code
   - Multi-agent workflow patterns
   - Tooling gap analysis
   - Prompt patterns that work

2. **UI Development Knowledge Base** - `claude/knowledge/ui-development/`
   - `INDEX.md` - Overview and quick reference
   - `figma-workflow.md` - Working with Figma designs
   - `high-fidelity-implementation.md` - Achieving pixel-perfect results
   - `responsive-design.md` - Multi-device implementation
   - `visual-qa-checklist.md` - Quality assurance checklist
   - `tailwind-patterns.md` - Common Tailwind CSS patterns

3. **Practical Test Case** - `ordinaryfolk-001` design system in ordinaryfolk-nextgen
   - Manual extraction from PDF exports
   - Standard directory structure established
   - Gap tracking methodology proven
   - Tailwind config generation pattern established
   - PROCESS.md captures lessons learned

### Key Learnings from ordinaryfolk-001

| What Worked | What Didn't Work |
|-------------|------------------|
| Modular file structure (colors.md, typography.md, etc.) | Hex values not extractable from PDFs |
| INDEX.md for quick reference | Manual transcription is slow (~2.5 hours) |
| GAPS.md for tracking unknowns | Font files not included in exports |
| Ready-to-copy Tailwind config | Desktop specs missing from mobile-only docs |
| Version numbering (brand-001, brand-002) | Component specs incomplete |

**Time Investment:**
- Manual process: ~2.5 hours per design system
- With tooling: ~15 minutes (estimated)
- ROI: Tooling pays for itself after 2-3 uses

---

## Requested Deliverables

### Phase 1: Design System Scaffolding Tools

#### 1.1 `./tools/init-design-system`

**Purpose:** Scaffold a new design system documentation structure.

**Usage:**
```bash
./tools/init-design-system <brand-name> <version>
# Example: ./tools/init-design-system acme 001
# Creates: claude/knowledge/design-systems/acme-001/
```

**Output Structure:**
```
claude/knowledge/design-systems/acme-001/
├── INDEX.md              # Overview (template)
├── PROCESS.md            # How this was extracted (template)
├── GAPS.md               # Missing information tracker (template)
├── GAP-RESOLUTION.md     # Resolution instructions (template)
├── colors.md             # Color palette (template)
├── typography.md         # Text styles (template)
├── spacing.md            # Spacing scale (template)
├── effects.md            # Shadows, borders (template)
├── assets.md             # SVGs, logos (template)
├── tailwind-config.md    # Tailwind theme (template)
└── source/               # Original source materials
```

**Templates should include:**
- Placeholder sections with clear instructions
- Examples from ordinaryfolk-001
- Validation checkboxes
- Standard table formats

#### 1.2 `./tools/validate-design-system`

**Purpose:** Verify a design system is complete and ready for implementation.

**Usage:**
```bash
./tools/validate-design-system <path>
# Example: ./tools/validate-design-system claude/knowledge/design-systems/acme-001
```

**Checks:**
- [ ] All required files present (INDEX.md, colors.md, typography.md, etc.)
- [ ] No placeholder values remaining (e.g., `[TODO]`, `???`)
- [ ] Hex values are valid format (#RRGGBB)
- [ ] Tailwind config is valid TypeScript
- [ ] No critical gaps outstanding in GAPS.md
- [ ] Font files referenced exist or fallback documented
- [ ] All color tokens used in tailwind-config match colors.md

**Output:**
```
Design System: acme-001
Status: INCOMPLETE

Issues:
  - colors.md: 5 placeholder hex values found
  - GAPS.md: 2 critical gaps outstanding
  - tailwind-config.md: Invalid TypeScript syntax on line 45
  - Font file not found: /fonts/Graphik-Regular.woff2

Warnings:
  - No desktop typography variants defined
  - No interaction states documented

Pass: 8/12 checks
```

---

### Phase 2: Figma Integration Tools

#### 2.1 `./tools/figma-extract`

**Purpose:** Extract design tokens directly from Figma via API.

**Prerequisites:**
- Figma Personal Access Token (store in Secret Service)
- Figma file key (from URL: figma.com/file/XXXXX/...)

**Usage:**
```bash
# Store Figma token
./tools/secret create figma-token --type=api_key --service=Figma

# Extract design system
./tools/figma-extract <file-key> --name=<brand-name> --version=<version>
# Example: ./tools/figma-extract abc123xyz --name=acme --version=001
```

**Extraction Capabilities:**
| Feature | Source | Output |
|---------|--------|--------|
| Colors | Figma Color Styles | colors.json, colors.md |
| Typography | Figma Text Styles | typography.json, typography.md |
| Spacing | Component analysis | spacing.md (if detectable) |
| Effects | Figma Effect Styles | effects.md |
| Assets | Page with assets | source/*.svg, source/*.png |
| Components | Component set analysis | components.md (basic) |

**Output Structure:**
```
claude/knowledge/design-systems/acme-001/
├── INDEX.md              # Auto-generated overview
├── colors.md             # From Color Styles
├── colors.json           # Machine-readable
├── typography.md         # From Text Styles
├── typography.json       # Machine-readable
├── spacing.md            # Inferred from components
├── effects.md            # From Effect Styles
├── tailwind-config.md    # Auto-generated
├── tailwind-config.ts    # Ready to use
├── GAPS.md               # Auto-generated for missing data
└── source/
    ├── colors-export.json
    ├── typography-export.json
    └── [exported assets]
```

**Implementation Notes:**
- Uses Figma REST API: `GET /v1/files/:file_key`
- Parse styles from `document.styles`
- Extract colors: `GET /v1/files/:file_key/styles`
- Export images: `GET /v1/images/:file_key`
- Requires handling pagination for large files

#### 2.2 `./tools/figma-diff`

**Purpose:** Visual comparison between Figma mockup and deployed implementation.

**Usage:**
```bash
./tools/figma-diff <mockup-path> <url> [--viewport=<width>x<height>]
# Example: ./tools/figma-diff source/home-desktop.png http://localhost:3000 --viewport=1440x900
```

**Process:**
1. Screenshot deployed URL at specified viewport
2. Load Figma mockup image
3. Generate pixel-diff overlay
4. Highlight differences (spacing, color, size)
5. Output annotated comparison image

**Output:**
```
claude/principals/jordan/resources/cloud/figma-diffs/
├── comparison-2026-01-13-120000.png
├── diff-overlay-2026-01-13-120000.png
└── report-2026-01-13-120000.md
```

**Report Format:**
```markdown
# Visual Diff Report

## Summary
- Match score: 94.2%
- Major differences: 3
- Minor differences: 12

## Issues Found
1. **Header height** - Expected: 72px, Actual: 68px
2. **Body text color** - Expected: #1A1A1A, Actual: #333333
3. **Card padding** - Expected: 24px, Actual: 16px

## Recommendations
- Check header CSS line-height
- Update text-primary color token
- Increase card padding to match design
```

**Dependencies:**
- Extend `./tools/browser` with comparison mode
- Use image diff library (pixelmatch or resemble.js)
- Save to principal's cloud storage

---

### Phase 3: Multi-Agent Workflow

#### 3.1 Agent Specialization

Create or enhance agents for UI work:

**`ui-dev` Agent**
- Purpose: Visual implementation specialist
- Knowledge: Tailwind patterns, responsive design, visual fidelity
- Tools: browser, figma-diff
- Primary task: Implement designs pixel-perfect

**Agent Definition:**
```
claude/agents/ui-dev/
├── agent.md
├── KNOWLEDGE.md → imports from claude/knowledge/ui-development/
├── WORKLOG.md
└── ADHOC-WORKLOG.md
```

#### 3.2 Collaboration Patterns

**Figma Implementation Request Flow:**
```
Principal → REQUEST with Figma exports → housekeeping
                                              ↓
                                        Create/update design-system
                                              ↓
housekeeping → collaborate → ui-dev (implement)
                                              ↓
ui-dev → collaborate → architect (structure review)
                                              ↓
ui-dev → collaborate → accessibility-specialist (a11y review)
                                              ↓
              Complete implementation ← ui-dev
```

**Standard Handoff Template:**
```markdown
## Collaboration Request: Implement [Screen Name]

### Context
- Design System: `claude/knowledge/design-systems/acme-001/`
- Mockups: `claude/principals/jordan/resources/cloud/figma-exports/acme/`

### Deliverables
1. React component(s) in `apps/[project]/components/`
2. Integration with design tokens from Tailwind config
3. Responsive behavior per spec

### Constraints
- Mobile-first implementation
- Must pass visual QA checklist
- Must be accessible (WCAG AA)

### References
- Spec: `design-systems/acme-001/home-spec.md`
- Mockups: `home-desktop-1440px.png`, `home-mobile-375px.png`
```

---

### Phase 4: Integration with Existing Systems

#### 4.1 Knowledge Base Integration

Ensure design system documentation is discoverable:

```
claude/knowledge/
├── INDEX.md                    # Updated to reference design-systems
├── ui-development/             # Implementation patterns
├── design-systems/             # Design tokens and specs
│   ├── _template/              # Template files for new systems
│   ├── ordinaryfolk-001/       # Production system
│   └── [other systems]/
└── [other knowledge areas]
```

**Update `claude/knowledge/INDEX.md`:**
```markdown
## Design Systems

Project-specific design tokens and specifications.

| Directory | Project | Status |
|-----------|---------|--------|
| `design-systems/ordinaryfolk-001/` | Health OS | In Progress |

### Creating New Design Systems

```bash
./tools/init-design-system <brand> <version>
```

See `design-systems/_template/` for standard structure.
```

#### 4.2 Tool Discovery

Add new tools to `./tools/find-tool`:

```bash
./tools/find-tool design
# Output:
# init-design-system    Create new design system documentation
# validate-design-system Verify design system completeness
# figma-extract         Extract tokens from Figma API
# figma-diff            Compare mockup vs implementation
```

---

## Implementation Plan

### Phase 1: Scaffolding (Priority 1)
1. Create `./tools/init-design-system`
2. Create `./tools/validate-design-system`
3. Create `claude/knowledge/design-systems/_template/`
4. Update knowledge INDEX.md

**Estimated Effort:** 4-6 hours

### Phase 2: Figma Integration (Priority 2)
1. Implement `./tools/figma-extract`
   - Figma API client
   - Color/typography extraction
   - Tailwind config generation
2. Implement `./tools/figma-diff`
   - Browser screenshot extension
   - Image diff integration
   - Report generation

**Estimated Effort:** 8-12 hours
**Dependency:** Figma API token in Secret Service

### Phase 3: Agent Setup (Priority 3)
1. Create `ui-dev` agent
2. Define collaboration templates
3. Document handoff patterns

**Estimated Effort:** 2-4 hours

### Phase 4: Integration (Priority 4)
1. Update knowledge base INDEX
2. Update tool discovery
3. Document in CLAUDE.md if needed

**Estimated Effort:** 1-2 hours

---

## Success Criteria

1. **Scaffolding Works**
   - `init-design-system` creates complete template structure
   - `validate-design-system` catches common issues
   - Time to create new design system: <5 minutes (vs 30+ manual)

2. **Figma Extraction Works**
   - Colors extracted with exact hex values
   - Typography extracted with full specs
   - Tailwind config auto-generated and valid
   - GAPS.md auto-generated for missing data

3. **Visual Comparison Works**
   - Screenshots match specified viewport
   - Diff overlay highlights differences
   - Report provides actionable feedback

4. **Agent Workflow Works**
   - ui-dev can implement from design system + mockups
   - Handoffs are clear and complete
   - Multiple agents can collaborate on UI work

---

## Dependencies

| Dependency | Status | Blocker? |
|------------|--------|----------|
| Figma Personal Access Token | Not configured | Yes for Phase 2 |
| Secret Service operational | Available | No |
| Browser tool | Available | No |
| pixelmatch/resemble.js | Not installed | Yes for figma-diff |

---

## Related Work

- **ART-jordan-0002** - Figma to High-Fidelity Code Strategy
- **ordinaryfolk-001** - Design system test case (in ordinaryfolk-nextgen)
- **PROP-0015** - Capture Web Content (browser tool)
- **REQUEST-jordan-0019** - DocBench enhancements (document viewing)

---

## Questions for Jordan

1. **Figma API Access** - Do you have a Figma account with API access?
   - If yes: Please create Personal Access Token and store via `./tools/secret create figma-token --type=api_key --service=Figma`

2. **Priority Order** - Which phase should we start with?
   - Option A: Scaffolding first (no external dependencies)
   - Option B: Figma extraction first (highest ROI)
   - Option C: Agent setup first (enables parallel work)

3. **Test Project** - Should we test on:
   - ordinaryfolk-nextgen (continue existing work)
   - New project (clean slate)

4. **Tool Technology** - For figma-diff image comparison:
   - Option A: Node.js with pixelmatch (simple, fast)
   - Option B: Python with OpenCV (more powerful analysis)
   - Option C: Integrate with browser tool (unified approach)

---

## Work Log

### 2026-01-13

**Initial Creation:**
- Created REQUEST document based on:
  - ART-jordan-0002-figma-to-code-strategy.md
  - ordinaryfolk-001 PROCESS.md learnings
  - ui-development knowledge base

**Analysis:**
- Reviewed ordinaryfolk-001 implementation in ordinaryfolk-nextgen
- Identified key patterns: modular structure, GAPS tracking, Tailwind config generation
- Confirmed manual process takes ~2.5 hours, tooling would reduce to ~15 minutes

---

**Next Step:** Awaiting principal input on priority and Figma API access.
