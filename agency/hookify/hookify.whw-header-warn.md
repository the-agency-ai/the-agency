---
name: whw-header-warn
enabled: true
event: write
pattern: (\.sh|\.py|\.ts|\.js|\.rs|\.go|\.rb|\.java|\.c|\.cpp|\.h|claude/tools/|usr/.*/tools/)
action: warn
---

**WHW header required.** Source code files need a What/How/Why provenance header — "What Problem" (what need drove creation), "How & Why" (approach and reasoning), "Written" (date/context). New files must include one; edits to existing files should keep it current. See agency/REFERENCE-PROVENANCE-HEADERS.md.

*OFFENDERS WILL BE FED TO THE — CUTE — ATTACK KITTENS!*
