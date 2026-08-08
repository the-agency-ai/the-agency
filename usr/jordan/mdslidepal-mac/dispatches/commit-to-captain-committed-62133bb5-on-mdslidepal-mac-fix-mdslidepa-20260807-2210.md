---
type: commit
from: the-agency/jordan/mdslidepal-mac
to: the-agency/jordan/captain
date: 2026-08-07T14:10
status: created
priority: normal
subject: "Committed 62133bb5 on mdslidepal-mac: fix(mdslidepal-mac): QG fixes — image path containment, typography, HTML and color parsing

Quality gate on the Phase 5.1+5.2 graft. Eleven findings fixed; two
architectural regressions remain and are escalated to captain (see below).

Security / correctness:
- ImagePathResolver extracted from ImageBlockView. The contract §11 containment
  check was a bare string hasPrefix, so a sibling directory sharing a name
  prefix escaped it — a deck at .../Fixtures could read .../Fixtures-private.
  Now compares path components and resolves symlinks on both sides. 7 tests,
  including one that fails against the old implementation.
- Blockquote children were constructed without sourceURL, so every image nested
  in a blockquote rendered 'Invalid image path'. Threaded through.
- Unparseable per-slide 'background:' metadata painted the whole slide magenta.
  Added Color(validatingHex:) so untrusted input falls back to the theme;
  Color(hex:) keeps the magenta tell for broken themes. 3- and 8-digit CSS
  forms now parse, which is what surfaced this.

Rendering and performance:
- <br> was detected two different ways, one case-sensitive, so <BR> silently
  lost its line break. Unified in HTMLText with a case-insensitive rule.
- NSImage(contentsOf:) ran inside a view body, re-reading and re-decoding on
  every render pass. Moved behind LocalImageCache, keyed on path + mtime so
  live-reload still picks up edits.
- Image bounds were hardcoded 1680x700, contradicting Theme.swift's own 'no
  hardcoded sizes' contract and breaking non-16:9 themes. Derived from the
  theme's logical dimensions and padding.

Typography:
- FontResolver split into a testable resolution() and Font construction, since
  SwiftUI Font values do not compare usefully. AppKit registration probes are
  memoized instead of running per node per render. Made public so the app
  target and PDF export can share it. 7 tests.

Also: stale provenance headers updated on all changed files; 'var updated'
never-mutated warning fixed.

66 tests: 66 passed, 0 failed (was 45).

NOT ready for PR — two regressions from the graft's app-entry rewrite need a
scope decision: the Phase 3 presentation subsystem is unreachable, and the
Cmd-O open path bypasses security-scoped access and the file watcher."
in_reply_to: null
---

# Committed 62133bb5 on mdslidepal-mac: fix(mdslidepal-mac): QG fixes — image path containment, typography, HTML and color parsing

Quality gate on the Phase 5.1+5.2 graft. Eleven findings fixed; two
architectural regressions remain and are escalated to captain (see below).

Security / correctness:
- ImagePathResolver extracted from ImageBlockView. The contract §11 containment
  check was a bare string hasPrefix, so a sibling directory sharing a name
  prefix escaped it — a deck at .../Fixtures could read .../Fixtures-private.
  Now compares path components and resolves symlinks on both sides. 7 tests,
  including one that fails against the old implementation.
- Blockquote children were constructed without sourceURL, so every image nested
  in a blockquote rendered 'Invalid image path'. Threaded through.
- Unparseable per-slide 'background:' metadata painted the whole slide magenta.
  Added Color(validatingHex:) so untrusted input falls back to the theme;
  Color(hex:) keeps the magenta tell for broken themes. 3- and 8-digit CSS
  forms now parse, which is what surfaced this.

Rendering and performance:
- <br> was detected two different ways, one case-sensitive, so <BR> silently
  lost its line break. Unified in HTMLText with a case-insensitive rule.
- NSImage(contentsOf:) ran inside a view body, re-reading and re-decoding on
  every render pass. Moved behind LocalImageCache, keyed on path + mtime so
  live-reload still picks up edits.
- Image bounds were hardcoded 1680x700, contradicting Theme.swift's own 'no
  hardcoded sizes' contract and breaking non-16:9 themes. Derived from the
  theme's logical dimensions and padding.

