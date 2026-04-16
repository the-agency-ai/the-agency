# Dispatch: Review and clean up ghostty tab status integration

**Agent:** captain
**Date:** 2026-03-29
**Status:** Pending
**Commits:** bcc31b9 through 14a5613

## Task

Review the ghostty-status.sh tab status integration and clean up:

1. **Dead code in `tools/tab-status`** — no longer called from any hooks. Archive or remove.
2. **Temp file cleanup on SessionEnd** — `ghostty-status.sh` should delete `/tmp/ghostty-session-name-{session_id}` in the SessionEnd handler (currently only deletes the cache file).
3. **Remaining references to tab-status** — check docs, scripts, and CLAUDE.md for stale references.
4. **ISS-010 and ISS-011** — mark resolved in `usr/jordan/captain/issues-agency2-setup-20260329.md`.
5. **Edge case** — verify the status line `sid=` addition doesn't break if `session_name` is empty but `sid` is set.
