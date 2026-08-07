---
type: commit
from: the-agency/jordan/mdpal-app
to: the-agency/jordan/captain
date: 2026-08-07T13:59
status: created
priority: normal
subject: "Committed 51fde004 on mdpal-app: fix(mdpal-app): graft coherence — host-independent CLI fallback test, Swift 6 async-lock safety, stale banner assertions

Post-graft verification of the Phase 2.1-2.6 replay surfaced three real
test failures and a class of Swift 6 blocking warnings:

- CLIServiceFactory.make() had no fallbacks: injection point, so the
  CLI-missing fallback path resolved /opt/homebrew/bin/mdpal on any host
  with the CLI installed and never exercised MockCLIService. Added the
  parameter (mirrors RealCLIService.init) and pinned the test to [].
- MockCLIService + PancakeCLIService called NSLock.lock()/unlock()
  directly inside async functions — a hard error in the Swift 6 language
  mode. Moved every critical section into synchronous snapshot helpers.
  Also fixes an unsynchronized read of contentHash in showVersion.
- Two Phase 1C.1 banner assertions encoded pre-Phase-2 copy. Rewritten to
  assert intent (case-insensitive mock-mode signal, verbatim diagnostic
  reason, banner title) rather than exact strings.

203/203 tests green, clean build with zero warnings."
in_reply_to: null
---

# Committed 51fde004 on mdpal-app: fix(mdpal-app): graft coherence — host-independent CLI fallback test, Swift 6 async-lock safety, stale banner assertions

Post-graft verification of the Phase 2.1-2.6 replay surfaced three real
test failures and a class of Swift 6 blocking warnings:

- CLIServiceFactory.make() had no fallbacks: injection point, so the
  CLI-missing fallback path resolved /opt/homebrew/bin/mdpal on any host
  with the CLI installed and never exercised MockCLIService. Added the
  parameter (mirrors RealCLIService.init) and pinned the test to [].
- MockCLIService + PancakeCLIService called NSLock.lock()/unlock()
  directly inside async functions — a hard error in the Swift 6 language
  mode. Moved every critical section into synchronous snapshot helpers.
  Also fixes an unsynchronized read of contentHash in showVersion.
- Two Phase 1C.1 banner assertions encoded pre-Phase-2 copy. Rewritten to
  assert intent (case-insensitive mock-mode signal, verbatim diagnostic
  reason, banner title) rather than exact strings.

203/203 tests green, clean build with zero warnings.

## Commit: 51fde004

**Branch:** mdpal-app
**Agent:** the-agency/jordan/mdpal-app
**Message:** housekeeping/captain: fix(mdpal-app): graft coherence — host-independent CLI fallback test, Swift 6 async-lock safety, stale banner assertions

Post-graft verification of the Phase 2.1-2.6 replay surfaced three real
test failures and a class of Swift 6 blocking warnings:

- CLIServiceFactory.make() had no fallbacks: injection point, so the
  CLI-missing fallback path resolved /opt/homebrew/bin/mdpal on any host
  with the CLI installed and never exercised MockCLIService. Added the
  parameter (mirrors RealCLIService.init) and pinned the test to [].
- MockCLIService + PancakeCLIService called NSLock.lock()/unlock()
  directly inside async functions — a hard error in the Swift 6 language
  mode. Moved every critical section into synchronous snapshot helpers.
  Also fixes an unsynchronized read of contentHash in showVersion.
- Two Phase 1C.1 banner assertions encoded pre-Phase-2 copy. Rewritten to
  assert intent (case-insensitive mock-mode signal, verbatim diagnostic
  reason, banner title) rather than exact strings.

203/203 tests green, clean build with zero warnings.

### Metadata
- commit_hash: 51fde004
- branch: mdpal-app
- files_changed: 4
- stage: none
- stage_hash: none
- work_item: none

### Files Changed
```
src/apps/mdpal-app/Sources/MarkdownPalApp/Services/CLIServiceFactory.swift
src/apps/mdpal-app/Sources/MarkdownPalApp/Services/MockCLIService.swift
src/apps/mdpal-app/Sources/MarkdownPalApp/Services/PancakeCLIService.swift
src/apps/mdpal-app/Tests/MarkdownPalAppTests/ModelTests.swift
```
