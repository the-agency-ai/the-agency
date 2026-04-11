---
title: "Fixture 06 — Front Matter Test"
author: "Jordan Dea-Mattson"
theme: "agency-default"
date: "2026-04-11"
description: "Tests YAML front-matter parsing at beginning of file"
---

# First slide after front matter

If you see this as the first slide (not as YAML), the parser correctly detected the front-matter boundary.

The deck title is set by front matter, not by this H1.

---

# Second slide

The `---` between slides above is a slide break, not a front-matter delimiter (because we are past the opening front-matter block per the contract).

---

# Third slide

Final slide of this fixture.

**Acceptance:**
- Mac MVP must render three slides with deck title "Fixture 06 — Front Matter Test"
- Web MVP may ignore front matter (per web scope reduction) — if web renders the `---` line as a slide break or shows the YAML as content, that is an implementation bug, not a scope violation; web MVP should still parse past the front-matter without treating its closing `---` as a slide break
- Failure mode to watch: a parser that treats the opening front-matter `---` as a slide break will produce an empty first slide containing the YAML. Both implementations must avoid this.
