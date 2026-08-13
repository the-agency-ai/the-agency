---
type: commit
from: the-agency/jordan/designex-tool-tests
to: the-agency/jordan/captain
date: 2026-08-13T10:41
status: created
priority: normal
subject: "Committed e315beeb on designex-tool-tests: test(designex): bats coverage for figma-extract + designsystem-add (#138/#139)

Adds two hermetic bats suites (48 tests) for previously untested designex-owned
tools, plus two bug fixes found while testing.

- figma-extract.bats (27): arg/option validation, missing-token, API-error,
  dry-run, full extraction, RGBA->hex transform, dedup, font extraction,
  summary counts, token propagation, empty-document, idempotency. Live Figma
  API never contacted (secret-vault + curl stubbed, canned JSON fixtures).
- designsystem-add.bats (21): help/version, arg + name + version validation,
  structure creation, placeholder substitution, AGENT env, verbose, empty
  template, idempotency, missing-template.

Bug fixes in figma-extract (red->green):
- Published-style counts used grep -c (counts matching LINES); Figma returns
  minified single-line JSON so all counts collapsed to 0/1. Now grep -o | wc -l.
- extract_embedded_colors/fonts ended in a pipeline whose grep exits non-zero on
  a color-less/font-less document; under set -euo pipefail that aborted the
  whole tool. Added || true so empty documents extract cleanly.

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_0177dGznTbVpyWLvK9H3VjYq"
in_reply_to: null
---

# Committed e315beeb on designex-tool-tests: test(designex): bats coverage for figma-extract + designsystem-add (#138/#139)

Adds two hermetic bats suites (48 tests) for previously untested designex-owned
tools, plus two bug fixes found while testing.

- figma-extract.bats (27): arg/option validation, missing-token, API-error,
  dry-run, full extraction, RGBA->hex transform, dedup, font extraction,
  summary counts, token propagation, empty-document, idempotency. Live Figma
  API never contacted (secret-vault + curl stubbed, canned JSON fixtures).
- designsystem-add.bats (21): help/version, arg + name + version validation,
  structure creation, placeholder substitution, AGENT env, verbose, empty
  template, idempotency, missing-template.

Bug fixes in figma-extract (red->green):
- Published-style counts used grep -c (counts matching LINES); Figma returns
  minified single-line JSON so all counts collapsed to 0/1. Now grep -o | wc -l.
- extract_embedded_colors/fonts ended in a pipeline whose grep exits non-zero on
  a color-less/font-less document; under set -euo pipefail that aborted the
  whole tool. Added || true so empty documents extract cleanly.

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_0177dGznTbVpyWLvK9H3VjYq

## Commit: e315beeb

**Branch:** designex-tool-tests
**Agent:** the-agency/jordan/designex-tool-tests
**Message:** housekeeping/captain: test(designex): bats coverage for figma-extract + designsystem-add (#138/#139)

Adds two hermetic bats suites (48 tests) for previously untested designex-owned
tools, plus two bug fixes found while testing.

- figma-extract.bats (27): arg/option validation, missing-token, API-error,
  dry-run, full extraction, RGBA->hex transform, dedup, font extraction,
  summary counts, token propagation, empty-document, idempotency. Live Figma
  API never contacted (secret-vault + curl stubbed, canned JSON fixtures).
- designsystem-add.bats (21): help/version, arg + name + version validation,
  structure creation, placeholder substitution, AGENT env, verbose, empty
  template, idempotency, missing-template.

Bug fixes in figma-extract (red->green):
- Published-style counts used grep -c (counts matching LINES); Figma returns
  minified single-line JSON so all counts collapsed to 0/1. Now grep -o | wc -l.
- extract_embedded_colors/fonts ended in a pipeline whose grep exits non-zero on
  a color-less/font-less document; under set -euo pipefail that aborted the
  whole tool. Added || true so empty documents extract cleanly.

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_0177dGznTbVpyWLvK9H3VjYq

### Metadata
- commit_hash: e315beeb
- branch: designex-tool-tests
- files_changed: 4
- stage: none
- stage_hash: none
- work_item: none

### Files Changed
```
agency/tools/figma-extract
agency/workstreams/designex/qgr/the-agency-jordan-designex-designex-tool-tests-qgr-pr-prep-20260813-1838-7133425.md
src/tests/tools/designsystem-add.bats
src/tests/tools/figma-extract.bats
```
