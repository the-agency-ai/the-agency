---
type: commit
from: the-agency/jordan/mdslidepal-mac
to: the-agency/jordan/captain
date: 2026-08-07T13:57
status: created
priority: normal
subject: "Committed 9b04687c on mdslidepal-mac: test(mdslidepal-mac): add fixture 04 (images) coverage — all 8 contract fixtures now tested

Fixture 04 was present on disk but never registered in TestRunner's allTests,
so the images acceptance fixture silently went unrun — a pre-existing gap, not
a graft regression. The Phase 5.2 image-rendering work makes closing it due.

- Register fixture04_images; assert 3 slides, one block image each, relative
  sources preserved, and alt text retained on the deliberately-missing image
  (contract §11: placeholder, never silent skip).
- Add collectImages() AST walker helper.
- Ship the missing images/sample.png asset with the fixture so local path
  resolution has something real to resolve.
- Record the full-Xcode build prerequisite in the header: HighlightSwift's
  @Entry macro needs the SwiftUIMacros plugin, absent from CommandLineTools.

45 tests: 45 passed, 0 failed."
in_reply_to: null
---

# Committed 9b04687c on mdslidepal-mac: test(mdslidepal-mac): add fixture 04 (images) coverage — all 8 contract fixtures now tested

Fixture 04 was present on disk but never registered in TestRunner's allTests,
so the images acceptance fixture silently went unrun — a pre-existing gap, not
a graft regression. The Phase 5.2 image-rendering work makes closing it due.

- Register fixture04_images; assert 3 slides, one block image each, relative
  sources preserved, and alt text retained on the deliberately-missing image
  (contract §11: placeholder, never silent skip).
- Add collectImages() AST walker helper.
- Ship the missing images/sample.png asset with the fixture so local path
  resolution has something real to resolve.
- Record the full-Xcode build prerequisite in the header: HighlightSwift's
  @Entry macro needs the SwiftUIMacros plugin, absent from CommandLineTools.

45 tests: 45 passed, 0 failed.

## Commit: 9b04687c

**Branch:** mdslidepal-mac
**Agent:** the-agency/jordan/mdslidepal-mac
**Message:** housekeeping/captain: test(mdslidepal-mac): add fixture 04 (images) coverage — all 8 contract fixtures now tested

Fixture 04 was present on disk but never registered in TestRunner's allTests,
so the images acceptance fixture silently went unrun — a pre-existing gap, not
a graft regression. The Phase 5.2 image-rendering work makes closing it due.

- Register fixture04_images; assert 3 slides, one block image each, relative
  sources preserved, and alt text retained on the deliberately-missing image
  (contract §11: placeholder, never silent skip).
- Add collectImages() AST walker helper.
- Ship the missing images/sample.png asset with the fixture so local path
  resolution has something real to resolve.
- Record the full-Xcode build prerequisite in the header: HighlightSwift's
  @Entry macro needs the SwiftUIMacros plugin, absent from CommandLineTools.

45 tests: 45 passed, 0 failed.

### Metadata
- commit_hash: 9b04687c
- branch: mdslidepal-mac
- files_changed: 2
- stage: none
- stage_hash: none
- work_item: none

### Files Changed
```
src/apps/mdslidepal-mac/Tests/MdSlidepalTests/Fixtures/images/sample.png
src/apps/mdslidepal-mac/Tests/MdSlidepalTests/TestRunner.swift
```
