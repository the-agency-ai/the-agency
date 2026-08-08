---
type: commit
from: the-agency/jordan/mdslidepal-mac
to: the-agency/jordan/captain
date: 2026-08-08T02:15
status: created
priority: normal
subject: "Committed 8037ac63 on mdslidepal-mac: fix(mdslidepal-mac): reconnect Phase 3 presentation, unify the document lifecycle

Resolves the two regressions the graft's app-entry rewrite introduced when it
replaced the SwiftUI App/Scene with a manual NSApplication delegate and did not
re-wire what the Scene had provided. Per principal: fix, do not delete.

Phase 3 presentation restored:
- New PresentationWindowManager supplies the missing AppKit half. The coordinator
  tracked state and PresenterWindowView/AudienceFullScreenView knew how to draw
  it, but nothing ever created the windows. Present (⌘P) now opens an audience
  window on the external display and a presenter window on the built-in one,
  falling back to audience-only on a single display.
- The audience window raises its level and hides the Dock and menu bar rather
  than calling toggleFullScreen, which AppKit ignores on a borderless window —
  the earlier approach left the menu bar drawn over the slides.
- Teardown hangs off PresentationCoordinator.onPresentationEnded, so Escape, the
  presenter's End button, the menu and the presenter's close box all converge on
  one path that runs once.

One owner for the document lifecycle:
- New DeckController owns open/reload/export/watch. The delegate and
  DeckWindowView each had their own copy and they had diverged: the delegate's
  path called neither startAccessingSecurityScopedResource() nor FileWatcher, so
  ⌘O-opened files never live-reloaded.
- Security-scoped access is now held for the document's lifetime, not released
  at the end of the load, and a failed open no longer revokes access to the
  document that stays loaded and watched.
- The six NotificationCenter observers DeckWindowView registered and never
  removed now live on the controller, which subscribes once and cleans up.
- Window title is observation-driven; setting it per call site missed
  drag-and-drop, the file importer and every watcher reload.

Also fixed while here: .startPresentation no longer bypasses the window manager
(it could leave the coordinator presenting with nothing on screen while its key
monitor swallowed Escape); presentation windows re-read the theme instead of
snapshotting it; drag-and-drop opens one file instead of racing several and
reports unhandled drops honestly; removed the inert navigationTitle, the
duplicate ⌘O binding, an unused AppKit import, and DeckState.isPresenting, which
nothing wrote.

AppMenuCommands is retained per instruction and documented: its Notification
vocabulary is live, but the Commands struct itself cannot attach without a
SwiftUI Scene, which SPM executables cannot use.

75 tests: 75 passed, 0 failed (was 66). Zero build warnings."
in_reply_to: null
---

# Committed 8037ac63 on mdslidepal-mac: fix(mdslidepal-mac): reconnect Phase 3 presentation, unify the document lifecycle

Resolves the two regressions the graft's app-entry rewrite introduced when it
replaced the SwiftUI App/Scene with a manual NSApplication delegate and did not
re-wire what the Scene had provided. Per principal: fix, do not delete.

Phase 3 presentation restored:
- New PresentationWindowManager supplies the missing AppKit half. The coordinator
  tracked state and PresenterWindowView/AudienceFullScreenView knew how to draw
  it, but nothing ever created the windows. Present (⌘P) now opens an audience
  window on the external display and a presenter window on the built-in one,
  falling back to audience-only on a single display.
- The audience window raises its level and hides the Dock and menu bar rather
  than calling toggleFullScreen, which AppKit ignores on a borderless window —
  the earlier approach left the menu bar drawn over the slides.
- Teardown hangs off PresentationCoordinator.onPresentationEnded, so Escape, the
  presenter's End button, the menu and the presenter's close box all converge on
  one path that runs once.

One owner for the document lifecycle:
- New DeckController owns open/reload/export/watch. The delegate and
  DeckWindowView each had their own copy and they had diverged: the delegate's
  path called neither startAccessingSecurityScopedResource() nor FileWatcher, so
  ⌘O-opened files never live-reloaded.
- Security-scoped access is now held for the document's lifetime, not released
  at the end of the load, and a failed open no longer revokes access to the
  document that stays loaded and watched.
- The six NotificationCenter observers DeckWindowView registered and never
  removed now live on the controller, which subscribes once and cleans up.
- Window title is observation-driven; setting it per call site missed
  drag-and-drop, the file importer and every watcher reload.

