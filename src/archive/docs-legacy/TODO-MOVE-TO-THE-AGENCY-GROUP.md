# TODO: Move this content to the-agency-group

**Source:** `agency/docs/` (pre-v46.1)
**Destination:** `the-agency-group` cross-repo collaboration target
**Status:** Archived locally pending cross-repo move
**Decided:** 2026-04-20 1B1 session
**Captured by:** Plan v5 Phase 3

## Why archived here, not moved

Cross-repo move to `the-agency-group` requires collaboration infrastructure
setup. Archiving to `src/archive/docs-legacy/` as an interim step preserves
the content in the framework repo until the-agency-group collab pattern is
ready.

## Content inventory (as-of archive time)

- book-sources/ — research book references
- claude-code-extensibility/ — Claude Code extensibility notes
- cookbooks/ — framework cookbooks
- design/ — design investigations
- FIRST-LAUNCH-CONTEXT.jsonl — first-launch bootstrap context
- guides/ — how-to guides
- investigations/ — ad-hoc research
- reference/ — reference docs
- schemas/ — schema investigations
- tutorials/ — tutorials
- worknotes/ — captain worknotes

## Follow-up

Once the-agency-group collab pattern is operational, run cross-repo move:

```bash
./agency/tools/collaboration send the-agency-group \
  --subject "Incoming docs content from the-agency v46.1" \
  --body "Archived at src/archive/docs-legacy/; please merge into the-agency-group structure"
```

Then delete `src/archive/docs-legacy/` from the-agency repo.

## Retention rationale

Receipts + docs are never thrown away. Trust chain preservation + historical
research value.
