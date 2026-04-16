# Gap Resolution Guide

## Recommended: PDF Export Workflow

The Figma API only returns "published" library styles, which may be sparse.
For comprehensive extraction, export design documentation pages as PDFs:

### Step 1: Export from Figma

1. Open the Figma file in your browser
2. Navigate to the Colors/Typography/Effects documentation pages
3. Select the frame(s) containing the design specs
4. File > Export frames to PDF
5. Save to this directory's `source/` folder

### Step 2: Let Claude Read the PDFs

Ask Claude Code to read and transcribe:

```
Read the PDFs in source/ and update colors.md with the color values you find.
Include hex codes, token names, and any usage guidelines shown.
```

Claude can read PDFs natively and extract the visual color swatches, typography
specs, and other design values that aren't available via the API.

---

## Alternative: Manual API Extraction

If you have published styles in Figma, you can extract from the JSON:

### Resolving Color Gaps

1. Open `source/figma-styles.json`
2. Find style entries with `"styleType": "FILL"`
3. Look for the `color` object with `r`, `g`, `b`, `a` values (0-1 range)
4. Convert to hex: `#RRGGBB` where each component = value * 255

**Example:**
```json
{ "r": 0.2, "g": 0.4, "b": 0.8 }
```
Converts to: `#3366CC`

### Resolving Typography Gaps

1. Open `source/figma-styles.json`
2. Find style entries with `"styleType": "TEXT"`
3. Extract font family, size, weight, line height

---

## Exporting Assets

1. Open Figma file in browser
2. Select assets to export (logos, icons, illustrations)
3. Right-click > Export
4. Choose format (SVG for icons, PNG for images)
5. Save to `source/` directory
6. Update `assets.md` with paths