Also fixed while here: .startPresentation no longer bypasses the window manager
(it could leave the coordinator presenting with nothing on screen while its key
monitor swallowed Escape); presentation windows re-read the theme instead of
snapshotting it; drag-and-drop opens one file instead of racing several and
reports unhandled drops honestly; removed the inert navigationTitle, the
duplicate ⌘O binding, an unused AppKit import, and DeckState.isPresenting, which
nothing wrote.

AppMenuCommands is retained per instruction and documented: its Notification
vocabulary is live, but the Commands struct itself cannot attach without a
SwiftUI Scene, which SPM executables cannot use.

75 tests: 75 passed, 0 failed (was 66). Zero build warnings.

## Commit: 8037ac63

**Branch:** mdslidepal-mac
**Agent:** the-agency/jordan/mdslidepal-mac
**Message:** housekeeping/captain: fix(mdslidepal-mac): reconnect Phase 3 presentation, unify the document lifecycle

Resolves the two regressions the graft's app-entry rewrite introduced when it
replaced the SwiftUI App/Scene with a manual NSApplication delegate and did not
re-wire what the Scene had provided. Per principal: fix, do not delete.

Phase 3 presentation restored:
- New PresentationWindowManager supplies the missing AppKit half. The coordinator
  tracked state and PresenterWindowView/AudienceFullScreenView knew how to draw
  it, but nothing ever created the windows. Present (⌘P) now opens an audience
  window on the external display and a presenter window on the built-in one,
  falling back to audience-only on a single display.
- The audience window raises its level and hides the Dock and menu bar rather
  than calling toggleFullScreen, which AppKit ignores on a borderless window —
  the earlier approach left the menu bar drawn over the slides.
- Teardown hangs off PresentationCoordinator.onPresentationEnded, so Escape, the
  presenter's End button, the menu and the presenter's close box all converge on
  one path that runs once.

One owner for the document lifecycle:
- New DeckController owns open/reload/export/watch. The delegate and
  DeckWindowView each had their own copy and they had diverged: the delegate's
  path called neither startAccessingSecurityScopedResource() nor FileWatcher, so
  ⌘O-opened files never live-reloaded.
- Security-scoped access is now held for the document's lifetime, not released
  at the end of the load, and a failed open no longer revokes access to the
  document that stays loaded and watched.
- The six NotificationCenter observers DeckWindowView registered and never
  removed now live on the controller, which subscribes once and cleans up.
- Window title is observation-driven; setting it per call site missed
  drag-and-drop, the file importer and every watcher reload.

Also fixed while here: .startPresentation no longer bypasses the window manager
(it could leave the coordinator presenting with nothing on screen while its key
monitor swallowed Escape); presentation windows re-read the theme instead of
snapshotting it; drag-and-drop opens one file instead of racing several and
reports unhandled drops honestly; removed the inert navigationTitle, the
duplicate ⌘O binding, an unused AppKit import, and DeckState.isPresenting, which
nothing wrote.

AppMenuCommands is retained per instruction and documented: its Notification
vocabulary is live, but the Commands struct itself cannot attach without a
SwiftUI Scene, which SPM executables cannot use.

75 tests: 75 passed, 0 failed (was 66). Zero build warnings.

### Metadata
- commit_hash: 8037ac63
- branch: mdslidepal-mac
- files_changed: 9
- stage: none
- stage_hash: none
- work_item: none

### Files Changed
```
src/apps/mdslidepal-mac/Sources/MdSlidepal/App/MdSlidepalApp.swift
src/apps/mdslidepal-mac/Sources/MdSlidepalLib/App/DeckController.swift
src/apps/mdslidepal-mac/Sources/MdSlidepalLib/App/PresentationCoordinator.swift
src/apps/mdslidepal-mac/Sources/MdSlidepalLib/App/PresentationWindowManager.swift
src/apps/mdslidepal-mac/Sources/MdSlidepalLib/Model/DeckDocument.swift
src/apps/mdslidepal-mac/Sources/MdSlidepalLib/UI/AppCommands.swift
src/apps/mdslidepal-mac/Sources/MdSlidepalLib/UI/DeckWindowView.swift
src/apps/mdslidepal-mac/Tests/MdSlidepalTests/TestRunner.swift
usr/jordan/mdslidepal-mac/dispatches/commit-to-captain-committed-62133bb5-on-mdslidepal-mac-fix-mdslidepa-20260807-2210.md
```
