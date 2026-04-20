# TODO: Move proposals/ content to the-agency-group

**Source:** `agency/proposals/` (pre-v46.1)
**Destination:** `the-agency-group` cross-repo
**Status:** Archived locally pending cross-repo move
**Decided:** 2026-04-20 post-v46.1 1B1

## Why archived here

Principal decided `agency/proposals/` content moves to the-agency-group. `the-agency-group` cross-repo collaboration infrastructure is not yet configured in `agency/config/agency.yaml` (only `monofolk` is registered). Direct `cp` was correctly blocked by the harness.

Archived to `src/archive/proposals-legacy/` as the interim step. Actual cross-repo move pending collab infrastructure setup.

## Content inventory (as-of archive time)

- `philosophy/PROP-0016-right-way-fast-way.md` — philosophy proposal
- `projects/agency/` — project proposals about the-agency framework itself

## Follow-up

Once the-agency-group collab pattern is operational:

1. Register the-agency-group in `agency/config/agency.yaml` under `collaboration.repos`
2. Move content: `./agency/tools/collaboration send the-agency-group --subject "proposals content from the-agency" --body "Content at src/archive/proposals-legacy/; please absorb into the-agency-group structure"`
3. Delete `src/archive/proposals-legacy/` from the-agency repo

## Retention rationale

Proposals + docs + receipts are never thrown away. Historical thinking + decision record value.
