# Design System Extraction Guide

Best practices for extracting design systems from Figma with maximum fidelity.

---

## Quick Start

```bash
# 1. Store your Figma token (one-time setup)
./tools/secret create figma-token --type=api_key --service=Figma

# 2. Run automated extraction
./tools/figma-extract <file-key> --name=<brand> --version=001

# 3. Export PDFs from Figma for complete specs
# 4. Ask Claude to read PDFs and enhance the extracted files
```

---

## The Two Approaches

Both approaches use Claude - the difference is the input source:

| Approach | Input | Claude Does |
|----------|-------|-------------|
| **API Extraction** | Figma REST API JSON | Parses raw color/font data |
| **PDF Reading** | Designer's documentation | Transcribes specs, names, guidelines |

**The best results combine both.**

---

## Understanding the Gap

The Figma API provides **raw data** but not **designer intent**:

| What API Gives You | What Designers Document |
|--------------------|------------------------|
| Hex color values | Token names (`brand-primary`, `text-muted`) |
| Font family names | Weight usage guidelines |
| Usage counts | When to use each style |
| Raw fills/strokes | Semantic categories |

**The best results combine both sources.**

---

## Recommended Workflow

### Step 1: Automated Extraction (5 minutes)

Run `figma-extract` to get the raw design data:

```bash
./tools/figma-extract abc123xyz --name=acme --version=001
```

This creates:
- `colors.md` - All unique colors with hex values
- `typography.md` - Fonts with usage counts
- `source/figma-file.json` - Raw document data
- Template files for spacing, effects, assets

### Step 2: Export PDFs from Figma (10 minutes)

Designers typically create documentation pages in Figma. Export these as PDFs:

1. Open the Figma file in your browser
2. Navigate to documentation pages (look for "Colors", "Typography", "Components")
3. Select the frame containing the design specs
4. **File > Export frames to PDF**
5. Save to `<design-system>/source/`

**Common documentation pages to export:**
- Color palette/swatches
- Typography scale/text styles
- Spacing system
- Component specs
- Icon library

### Step 3: Claude Reads PDFs (15 minutes)

Ask Claude to read the PDFs and enhance the extracted files:

```
Read the PDF at source/colors.pdf and update colors.md with:
1. Token names for each color
2. Organize into categories (Neutrals, Brand, Semantic)
3. Add usage guidelines (when to use each color)
4. Create Tailwind class mappings
```

```
Read the PDF at source/typography.pdf and update typography.md with:
1. All text styles (headers, body, buttons, etc.)
2. Complete specs: size, weight, line-height, letter-spacing
3. Tailwind class for each style
4. Usage guidelines
```

### Step 4: Human Review (15 minutes)

Review and refine:
- Verify hex values match between automated and PDF
- Add any missing styles or variations
- Update `tailwind-config.md` with final tokens
- Run `./tools/designsystem-validate` to check completeness

---

## What Each Source Provides

### Figma API (Automated)

**Strengths:**
- Exact hex values from actual document
- Comprehensive (finds all colors/fonts used)
- Fast and repeatable
- Catches colors designers may have missed documenting

**Limitations:**
- No semantic meaning (just raw values)
- No organization or naming
- Typography specs incomplete (no sizes/weights)
- Published styles often sparse

### PDF Exports (Claude Reads)

Claude can read PDFs natively and extract design specs that aren't available via API.

**Strengths:**
- Designer's intended organization
- Semantic token names
- Complete typography specs (sizes, weights, line-heights)
- Usage guidelines and context
- Accessibility notes
- Tailwind class mappings (Claude generates these)

**Limitations:**
- Requires someone to export PDFs from Figma
- May not include all colors actually used
- Hex values are approximations (from visual inspection of swatches)
- Documentation can become outdated vs actual Figma file

### Combined Approach

| Data Point | Best Source |
|------------|-------------|
| Hex values | Automated (exact) |
| Token names | PDF (designer intent) |
| Color categories | PDF (semantic organization) |
| Font families | Automated (usage counts) |
| Text style specs | PDF (sizes, weights, line-heights) |
| Usage guidelines | PDF (designer knowledge) |
| Tailwind mappings | Claude (generates from specs) |

---

## Tips for Best Results

### For Colors

1. **Start with automated hex values** - They're exact
2. **Use PDF for naming** - Match hex to designer's token name
3. **Watch for near-duplicates** - `#1A1A1A` vs `#1B1B1B` may be the same intended color
4. **Document the primary palette** - Not every color needs a token

