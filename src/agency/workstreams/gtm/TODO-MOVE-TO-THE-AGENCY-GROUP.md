# TODO: Move `gtm/` workstream to the-agency-group

**Status:** Kept in-place pending cross-repo move
**Decided:** 2026-04-20 per Plan v5 Phase 3

## Why kept here

`agency/workstreams/gtm/` is go-to-market content that belongs with the broader agency-group planning, not inside the framework development repo. Cross-repo move to `the-agency-group` pending collaboration infrastructure.

## Follow-up

When the-agency-group collab pattern is operational:

```bash
./agency/tools/collaboration send the-agency-group \
  --subject "Move gtm/ workstream content" \
  --body "Source: agency/workstreams/gtm/ in the-agency repo; destination: the-agency-group workstream layout"
```

Then delete `agency/workstreams/gtm/` from the-agency repo.
