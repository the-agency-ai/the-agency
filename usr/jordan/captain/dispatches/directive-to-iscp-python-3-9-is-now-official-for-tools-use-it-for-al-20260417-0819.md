---
type: directive
from: the-agency/jordan/captain
to: the-agency/jordan/iscp
date: 2026-04-17T00:19
status: created
priority: normal
subject: "Python 3.9+ is now official for tools — use it for all future work"
in_reply_to: null
---

# Python 3.9+ is now official for tools — use it for all future work

Principal directive (D44):

Python 3.9+ (stdlib only, no pip) is now a valid and encouraged language for framework tools. dispatch-monitor was rewritten from bash to Python today — first Python tool in claude/tools/. It's shipped and running.

**For you specifically:**

1. **All new tools you write should be Python 3.9+.** You own dispatch, flag, collaboration, iscp-check, iscp-migrate, agent-identity — these are prime candidates for Python (SQLite access, JSON parsing, set/dict data structures, proper error handling).

2. **Review your existing tools for upgrade.** If any tool is fighting bash limitations (associative arrays, complex string parsing, error handling, long-running processes), consider rewriting in Python. dispatch-monitor hit declare -A (bash 4+) which broke on macOS — you may have similar landmines.

3. **Constraints:** stdlib only. No pip, no virtualenv. Shebang: #!/usr/bin/env python3. Use 'from __future__ import annotations' for modern type hints on 3.9. Template at claude/templates/TOOL.py.

4. **Reference:** REFERENCE-PROVENANCE-HEADERS.md now documents the bash vs Python decision table.

This is not a request to rewrite everything now. It's a standing directive: Python first for new work, and upgrade existing tools when you're already touching them.
