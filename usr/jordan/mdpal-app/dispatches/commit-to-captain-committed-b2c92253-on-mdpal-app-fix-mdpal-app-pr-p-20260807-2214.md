---
type: commit
from: the-agency/jordan/mdpal-app
to: the-agency/jordan/captain
date: 2026-08-07T14:14
status: created
priority: normal
subject: "Committed b2c92253 on mdpal-app: fix(mdpal-app): pr-prep QG — silent-failure alert path, packageRequired retry, subprocess drain, mock/pancake parity

Quality gate over the full Phase 2.1-2.6 diff. 18 findings, 17 fixed here,
2 filed upstream, 1 accepted as not-a-defect.

Critical — the convert-to-package flow was unreachable. ContentView's alert
is presenting:-driven on lastAlert, but four SectionReaderView catch sites
and commitEdit wrote document.lastError directly. SwiftUI renders nothing
when presenting: is nil, so every pancake-mode .packageRequired failure —
i.e. every mutation the whole Phase 2.6 promote flow exists to serve —
looked to the user like the button simply did nothing. All five now route
through recordError.

High — pendingPackageOp was declared and consumed by promote() but never
assigned anywhere in the module, so even a reachable alert would have
dropped the user's original operation after conversion. recordError gains a
retry: parameter that parks the closure for .packageRequired only; parking
it for other errors would let a later unrelated promotion replay a stale op.

High — runMdpalCreate hand-rolled Process and called readDataToEndOfFile()
inside terminationHandler, draining one pipe fully before the other with no
cap: deadlock above the pipe buffer. Now goes through DefaultProcessRunner
(concurrent drain, 32 MiB cap), which is what that abstraction is for.

High — MockCLIService.editSection consulted only the canned Acme fixture
while listSections/readSection prefer the pushed document, so editing your
own file under MDPAL_MOCK=1 failed listing slugs you have never seen.

Also: removed a load-ordering race between MarkdownDocument.init and
ContentView's .task by pushing content synchronously at init; rejected
relative PATH entries in the binary resolver; sanitized the launch-failure
message that embeds the account name; deleted the dead CLIServiceBanner view
and pointed the live toolbar tooltips at Resolution.bannerMessage so that
copy has one tested source instead of two that drift; gave Mock's mutations
real slug/commentId validation so the notFound paths are reachable; widened
a 500ms scheduling-latency assertion that was a CI flake waiting to happen.

Filed to mdpal-cli as #887, not app-fixable: mdpal create has no
--content-stdin (whole document rides in argv, visible to ps, ARG_MAX-bound),
and no argument order gives the bundle subcommands a working -- position.
Both probed against the shipped binary; create's -- does work and is now used.

203 -> 221 tests, all green. Clean build, zero warnings."
in_reply_to: null
---

# Committed b2c92253 on mdpal-app: fix(mdpal-app): pr-prep QG — silent-failure alert path, packageRequired retry, subprocess drain, mock/pancake parity

Quality gate over the full Phase 2.1-2.6 diff. 18 findings, 17 fixed here,
2 filed upstream, 1 accepted as not-a-defect.

Critical — the convert-to-package flow was unreachable. ContentView's alert
is presenting:-driven on lastAlert, but four SectionReaderView catch sites
and commitEdit wrote document.lastError directly. SwiftUI renders nothing
when presenting: is nil, so every pancake-mode .packageRequired failure —
i.e. every mutation the whole Phase 2.6 promote flow exists to serve —
looked to the user like the button simply did nothing. All five now route
through recordError.

High — pendingPackageOp was declared and consumed by promote() but never
assigned anywhere in the module, so even a reachable alert would have
dropped the user's original operation after conversion. recordError gains a
retry: parameter that parks the closure for .packageRequired only; parking
it for other errors would let a later unrelated promotion replay a stale op.

High — runMdpalCreate hand-rolled Process and called readDataToEndOfFile()
inside terminationHandler, draining one pipe fully before the other with no
cap: deadlock above the pipe buffer. Now goes through DefaultProcessRunner
(concurrent drain, 32 MiB cap), which is what that abstraction is for.

High — MockCLIService.editSection consulted only the canned Acme fixture
while listSections/readSection prefer the pushed document, so editing your
own file under MDPAL_MOCK=1 failed listing slugs you have never seen.

