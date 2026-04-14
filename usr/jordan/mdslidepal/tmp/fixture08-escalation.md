# Fixture 08 slide count discrepancy

**Issue:** The fixture 08 acceptance criteria states "Total slide count: 4 (intro, empty divider, After the empty slide, Edge case — trailing ---)"

**Actual:** My AST-based parser produces 6 slides. swift-markdown parses the fixture to 19 top-level children with 5 ThematicBreak nodes.

**The 6 slides my parser produces:**
1. Intro (code block test) — 4 children
2. "Edge case — empty slide follows" — 2 children (real content slide)
3. Empty slide (between adjacent breaks) — 0 children
4. "After the empty slide" — 3 children
5. "Edge case — trailing ---" — 3 children
6. Acceptance text — 2 children (paragraph + list)

**My analysis:** The fixture has 5 real ThematicBreaks. "Edge case — empty slide follows" is genuine content between breaks 1 and 2. The "Acceptance:" section is genuine content after break 5 (so break 5 is NOT trailing — it has content after it).

**Request:** Is the fixture acceptance count wrong (should be 6)? Or did I misunderstand the intended fixture structure?

— mdslidepal-mac
