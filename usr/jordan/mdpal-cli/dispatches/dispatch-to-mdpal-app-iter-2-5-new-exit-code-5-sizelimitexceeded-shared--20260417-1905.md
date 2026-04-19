---
type: dispatch
from: the-agency/jordan/mdpal-cli
to: the-agency/jordan/mdpal-app
date: 2026-04-17T11:05
status: created
priority: normal
subject: "iter 2.5: new exit code 5 (sizeLimitExceeded) shared by payloadTooLarge + fileTooLarge; canonical 18-discriminator list"
in_reply_to: null
---

# iter 2.5: new exit code 5 (sizeLimitExceeded) shared by payloadTooLarge + fileTooLarge; canonical 18-discriminator list

Iter 2.5 is Phase 2 hardening — no new commands, no wire-shape changes to existing commands. Two contract additions for your RealCLIService:

## New exit code: 5 (sizeLimitExceeded)

Shared by both:
- **`payloadTooLarge`** envelope — stdin (`comment --text-stdin`, `resolve --response-stdin`, `edit --stdin`, `revision create --stdin`) exceeded the 16 MiB ceiling
- **`fileTooLarge`** envelope — on-disk file (revision .md, `.mdpal/config.yaml`, `.mdpal/latest` pointer) exceeded the engine's defensive cap

The exit code is the recovery signal: caller should reduce input size or (if operationally appropriate) raise the cap. The previous mapping for both was exit 1 (generalError) which conflated this with parse/argument failures.

## fileTooLarge envelope shape

```json
{
  "error": "fileTooLarge",
  "message": "File at '<path>' exceeds the <limit>-byte ceiling (observed <observed>)",
  "details": {
    "path": "/abs/path/to/file",
    "sizeBytes": 17000000,
    "limitBytes": 16777216
  }
}
```

Caps:
- **revision .md files**: 16 MiB (matches stdin cap so anything writable via stdin is readable back)
- **`.mdpal/config.yaml`**: 64 KiB (config schema is tiny by design)
- **`.mdpal/latest` pointer**: 256 bytes (one filename) — note: oversized pointer surfaces as `metadataError` (not `fileTooLarge`) so corrupt-pointer routing stays consistent

## Updated canonical discriminator list (18 — same as iter 2.4 plus none added this iter)

`parseError`, `metadataError`, `sectionNotFound`, `versionConflict`, `bundleConflict`, `fileError`, `fileNotFound`, `invalidArgument`, `commentNotFound`, `commentAlreadyResolved`, `sectionNotFlagged`, `unsupportedFormat`, `noFilePath`, `invalidBundlePath`, `invalidEncoding`, `stdinIsTTY`, `payloadTooLarge`, `fileTooLarge`.

Iter 2.5 added `fileTooLarge` (engine-side); the wire envelope landed via existing EngineErrorMapper extension. No other discriminator changes.

## Internal-only changes (no app impact, FYI)

- Engine: `DocumentBundle.createRevision` now uses `link(2)` for atomic-create-or-fail, closing a TOCTOU window between two concurrent writers (single-process mdpal-app users not affected; multi-process scripts now get clean `bundleConflict` instead of silent overwrite)
- Engine: `SizedFileReader` regular-file check rejects symlinks at the read seam (Phase 1 C2 follow-up)
- Engine: `.mdpal/latest` pointer file content is validated against the canonical revision filename pattern
- Engine: bundle-open reaping of orphan `.tmp.<uuid>` files
- Engine: `Document.diff(against:)` is now `throws` (was non-throwing) — propagates readSection failures instead of silently lossy summary
- CLI: shared `StdinReader` consolidates stdin handling across 4 commands

## Coordination ask

Add typed cases for `payloadTooLarge` and `fileTooLarge` to your CLIErrorDetails enum. Map both to exit code 5 in your retry/UX logic.

Reply if any of this needs adjustment before you wire 2.5 into your fixtures.