Also: removed a load-ordering race between MarkdownDocument.init and
ContentView's .task by pushing content synchronously at init; rejected
relative PATH entries in the binary resolver; sanitized the launch-failure
message that embeds the account name; deleted the dead CLIServiceBanner view
and pointed the live toolbar tooltips at Resolution.bannerMessage so that
copy has one tested source instead of two that drift; gave Mock's mutations
real slug/commentId validation so the notFound paths are reachable; widened
a 500ms scheduling-latency assertion that was a CI flake waiting to happen.

Filed to mdpal-cli as #887, not app-fixable: mdpal create has no
--content-stdin (whole document rides in argv, visible to ps, ARG_MAX-bound),
and no argument order gives the bundle subcommands a working -- position.
Both probed against the shipped binary; create's -- does work and is now used.

203 -> 221 tests, all green. Clean build, zero warnings.

## Commit: b2c92253

**Branch:** mdpal-app
**Agent:** the-agency/jordan/mdpal-app
**Message:** housekeeping/captain: fix(mdpal-app): pr-prep QG — silent-failure alert path, packageRequired retry, subprocess drain, mock/pancake parity

Quality gate over the full Phase 2.1-2.6 diff. 18 findings, 17 fixed here,
2 filed upstream, 1 accepted as not-a-defect.

Critical — the convert-to-package flow was unreachable. ContentView's alert
is presenting:-driven on lastAlert, but four SectionReaderView catch sites
and commitEdit wrote document.lastError directly. SwiftUI renders nothing
when presenting: is nil, so every pancake-mode .packageRequired failure —
i.e. every mutation the whole Phase 2.6 promote flow exists to serve —
looked to the user like the button simply did nothing. All five now route
through recordError.

High — pendingPackageOp was declared and consumed by promote() but never
assigned anywhere in the module, so even a reachable alert would have
dropped the user's original operation after conversion. recordError gains a
retry: parameter that parks the closure for .packageRequired only; parking
it for other errors would let a later unrelated promotion replay a stale op.

High — runMdpalCreate hand-rolled Process and called readDataToEndOfFile()
inside terminationHandler, draining one pipe fully before the other with no
cap: deadlock above the pipe buffer. Now goes through DefaultProcessRunner
(concurrent drain, 32 MiB cap), which is what that abstraction is for.

High — MockCLIService.editSection consulted only the canned Acme fixture
while listSections/readSection prefer the pushed document, so editing your
own file under MDPAL_MOCK=1 failed listing slugs you have never seen.

Also: removed a load-ordering race between MarkdownDocument.init and
ContentView's .task by pushing content synchronously at init; rejected
relative PATH entries in the binary resolver; sanitized the launch-failure
message that embeds the account name; deleted the dead CLIServiceBanner view
and pointed the live toolbar tooltips at Resolution.bannerMessage so that
copy has one tested source instead of two that drift; gave Mock's mutations
real slug/commentId validation so the notFound paths are reachable; widened
a 500ms scheduling-latency assertion that was a CI flake waiting to happen.

Filed to mdpal-cli as #887, not app-fixable: mdpal create has no
--content-stdin (whole document rides in argv, visible to ps, ARG_MAX-bound),
and no argument order gives the bundle subcommands a working -- position.
Both probed against the shipped binary; create's -- does work and is now used.

203 -> 221 tests, all green. Clean build, zero warnings.

### Metadata
- commit_hash: b2c92253
- branch: mdpal-app
- files_changed: 11
- stage: none
- stage_hash: none
- work_item: none

### Files Changed
```
src/apps/mdpal-app/Sources/MarkdownPalApp/Models/DocumentModel.swift
src/apps/mdpal-app/Sources/MarkdownPalApp/Services/CLIProcess.swift
src/apps/mdpal-app/Sources/MarkdownPalApp/Services/MockCLIService.swift
src/apps/mdpal-app/Sources/MarkdownPalApp/Services/RealCLIService.swift
src/apps/mdpal-app/Sources/MarkdownPalApp/Views/CLIServiceBanner.swift
src/apps/mdpal-app/Sources/MarkdownPalApp/Views/ContentView.swift
src/apps/mdpal-app/Sources/MarkdownPalApp/Views/MarkdownDocument.swift
src/apps/mdpal-app/Sources/MarkdownPalApp/Views/SectionReaderView.swift
src/apps/mdpal-app/Tests/MarkdownPalAppTests/ModelTests.swift
usr/jordan/mdpal-app/dispatches/commit-to-captain-committed-51fde004-on-mdpal-app-fix-mdpal-app-graf-20260807-2159.md
usr/jordan/mdpal-app/dispatches/dispatch-to-mdpal-cli-pr-prep-qg-findings-mdpal-create-needs-content-std-20260807-2213.md
```
