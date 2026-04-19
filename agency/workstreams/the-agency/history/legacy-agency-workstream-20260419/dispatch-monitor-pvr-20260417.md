---
type: pvr
project: dispatch-monitor
workstream: agency
date: 2026-04-17
status: draft
author: the-agency/jordan/captain
seeds:
  - "1B1 discussion with principal on Python tooling strategy (2026-04-17)"
  - "Issue #144 — dispatch-monitor stale-read loop"
  - "dispatch-monitor bash 3.2 failure on macOS"
---

# dispatch-monitor — Python Rewrite PVR

## Vision

Rewrite `dispatch-monitor` from bash to Python 3.9+, establishing it as the first Python tool in the framework and setting the precedent that Python is a valid and encouraged language for Agency tools.

## The Problem

1. **dispatch-monitor is broken on macOS.** It uses `declare -A` (bash 4+ associative arrays) for SEEN_IDS tracking. macOS ships bash 3.2 (Apple won't ship GPLv3). The Monitor tool can't run it. All agent collaboration via dispatch monitoring is down fleet-wide.

2. **Bash is the wrong language for this tool.** dispatch-monitor needs a set data structure (seen IDs), runs as a long-lived process, does string parsing, and would benefit from proper error handling. All of these are painful or impossible in bash 3.2.

3. **No Python tools exist in the framework yet.** The TOOL.py template was created in D43 (#141) but has never been used for a shipped tool. There's no precedent for Python tools, and documentation doesn't clearly state Python is an option.

## Target Users

- **Captain agent** — primary consumer of dispatch notifications via Monitor tool
- **Worktree agents** — receive dispatches from captain and other agents
- **Adopter repos** — any repo running `agency update` gets this tool

## Use Cases

1. **UC1: Background dispatch monitoring** — Captain starts Monitor with dispatch-monitor at session start. Script polls every N seconds, only outputs when new unread dispatches exist. Monitor tool surfaces each output line to the agent.

2. **UC2: Cross-repo collaboration monitoring** — With `--include-collab`, also checks the collaboration channel for cross-repo dispatches.

3. **UC3: Stale-read prevention** — Once a dispatch ID has been surfaced, it never surfaces again, even if the underlying query returns it (resolved dispatch re-appearing, identity shift, etc.).

4. **UC4: Standalone usage** — Can be run directly from CLI for debugging/testing without the Monitor tool.

## Functional Requirements

| ID | Requirement |
|----|-------------|
| FR1 | Poll `dispatch list --status unread` every N seconds (default 10, configurable via `--interval`) |
| FR2 | Only produce output when NEW unread dispatches exist (completely silent otherwise) |
| FR3 | Track seen dispatch IDs in a set — once emitted, never emit again (stale-read prevention) |
| FR4 | Optionally check cross-repo collaboration via `--include-collab` flag |
| FR5 | Prefix output with `[DISPATCH]` or `[COLLAB]` for routing |
| FR6 | Support `--help` flag with usage information |
| FR7 | Use Python 3.9+ with no external dependencies (stdlib only) |
| FR8 | Interoperate with existing JSONL telemetry (_log-helper format) |
| FR9 | Flush stdout after every write (line-buffered for Monitor tool compatibility) |

## Non-Functional Requirements

| ID | Requirement |
|----|-------------|
| NFR1 | Zero external Python dependencies — stdlib only |
| NFR2 | Memory-stable for long-running sessions (seen_ids set grows but dispatch IDs are small integers) |
| NFR3 | Graceful handling of subprocess failures (dispatch tool not found, DB locked, etc.) |
| NFR4 | Clean shutdown on SIGINT/SIGTERM |
| NFR5 | Provenance headers following TOOL.py template pattern |
| NFR6 | Python 3.9+ floor (matches macOS system Python) |

## Constraints

1. Must be a drop-in replacement — same CLI interface (`--interval N`, `--include-collab`, `--help`)
2. Must work with the Monitor tool (stdout is the event stream, stderr for diagnostics)
3. No pip install — stdlib only
4. Shebang must be `#!/usr/bin/env python3` (resolves correctly on macOS and Linux)
5. Must replace the existing bash script at `agency/tools/dispatch-monitor` (not a new path)

## Success Criteria

1. `dispatch-monitor --include-collab` runs successfully under the Monitor tool on macOS with system Python 3.9
2. Stale-read prevention works (same dispatch ID never emitted twice)
3. Silent when no new dispatches (zero output, no tokens consumed)
4. All existing dispatch-monitor tests pass (update test expectations if needed)
5. First Python tool shipped in `agency/tools/` — sets the precedent

## Non-Goals

- Rewriting other tools in Python (separate initiative, flagged for review)
- Adding pip/virtualenv infrastructure
- Changing the dispatch tool itself (this is just the monitor wrapper)
- Python packaging or distribution concerns

## Open Questions

None — principal discussion resolved all questions (Python 3.9+, stdlib only, first tool, update docs).
