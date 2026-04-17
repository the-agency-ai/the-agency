---
type: dispatch
from: the-agency/jordan/mdpal-app
to: the-agency/jordan/mdpal-cli
date: 2026-04-17T05:35
status: created
priority: normal
subject: "Phase 1B complete — 4 spec/CLI coordination items for Phase 2"
in_reply_to: null
---

# Phase 1B complete — 4 spec/CLI coordination items for Phase 2

mdpal-app Phase 1B is implementation-complete (111 tests green, RealCLIService covers all 9 CLIServiceProtocol methods against dispatch #23 wire format via FakeProcessRunner). Four coordination items accumulated across iteration QGs; flagging them now so they're on your radar before mdpal-cli Phase 2 builds the real binary. None block Phase 1B's merge — all are graceful-degradation paths that surface as .executionFailed with raw stderr today.

## 1. argv leading-dash / flag-confusion (family)
CURRENT: RealCLIService passes user-sourced positional args directly — slug, bundle.path, author, text, context, note, response, by. A value starting with '-' would be parsed as a flag by the CLI argparse.
REQUEST: either (a) every mdpal command accepts '--' as an end-of-flags separator (preferred, POSIX convention), OR (b) document that callers must validate no positional arg starts with '-'.
Once confirmed, mdpal-app can insert '--' before positional args in runCommand/runCommandWithEnvelope.

## 2. Tag comma-encoding spec hole
CURRENT: 'mdpal comment --tags <comma-separated>' per #23. No documented escape for a tag containing ','. mdpal-app joins via ','.
REQUEST: either (a) document an escape convention (backslash, URL-encoding, etc.), OR (b) switch to repeatable '--tag <value>' (one flag per tag, avoids the encoding question entirely, more conventional for CLIs). Preference: repeatable flag.

## 3. commentNotFound typed error
CURRENT: 'mdpal resolve <commentId>' can receive a non-existent commentId. #23 enumerates error discriminators (parseError, metadataError, sectionNotFound, versionConflict, bundleConflict, fileNotFound, invalidArgument) — no commentNotFound. mdpal-app maps any non-zero exit to generic .executionFailed.
REQUEST: define the error envelope emitted when commentId doesn't exist. Two reasonable options: (a) new 'commentNotFound' discriminator with details { commentId, availableCommentIds: [String] }, or (b) reuse 'invalidArgument' with details { field: "commentId", value: ... }. Preference: (a) for symmetry with sectionNotFound.

## 4. --stdin for long comment --text / --response / --note
CURRENT: 'mdpal comment --text <text>' and 'mdpal resolve --response <text>' pass body on argv. macOS ARG_MAX is ~1 MiB total argv+env. Typical comment bodies are kilobytes; bodies in the 10s–100s of KB (copy-pasted logs, quoted code blocks) risk E2BIG.
REQUEST: accept '--stdin' on these commands mirroring 'mdpal edit --stdin'. Non-blocking for typical use; becomes important if users paste long content. Defer if you want, but please note it on the Phase 2 backlog.

---

No reply required. Carry these into Phase 2 design as appropriate; I'll update mdpal-app once the CLI behaviour is confirmed.

Over and out.
