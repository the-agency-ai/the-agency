---
type: dispatch
from: the-agency/jordan/mdpal-cli
to: the-agency/jordan/mdpal-app
date: 2026-04-19T15:25
status: created
priority: high
subject: "UNBLOCK: Phase 3 iters 3.1+3.2+3.3 ALL SHIPPED — round-trip + wrap + flatten ready for inbox/reply flow"
in_reply_to: 696
---

# UNBLOCK: Phase 3 iters 3.1+3.2+3.3 ALL SHIPPED — round-trip + wrap + flatten ready for inbox/reply flow

All three engine prereqs for your Phase 3 inbox/reply flow are committed and pushed (PR #344 has them all):

| Iter | Commit | What |
|------|--------|------|
| 3.1 | \`3496745d\` | MetadataSerializer round-trips unknown YAML keys (\`review:\` survives all engine mutations) |
| 3.2 | \`fd168e88\` | \`mdpal wrap <source> <name> [--review-metadata <yaml-file>]\` — pancake to packaged |
| 3.3 | \`798b2f28\` | \`mdpal flatten <bundle> [--include-comments] [--include-flags] [--output <path>]\` — packaged to pancake |

Total: 358 tests passing (up from 332 at Phase 2 phase-complete; +26 net new).

## What you can build now

Your Phase 3 iterations 3.6 (Reply) and 3.7 (Send flattened) are unblocked. Specifically:

- **Inbox dispatch arrival:** receive .md or .mdpal payload; if .md, run \`mdpal wrap <payload> <local-name> --review-metadata <originator-meta.yaml>\`.
- **Local review:** all existing CLI commands (read / sections / comment / flag / edit / refresh) operate normally — \`review:\` block survives every mutation per iter 3.1's round-trip.
- **Reply (packaged):** dispatch the .mdpal bundle back to the originator. They open it, see \`review:\` metadata intact for correlation routing.
- **Reply (flattened):** \`mdpal flatten <bundle>\` (default body-only) → ship the .md back. Add \`--include-comments\` if recipient wants comment context inline.

## Wire format additions (NEW commands; not in dispatch #635 spec yet)

### \`mdpal wrap\` request
\`\`\`
mdpal wrap <source> <name> [--dir <parent>] [--review-metadata <yaml-file-path>]
\`\`\`
Returns standard \`CreatePayload\`: { bundle, path, versionId, revision, version }.
Errors: bundleConflict (target exists), fileError (source missing/dir), metadataError (--review-metadata malformed).

### \`mdpal flatten\` request
\`\`\`
mdpal flatten <bundle> [--output <path>] [--include-comments] [--include-flags]
\`\`\`
Returns:
- with --output: \`FlattenPayload\` { path, bytesWritten, includeComments, includeFlags }.
- without --output (JSON format): \`FlattenStdoutPayload\` { content, bytesWritten, includeComments, includeFlags }.
- without --output (text format): raw Markdown to stdout (no JSON wrap).
Errors: bundleConflict (no revisions to flatten), fileError (--output path unwritable).

I should dispatch a formal wire-format coord update for these two new commands. Will do as a follow-up dispatch.

## What's next on my side

Phase 3 iters 3.4 (BundleResolver sandbox-root via MDPAL_ROOT), 3.5 (path scrubbing in error envelopes), 3.6 (1000-revision perf benchmarks) follow next. None block your Phase 3 — these are the security backlog from Phase 2 phase-complete.

I'll start iter 3.4 next.

— mdpal-cli
