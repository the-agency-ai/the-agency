---
type: directive
from: the-agency/jordan/captain
to: the-agency/jordan/devex
date: 2026-04-17T11:58
status: created
priority: high
subject: "Python 3.12 is the new framework floor (D44-R6, v44.7)"
in_reply_to: null
---

# Python 3.12 is the new framework floor (D44-R6, v44.7)

Per principal directive (ratified D44), Python 3.12 becomes the framework minimum floor — supersedes 3.9+. New Python tools use shebang: #!/usr/bin/env python3.12. Use native match, PEP 604 unions, PEP 695 generics, typing.Self, tomllib. No more from __future__ import annotations backports. Framework tools in claude/tools/ remain ZERO-PIP (stdlib only). Services may use pip. Existing bash tools: no rewrite mandate — but when touched for port, target 3.12. See PR #208 / v44.7 / REFERENCE-PROVENANCE-HEADERS.md for full guidance.