### For Typography

1. **Automated gives you fonts** - But not sizes/weights
2. **PDF gives you the scale** - The actual text styles
3. **Check font file availability** - Do you have the fonts?
4. **Map to Tailwind utilities** - Or create custom classes

### For Spacing

1. **Not extractable from API** - Must infer from components
2. **PDF may document the scale** - 4, 8, 16, 24, 32, etc.
3. **Check component padding** - In source/figma-file.json
4. **Use standard scales** - When in doubt, use 4px base

---

## Example: Complete Extraction Session

```bash
# 1. Extract from Figma
./tools/figma-extract qaWYnSjA1EiarqNwMHM2zK --name=healthos --version=001

# 2. Check what we got
cat claude/knowledge/design-systems/healthos-001/colors.md
# Shows: 69 unique colors, needs naming

cat claude/knowledge/design-systems/healthos-001/typography.md
# Shows: Graphik (418 uses), Poppins (338), needs specs
```

Then in Figma:
1. Export "Colors" page → `source/colors.pdf`
2. Export "Typography" page → `source/typography.pdf`

Then ask Claude:
```
Read source/colors.pdf and source/typography.pdf.
Update colors.md and typography.md with the complete specs,
token names, and Tailwind mappings.
```

Finally:
```bash
./tools/designsystem-validate claude/knowledge/design-systems/healthos-001
```

---

## Troubleshooting

### "Only 1-2 published styles found"

This is normal. Most designers don't formally publish styles to the Figma library. The automated extraction still captures embedded colors/fonts from the document.

### "Hex values don't match PDF"

Trust the automated hex values - they're extracted from actual document data. PDF colors are approximations from visual inspection.

### "Missing text style specs"

The API doesn't provide fontSize/fontWeight for arbitrary text. You need the PDF export or manual inspection of specific nodes.

### "Too many colors extracted"

The tool extracts ALL unique colors, including one-off variations. Focus on documenting the core palette from the PDF, and note which automated colors map to which tokens.

---

## Time Estimates

| Approach | Human Time | Claude Time | Quality |
|----------|------------|-------------|---------|
| API only | 2 min (run command) | 10 sec | Raw data, needs naming |
| PDF only | 10 min (export PDFs) | 15-20 min | Complete specs, approx hex |
| **Hybrid** | 12 min total | 20 min | Best of both |

**Note:** Both approaches are Claude doing the work - the difference is whether Claude reads API JSON or PDF documents. The hybrid approach gives Claude both sources to work with.

---

## Example Prompts for Claude

After running `figma-extract` and exporting PDFs, use these prompts:

### Colors

```
Read the PDF at claude/knowledge/design-systems/acme-001/source/colors.pdf

Update colors.md with:
1. Token names for each color (e.g., of-black-900, brand-primary)
2. Organize into categories: Neutrals, Brand Colors, Semantic Colors
3. Add usage guidelines (text colors, backgrounds, borders, states)
4. Match the extracted hex values to the PDF's named tokens
5. Generate Tailwind class names for each token
```

### Typography

```
Read the PDF at claude/knowledge/design-systems/acme-001/source/typography.pdf

Update typography.md with:
1. Font family details (weights available, fallback stack)
2. All text styles with complete specs:
   - Style name (H1, Body 1, Button, etc.)
   - Font weight
   - Font size
   - Line height
   - Letter spacing
   - Text transform
3. Tailwind classes for each style
4. Usage guidelines (hierarchy, accessibility)
```

### Full Enhancement

```
I've run figma-extract and exported PDFs to source/. Please:

1. Read colors.pdf and enhance colors.md with named tokens and organization
2. Read typography.pdf and enhance typography.md with complete text styles
3. Update tailwind-config.md with the final token values
4. Update GAPS.md to reflect what's now complete vs still missing
```

---

## Specialized Agent

For complex or ongoing design system work, create a dedicated agent:

```bash
./tools/agent-create ds-extractor design --type=design-system
./tools/myclaude design ds-extractor
```

The `design-system` agent template comes pre-configured with:
- Knowledge of extraction workflows
- Checklists for colors, typography, spacing
- Standard file structures and naming conventions

---

## See Also

- `./tools/figma-extract --help` - Tool documentation
- `./tools/designsystem-validate` - Validation tool
- `./tools/agent-create --type=design-system` - Specialized agent
- `_template/` - Template files for new design systems