Typography:
- FontResolver split into a testable resolution() and Font construction, since
  SwiftUI Font values do not compare usefully. AppKit registration probes are
  memoized instead of running per node per render. Made public so the app
  target and PDF export can share it. 7 tests.

Also: stale provenance headers updated on all changed files; 'var updated'
never-mutated warning fixed.

66 tests: 66 passed, 0 failed (was 45).

NOT ready for PR — two regressions from the graft's app-entry rewrite need a
scope decision: the Phase 3 presentation subsystem is unreachable, and the
Cmd-O open path bypasses security-scoped access and the file watcher.

## Commit: 62133bb5

**Branch:** mdslidepal-mac
**Agent:** the-agency/jordan/mdslidepal-mac
**Message:** housekeeping/captain: fix(mdslidepal-mac): QG fixes — image path containment, typography, HTML and color parsing

Quality gate on the Phase 5.1+5.2 graft. Eleven findings fixed; two
architectural regressions remain and are escalated to captain (see below).

Security / correctness:
- ImagePathResolver extracted from ImageBlockView. The contract §11 containment
  check was a bare string hasPrefix, so a sibling directory sharing a name
  prefix escaped it — a deck at .../Fixtures could read .../Fixtures-private.
  Now compares path components and resolves symlinks on both sides. 7 tests,
  including one that fails against the old implementation.
- Blockquote children were constructed without sourceURL, so every image nested
  in a blockquote rendered 'Invalid image path'. Threaded through.
- Unparseable per-slide 'background:' metadata painted the whole slide magenta.
  Added Color(validatingHex:) so untrusted input falls back to the theme;
  Color(hex:) keeps the magenta tell for broken themes. 3- and 8-digit CSS
  forms now parse, which is what surfaced this.

Rendering and performance:
- <br> was detected two different ways, one case-sensitive, so <BR> silently
  lost its line break. Unified in HTMLText with a case-insensitive rule.
- NSImage(contentsOf:) ran inside a view body, re-reading and re-decoding on
  every render pass. Moved behind LocalImageCache, keyed on path + mtime so
  live-reload still picks up edits.
- Image bounds were hardcoded 1680x700, contradicting Theme.swift's own 'no
  hardcoded sizes' contract and breaking non-16:9 themes. Derived from the
  theme's logical dimensions and padding.

Typography:
- FontResolver split into a testable resolution() and Font construction, since
  SwiftUI Font values do not compare usefully. AppKit registration probes are
  memoized instead of running per node per render. Made public so the app
  target and PDF export can share it. 7 tests.

Also: stale provenance headers updated on all changed files; 'var updated'
never-mutated warning fixed.

66 tests: 66 passed, 0 failed (was 45).

NOT ready for PR — two regressions from the graft's app-entry rewrite need a
scope decision: the Phase 3 presentation subsystem is unreachable, and the
Cmd-O open path bypasses security-scoped access and the file watcher.

### Metadata
- commit_hash: 62133bb5
- branch: mdslidepal-mac
- files_changed: 11
- stage: none
- stage_hash: none
- work_item: none

### Files Changed
```
src/apps/mdslidepal-mac/Sources/MdSlidepalLib/Model/Slide.swift
src/apps/mdslidepal-mac/Sources/MdSlidepalLib/Parser/SlideMetadataExtractor.swift
src/apps/mdslidepal-mac/Sources/MdSlidepalLib/Render/HTMLText.swift
src/apps/mdslidepal-mac/Sources/MdSlidepalLib/Render/ImageBlockView.swift
src/apps/mdslidepal-mac/Sources/MdSlidepalLib/Render/ImagePathResolver.swift
src/apps/mdslidepal-mac/Sources/MdSlidepalLib/Render/LocalImageCache.swift
src/apps/mdslidepal-mac/Sources/MdSlidepalLib/Render/SlideView.swift
src/apps/mdslidepal-mac/Sources/MdSlidepalLib/Theme/ColorHex.swift
src/apps/mdslidepal-mac/Sources/MdSlidepalLib/Theme/FontResolver.swift
src/apps/mdslidepal-mac/Tests/MdSlidepalTests/TestRunner.swift
usr/jordan/mdslidepal-mac/dispatches/commit-to-captain-committed-9b04687c-on-mdslidepal-mac-test-mdslidep-20260807-2157.md
```
