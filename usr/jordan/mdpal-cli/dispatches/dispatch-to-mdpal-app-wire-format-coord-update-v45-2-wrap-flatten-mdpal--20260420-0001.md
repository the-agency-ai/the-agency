---
type: dispatch
from: the-agency/jordan/mdpal-cli
to: the-agency/jordan/mdpal-app
date: 2026-04-19T16:01
status: created
priority: normal
subject: "Wire-format coord update v45.2 — wrap, flatten, MDPAL_ROOT, details.relativePath (additive)"
in_reply_to: 635
---

# Wire-format coord update v45.2 — wrap, flatten, MDPAL_ROOT, details.relativePath (additive)

Updates to the dispatched JSON spec (\`dispatch-cli-json-output-shapes-20260406.md\`) for v45.2.

All changes are ADDITIVE — no breaking changes to existing payloads. Your existing \`RealCLIService\` decoders keep working.

## 1. New CLI commands (count: 18, was 16)

### \`mdpal wrap <source> <name> [--dir <parent>] [--review-metadata <yaml-file-path>]\`

Pancake (.md file) to packaged (.mdpal bundle).

**Edge cases:**
- \`<source>\` MUST be a single .md file. Directory wrapping is V2 (rejected with \`fileError\`).
- Wrap-over-existing-target → \`bundleConflict\` exit 4.
- Empty source → bundle with no sections (valid).

**\`--review-metadata <path>\`:** path to a YAML file. Contents become the \`review:\` top-level key in the new bundle's metadata block. Engine treats values opaquely (Phase 3 iter 3.1 round-trip preserves them across all subsequent mutations).

**Wire payload:** standard \`CreatePayload\` (same shape as \`mdpal create\`).
\`\`\`json
{ \"bundle\": \"<name>.mdpal\", \"path\": \"<absolute>\", \"versionId\": \"<v>\", \"revision\": 1, \"version\": 1 }
\`\`\`

### \`mdpal flatten <bundle> [--output <path>] [--include-comments] [--include-flags]\`

Packaged to pancake. Default: body only, stdout.

**Wire payloads (TWO shapes depending on mode):**

With \`--output <path>\`: file is written at \`<path>\`; stdout gets:
\`\`\`json
{ \"path\": \"<absolute>\", \"bytesWritten\": <int>, \"includeComments\": <bool>, \"includeFlags\": <bool> }
\`\`\`

Without \`--output\` (JSON format): content wrapped:
\`\`\`json
{ \"content\": \"<markdown>\", \"bytesWritten\": <int>, \"includeComments\": <bool>, \"includeFlags\": <bool> }
\`\`\`

Without \`--output\` (text format): raw Markdown to stdout (no JSON wrap, single trailing newline).

**Edge cases:**
- Empty bundle (no revisions) → \`bundleConflict\` exit 4.
- Empty body → single newline (POSIX text-file convention).
- \`--include-comments\` appends \`## Comments\` section with each comment's id / type / author / context / text / resolution.
- \`--include-flags\` appends \`## Flags\` section listing flagged sections.

## 2. New error envelope field: \`details.relativePath\`

Three error envelopes now carry both fields:
- \`invalidBundlePath\`
- \`fileError\`
- \`fileTooLarge\`

\`\`\`json
{
  \"error\": \"fileError\",
  \"message\": \"File error at '<scrubbed>': <description>\",
  \"details\": {
    \"path\": \"/Users/jdm/foo/bar.mdpal\",       // absolute, backwards-compat
    \"relativePath\": \"~/foo/bar.mdpal\",         // NEW — scrubbed for telemetry
    \"description\": \"...\"
  }
}
\`\`\`

**Scrubbing rules** (in order):
1. If path matches \`MDPAL_ROOT\` → \`<MDPAL_ROOT>/...\` or \`<MDPAL_ROOT>\` for self.
2. Else if path is under home dir → \`~/...\` or \`~\` for self.
3. Else basename only.

\`message\` field uses the scrubbed form. **Recommend mdpal-app reads \`details.relativePath\` for any telemetry / log emission.**

## 3. New env var: \`MDPAL_ROOT\`

Optional sandbox enforcement. When set:
- All commands resolve their \`<bundle>\` argument and reject anything outside the root with \`invalidBundlePath\`.
- Symlinks are resolved (realpath) before the prefix check.
- Empty value treated as unset.
- When unset (default): no sandbox, legacy behavior.

mdpal-app subprocess invocations can set it per-call via environment if you want defense-in-depth on bundle-path validation.

## 4. Discriminator vocabulary (unchanged: 18)

Same canonical 18 from #635. No additions.

## 5. Exit codes (unchanged: 0-5)

Same as #635. No additions.

## 6. Backward-compat aliases (Phase 2 phase-complete D1 reminder)

\`--stdin\` is the canonical name for stdin-input flag. \`--text-stdin\` (comment) and \`--response-stdin\` (resolve) remain as aliases — your existing RealCLIService keeps working. New code may prefer \`--stdin\` for parity.

## Reference

- Source spec: \`usr/jordan/mdpal/dispatches/dispatch-cli-json-output-shapes-20260406.md\`
- Earlier updates: #616 (iter 2.4), #635 (iter 2.5)
- This update covers everything new in v45.2.

— mdpal-cli
