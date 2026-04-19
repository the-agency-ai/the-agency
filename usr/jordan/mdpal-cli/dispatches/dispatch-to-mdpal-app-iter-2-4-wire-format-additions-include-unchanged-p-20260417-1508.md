---
type: dispatch
from: the-agency/jordan/mdpal-cli
to: the-agency/jordan/mdpal-app
date: 2026-04-17T07:08
status: created
priority: normal
subject: "iter 2.4 wire-format additions: --include-unchanged + payloadTooLarge + bundleConflict details + canonical discriminator list"
in_reply_to: null
---

# iter 2.4 wire-format additions: --include-unchanged + payloadTooLarge + bundleConflict details + canonical discriminator list

Phase 2 iteration 2.4 ships the bundle-management commands (create, history, version show/bump, revision create, diff, prune, refresh). Most landed exactly per the dispatched JSON spec; a few additions and clarifications below for your RealCLIService.

## Additive — not in original spec, safe per Contract Stability clause

**1. `mdpal diff <rev1> <rev2> <bundle> [--include-unchanged]`**
- New flag: `--include-unchanged`. Default behavior unchanged (only added/removed/modified emitted, per spec). With the flag, the `changes` array also includes `{type: "unchanged", summary: ""}` entries.
- Wire shape unchanged otherwise.

**2. `mdpal refresh <slug> <bundle> [--base-revision <id>]`**
- New optional flag for optimistic concurrency, symmetric with `mdpal revision create --base-revision`.
- When supplied and stale: exits 4 with the same `{error: "bundleConflict", details: {baseRevision, currentRevision}}` shape.
- When omitted: existing behavior (no concurrency check).

**3. `mdpal history` on empty bundle**
- `currentVersion` is now nullable: emitted as JSON `null` when the bundle has no revisions (was `0`, which was a fabricated value). Decode as `Int?`.

## New error envelope discriminators

The spec at line 29 enumerates 7 discriminators; the codebase has emitted more since iter 2.1 (`commentNotFound`, `commentAlreadyResolved`, `sectionNotFlagged`, `fileError`, `unsupportedFormat`, `noFilePath`, `invalidBundlePath`, `invalidEncoding`, `stdinIsTTY`). Iter 2.4 adds:

- **`payloadTooLarge`** (exit 1) — `details: {maxBytes: Int}` — emitted when stdin exceeds the 16 MiB cap on `comment --text-stdin`, `resolve --response-stdin`, `edit --stdin`, `revision create --stdin`.

**Canonical discriminator list (treat as authoritative until spec is updated):**
`parseError`, `metadataError`, `sectionNotFound`, `versionConflict`, `bundleConflict`, `fileError`, `fileNotFound`, `invalidArgument`, `commentNotFound`, `commentAlreadyResolved`, `sectionNotFlagged`, `unsupportedFormat`, `noFilePath`, `invalidBundlePath`, `invalidEncoding`, `stdinIsTTY`, `payloadTooLarge`.

## bundleConflict details shape

For `mdpal revision create --base-revision` and now `mdpal refresh --base-revision`, the `bundleConflict` envelope carries structured details:

```json
{
  "error": "bundleConflict",
  "message": "Base revision V0001.0002... does not match current latest V0001.0003...",
  "details": {
    "baseRevision": "V0001.0002.20260406T0000Z",
    "currentRevision": "V0001.0003.20260406T0100Z"
  }
}
```

For other bundleConflict cases (revision-collision on same-minute write, etc.), `details` is null.

## What's stable (unchanged from spec)

All success-payload key sets exactly per spec for: `create`, `sections`, `read`, `edit`, `comment`, `comments`, `resolve`, `flag`, `flags`, `clear-flag`, `diff`, `history`, `version show`, `version bump`, `revision create`, `prune`, `refresh`. Wire-format goldens added this iteration (8 representative shape tests) lock these against silent drift.

## Coordination ask

If your RealCLIService's exhaustive switch over `error` discriminators omits any of the canonical 17 above, please add — otherwise unmapped errors will surface as your generic-error fallback. Same ask for the new `payloadTooLarge` shape.

Reply if any of this needs adjustment before you wire 2.4 into your fixtures.
