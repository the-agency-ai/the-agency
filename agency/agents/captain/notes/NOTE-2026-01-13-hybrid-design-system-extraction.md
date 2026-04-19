# Working Note: Hybrid Design System Extraction

**Date:** 2026-01-13
**Related:** REQUEST-jordan-0042

---

## Summary

Demonstrated the hybrid workflow for design system extraction by creating `ordinaryfolk-003` from the NOAH-APP Figma file. The approach combines Figma API extraction with Claude reading designer PDFs.

## The Problem

The Figma API only returns "published" library styles, which designers don't consistently create. Manual extraction from PDFs captures designer intent but uses approximate hex values from visual inspection.

## The Solution: Hybrid Workflow

```
┌─────────────────────────────────────────────────────┐
│  Figma API (figma-extract)     +     PDF (Claude)   │
│  ─────────────────────────          ─────────────   │
│  • 69 exact hex colors              • Token names   │
│  • 3 fonts + usage counts           • Organization  │
│  • All colors actually used         • Typography    │
│  • Fast (10 seconds)                • Guidelines    │
└─────────────────────────────────────────────────────┘
                          ↓
              Merged Design System
              • Exact values + semantic names
              • Complete coverage + curated palette
              • Production-ready Tailwind config
```

## Results: v001 vs v003

| Metric | v001 (PDF Only) | v003 (Hybrid) |
|--------|-----------------|---------------|
| Time | ~2.5 hours | ~30 minutes |
| Color accuracy | Approximate | Exact |
| Color coverage | ~50 documented | 69 total |
| Discovery | None | 20+ undocumented |
| Typography | Complete | Complete |

## Key Discoveries

1. **Health OS Accent Palette** - Found warm colors not in standard palette:
   - `#EBE3D7` warm-cream
   - `#D0B895` sand
   - `#B89460` caramel
   - `#D7A492` peach

2. **Secondary Font** - Poppins (338 uses) alongside Graphik (418 uses)

3. **Undocumented Colors** - 20+ colors used in designs but not in design system PDF

## Deliverables Created

1. **`figma-extract` v1.2.0** - Now parses document structure for embedded colors/fonts
2. **`EXTRACTION-GUIDE.md`** - Best practices for hybrid workflow
3. **`design-system` agent template** - Specialized agent for extraction work
4. **`ordinaryfolk-003/`** - Complete design system demonstrating the workflow

## Implications for UI Work

The ordinaryfolk-003 design system should improve UI implementation:

- **Exact hex values** - No more guessing colors from PDF swatches
- **Complete typography** - Every text style with size/weight/line-height
- **Tailwind config ready** - Copy-paste into project
- **Undocumented colors flagged** - Can discuss with design team

## Next Steps

- Use ordinaryfolk-003 for ongoing Health OS UI work
- Consider updating ordinaryfolk-nextgen to use v003 tokens
- Share undocumented colors list with design team for review
