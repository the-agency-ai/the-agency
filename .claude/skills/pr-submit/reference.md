# pr-submit Dispatch Payload Protocol

## Purpose

Defines the structured payload `/pr-submit` sends to captain. Captain's `/pr-captain-land` relies on this structure to land the PR correctly. Changes to the payload require coordinated changes on both sides.

## Dispatch envelope

```
type:       dispatch
to:         monofolk/{principal}/captain
priority:   normal | high
subject:    "Ready for PR landing: {branch} — {scope}"
in_reply_to: null | <prior-dispatch-id>
```

## Body structure (markdown)

```markdown
# Ready for PR landing — {scope}

## Branch ready

- **Branch:** `{branch}`
- **Agent:** monofolk/{principal}/{agent}
- **HEAD:** `{sha}` (pushed to origin)
- **Diff base:** `origin/master`
- **Diff hash:** `{hash-7-char}`

## QGR receipt

- **Path:** `{receipt-relative-to-repo-root}`
- **Verified:** local receipt file matches current state

## Scope summary

{one-line summary from --scope flag}

## Captain action requested

Run /pr-captain-land on branch `{branch}`:

1. Switch to `{branch}`
2. Verify receipt against current state
3. Bump `monofolk_version` in manifest (serialized — single writer)
4. Create PR with captain-authored fleet-aware description
5. Watch CI (`lint-and-test` gate)
6. Merge when green
7. Create GitHub release v{monofolk_version}
8. Dispatch back with merge confirmation + release tag

## What I (agent) will NOT do

- Create the PR myself
- Bump `monofolk_version` myself
- Merge myself
- Create the release myself

Captain owns the PR lifecycle. I stand by to /pr-respond if review comments come.

Over.

-- monofolk/{principal}/{agent}
```

## Field specifications

| Field | Type | Source | Constraint |
|---|---|---|---|
| `branch` | string | `git rev-parse --abbrev-ref HEAD` | Not `master`, not `HEAD` (detached) |
| `sha` | string (40 char hex) | `git rev-parse HEAD` | Must equal `origin/{branch}` |
| `diff-hash` | string (7 char hex) | `./agency/tools/diff-hash --base origin/master --json` | First 7 of full SHA-256 |
| `receipt-path` | string | Glob `agency/workstreams/**/qgr/*qgr-pr-prep-*-{hash}.md` | Must exist, must match hash |
| `scope` | string | `--scope` flag | Required, non-empty |
| `priority` | enum | `--priority` flag | `normal` (default) or `high` |

## Captain-side parsing (/pr-captain-land)

Captain's `/pr-captain-land` script:

1. Reads the dispatch by ID or picks up from dispatch monitor
2. Parses `branch` and `diff-hash` from the body (regex against the structured fields)
3. Switches to that branch via `git-captain switch-branch`
4. Recomputes `diff-hash` on the branch and compares to the dispatched hash (must match)
5. Verifies the receipt file exists at the dispatched path
6. Proceeds with landing

## Protocol versioning

v1.0 — initial Phase 1 pilot (this document)

Future versions:
- v1.1: add `substance-summary` field (agent-authored, captain uses as PR body)
- v1.2: add `preferred-merge-method` (currently always `merge`, may allow rebase for specific branches)
- v2.0: machine-parseable JSON block alongside markdown body for stricter captain parsing

## Breaking changes

Any change to `branch`, `sha`, `diff-hash`, or `receipt-path` semantics is breaking. Bump major version and coordinate with pr-captain-land update.

Non-breaking additions (new fields captain ignores if not present) can happen without coordination.
