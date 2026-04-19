# Historical Path Note — v46.0 Flotsam

This directory contains content archived during the v46.0 structural reset (2026-04-19 → 2026-04-20).

## What's here

- `principals/` — legacy v1 principal system (replaced by `usr/` + `agency.yaml`)
- `proposals/` — legacy proposal drafts superseded by workstream artifacts
- `reviews/` — legacy review doc (obsolete)
- `legacy-injection-test-artifact/` — security-audit injection-test artifact (originally named with embedded shell metachars; stripped for safety)

## Why archived vs deleted

Per Plan v4 Principle 2 (archive-before-delete): every removal from the `agency/` tree is preceded by a move to flotsam unless the captain has explicit principal 1B1 on `--confirmed-zero-value`. These dirs contained historical content that had limited forward value but non-zero archival value (example principal scaffolding, historical plan/review decisions).

## Historical path references

Artifacts in this flotsam may reference pre-v46.0 paths like `claude/principals/` or `claude/plans/`. These references are preserved verbatim as historical record (Principle 9 excludes `history/**` from the reference sweep).

## How to find something

If you're looking for the v45-era principal docs or proposals:
- `history/flotsam/principals/<principal-name>/` — per-principal scaffold folders
- `history/flotsam/proposals/` — proposals sorted by date

The active v46 replacement:
- Principal sandboxes: `usr/<principal>/`
- Workstream artifacts: `agency/workstreams/<workstream>/`
