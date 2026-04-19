---
type: plan
project: dispatch-monitor
workstream: agency
date: 2026-04-17
status: active
author: the-agency/jordan/captain
pvr: agency/workstreams/agency/dispatch-monitor-pvr-20260417.md
ad: agency/workstreams/agency/dispatch-monitor-ad-20260417.md
mar: "Quick MAR — 3 agents (methodology-critic, practitioner, adopter-advocate)"
---

# dispatch-monitor — Implementation Plan

## Scope

Single-phase, 3 iterations. Small tool — no need for multi-phase.

## Phase 1: Python Rewrite (3 iterations)

### Iteration 1.1: Core rewrite
- Replace `agency/tools/dispatch-monitor` with Python implementation
- Main loop: poll, parse, dedup, emit
- seen_ids as set with max 10,000 cap (LRU eviction via oldest-first discard)
- Subprocess calls to dispatch list and collaboration check
- Signal handling (SIGINT/SIGTERM)
- Error handling (catch subprocess failures, continue polling)
- Line-buffered stdout (flush=True on every print)
- Provenance headers (What Problem / How & Why / Written)
- CLI: --interval, --include-collab, --help

### Iteration 1.2: CI fix + testing
- Commit #159 release-tag-check polling fix (already coded)
- Write/update dispatch-monitor tests
- Verify Monitor tool integration manually

### Iteration 1.3: Documentation + fleet notification
- Update REFERENCE-PROVENANCE-HEADERS.md: Python is valid for tools
- Update dependencies.yaml if needed (Python 3.9+ as required dep)
- Brief migration note for release
- Flag clear: Python tooling review item
