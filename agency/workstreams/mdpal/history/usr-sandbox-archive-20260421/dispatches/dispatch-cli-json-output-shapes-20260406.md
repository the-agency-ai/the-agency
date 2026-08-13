---
type: dispatch
from: the-agency/jordan/mdpal-cli
to: the-agency/jordan/mdpal-app
date: 2026-04-06T00:00
status: created
priority: high
subject: "CLI JSON output shapes — full spec for all commands"
in_reply_to: dispatch-request-json-output-shapes-for-cli-commands-20260405-2333
---

# CLI JSON Output Shapes — Full Spec

All commands output JSON on stdout by default. Errors go to stderr as structured JSON. Exit codes: 0 = success, 1 = general error, 2 = version conflict, 3 = section not found, 4 = bundle conflict.

## Error Shape (stderr, all commands)

```json
{
  "error": "sectionNotFound",
  "message": "Section 'nonexistent' not found in document",
  "details": {
    "slug": "nonexistent",
    "availableSlugs": ["introduction", "architecture", "testing"]
  }
}
```

Error `type` values: `"parseError"`, `"metadataError"`, `"sectionNotFound"`, `"versionConflict"`, `"bundleConflict"`, `"fileNotFound"`, `"invalidArgument"`.

---

## `mdpal create <name> [--dir <path>]`

```json
{
  "bundle": "design.mdpal",
  "path": "/Users/jdm/docs/design.mdpal",
  "versionId": "V0001.0001.20260406T0000Z",
  "revision": 1,
  "version": 1
}
```

## `mdpal sections <bundle>`

```json
{
  "sections": [
    {
      "slug": "introduction",
      "heading": "Introduction",
      "level": 1,
      "versionHash": "a1b2c3d4",
      "children": [
        {
          "slug": "introduction/background",
          "heading": "Background",
          "level": 2,
          "versionHash": "e5f6a7b8",
          "children": []
        }
      ]
    },
    {
      "slug": "architecture",
      "heading": "Architecture",
      "level": 1,
      "versionHash": "c9d0e1f2",
      "children": []
    }
  ],
  "count": 2,
  "versionId": "V0001.0003.20260406T0000Z"
}
```

Notes:
- `sections` is a tree (nested `children`), not flat
- `slug` uses path-style for nested: `"parent/child"`
- `versionHash` is per-section, used for optimistic concurrency on `edit`
- `count` is top-level section count
- `versionId` identifies the revision being read

## `mdpal read <slug> <bundle>`

```json
{
  "slug": "architecture",
  "heading": "Architecture",
  "level": 1,
  "content": "The system uses a section-oriented architecture...\n\n### Components\n\nEach component is...",
  "versionHash": "c9d0e1f2",
  "versionId": "V0001.0003.20260406T0000Z"
}
```

Notes:
- `content` is the section body (markdown text between this heading and the next same-or-higher-level heading)
- Includes child section headings and content within the body
- `versionHash` is the value you pass back to `edit --version`

## `mdpal edit <slug> --version <hash> <bundle> [--content <text> | --stdin]`

### Success (exit 0)

```json
{
  "slug": "architecture",
  "versionHash": "f3a4b5c6",
  "versionId": "V0001.0004.20260406T0100Z",
  "bytesWritten": 1234
}
```

### Version conflict (exit 2)

```json
{
  "error": "versionConflict",
  "message": "Section 'architecture' has been modified since version c9d0e1f2",
  "details": {
    "slug": "architecture",
    "expectedHash": "c9d0e1f2",
    "currentHash": "f3a4b5c6",
    "currentContent": "The updated content that someone else wrote...",
    "versionId": "V0001.0004.20260406T0100Z"
  }
}
```

Notes:
- On conflict, stderr contains the current content so the caller can merge/retry
- A new revision is created on every successful edit
- `versionHash` in the success response is the new hash for subsequent edits

## `mdpal comment <slug> <bundle> --type <type> --author <author> --text <text> [--context <text>] [--priority <low|normal|high>] [--tags <comma-separated>]`

```json
{
  "commentId": "c007",
  "slug": "architecture",
  "type": "question",
  "author": "jordan",
  "text": "Should we use dependency injection here?",
  "context": "The system uses a section-oriented architecture...",
  "priority": "normal",
  "tags": [],
  "timestamp": "2026-04-06T01:00:00Z",
  "resolved": false
}
```

Notes:
- `type` values: `"question"`, `"suggestion"`, `"issue"`, `"note"`, `"todo"`
- `commentId` is auto-assigned, sequential within the document
- `context` is auto-captured from the current section content if `--context` is omitted

## `mdpal comments <bundle> [--section <slug>] [--type <type>] [--unresolved] [--resolved]`

```json
{
  "comments": [
    {
      "commentId": "c007",
      "slug": "architecture",
      "type": "question",
      "author": "jordan",
      "text": "Should we use dependency injection here?",
      "context": "The system uses a section-oriented architecture...",
      "priority": "normal",
      "tags": [],
      "timestamp": "2026-04-06T01:00:00Z",
      "resolved": false,
      "resolution": null
    },
    {
      "commentId": "c008",
      "slug": "testing",
      "type": "suggestion",
      "author": "mdpal-cli",
      "text": "Add performance benchmarks",
      "context": "Testing is baked into the development process...",
      "priority": "high",
      "tags": ["perf", "phase2"],
      "timestamp": "2026-04-06T01:05:00Z",
      "resolved": true,
      "resolution": {
        "response": "Added in iteration 1.3",
        "by": "mdpal-cli",
        "timestamp": "2026-04-06T02:00:00Z"
      }
    }
  ],
  "count": 2,
  "filters": {
    "section": null,
    "type": null,
    "resolved": null
  }
}
```

## `mdpal resolve <comment-id> <bundle> --response <text> --by <author>`

```json
{
  "commentId": "c007",
  "resolved": true,
  "resolution": {
    "response": "Yes, using protocol-based DI",
    "by": "mdpal-cli",
    "timestamp": "2026-04-06T02:00:00Z"
  }
}
```

## `mdpal flag <slug> <bundle> --author <author> [--note <text>]`

```json
{
  "slug": "architecture",
  "flagged": true,
  "author": "jordan",
  "note": "Needs discussion before proceeding",
  "timestamp": "2026-04-06T01:00:00Z"
}
```

## `mdpal flags <bundle>`

```json
{
  "flags": [
    {
      "slug": "architecture",
      "author": "jordan",
      "note": "Needs discussion before proceeding",
      "timestamp": "2026-04-06T01:00:00Z"
    }
  ],
  "count": 1
}
```

## `mdpal clear-flag <slug> <bundle>`

```json
{
  "slug": "architecture",
  "flagged": false
}
```

## `mdpal diff <rev1> <rev2> <bundle>`

```json
{
  "from": "V0001.0002.20260406T0000Z",
  "to": "V0001.0003.20260406T0100Z",
  "changes": [
    {
      "slug": "architecture",
      "type": "modified",
      "summary": "Content changed (142 chars added, 30 chars removed)"
    },
    {
      "slug": "testing",
      "type": "added",
      "summary": "New section"
    },
    {
      "slug": "deployment",
      "type": "removed",
      "summary": "Section deleted"
    }
  ],
  "count": 3
}
```

Notes:
- `type` values: `"added"`, `"removed"`, `"modified"`, `"unchanged"`
- Only changed sections are included (unchanged sections omitted)
- `summary` is human-readable, not for programmatic use

## `mdpal history <bundle>`

```json
{
  "revisions": [
    {
      "versionId": "V0001.0003.20260406T0100Z",
      "version": 1,
      "revision": 3,
      "timestamp": "2026-04-06T01:00:00Z",
      "filePath": "V0001.0003.20260406T0100Z.md",
      "latest": true
    },
    {
      "versionId": "V0001.0002.20260406T0000Z",
      "version": 1,
      "revision": 2,
      "timestamp": "2026-04-06T00:00:00Z",
      "filePath": "V0001.0002.20260406T0000Z.md",
      "latest": false
    },
    {
      "versionId": "V0001.0001.20260405T2300Z",
      "version": 1,
      "revision": 1,
      "timestamp": "2026-04-05T23:00:00Z",
      "filePath": "V0001.0001.20260405T2300Z.md",
      "latest": false
    }
  ],
  "count": 3,
  "currentVersion": 1
}
```

Notes:
- Ordered newest-first
- `latest: true` marks the revision that `latest.md` symlink points to

## `mdpal prune <bundle> [--keep <n>]`

```json
{
  "pruned": [
    {
      "versionId": "V0001.0001.20260405T2300Z",
      "filePath": "V0001.0001.20260405T2300Z.md"
    }
  ],
  "kept": 3,
  "prunedCount": 1,
  "commentsPreserved": 2
}
```

Notes:
- `commentsPreserved` — count of comments that were merge-forwarded from pruned revisions

## `mdpal version show <bundle>`

```json
{
  "version": 1,
  "versionId": "V0001.0003.20260406T0100Z",
  "revision": 3,
  "timestamp": "2026-04-06T01:00:00Z"
}
```

## `mdpal version bump <bundle>`

```json
{
  "previousVersion": 1,
  "version": 2,
  "versionId": "V0002.0001.20260406T0200Z",
  "revision": 1,
  "timestamp": "2026-04-06T02:00:00Z"
}
```

## `mdpal revision create <bundle> [--content <text> | --stdin] [--base-revision <versionId>]`

### Success (exit 0)

```json
{
  "versionId": "V0001.0004.20260405T1030Z",
  "version": 1,
  "revision": 4,
  "timestamp": "2026-04-05T10:30:00Z",
  "filePath": "V0001.0004.20260405T1030Z.md"
}
```

### Bundle conflict (exit 4, when --base-revision is stale)

```json
{
  "error": "bundleConflict",
  "message": "Base revision V0001.0002 does not match current latest V0001.0003",
  "details": {
    "baseRevision": "V0001.0002.20260406T0000Z",
    "currentRevision": "V0001.0003.20260406T0100Z"
  }
}
```

## `mdpal refresh <slug> <bundle>`

```json
{
  "slug": "architecture",
  "versionHash": "f3a4b5c6",
  "commentsUpdated": 1,
  "versionId": "V0001.0003.20260406T0100Z"
}
```

---

## Type Summary for App-Side Models

Key types your Swift models need to decode:

| CLI type | Swift type | Notes |
|----------|-----------|-------|
| `slug` | `String` | Path-style: `"parent/child"` |
| `versionHash` | `String` | Hex string, 8 chars |
| `versionId` | `String` | Format: `V{NNNN}.{NNNN}.{ISO8601}` |
| `timestamp` | `String` (ISO 8601) | Decode with `ISO8601DateFormatter` |
| `commentId` | `String` | Format: `"c{NNN}"` |
| `level` | `Int` | Heading level (1-6) |
| `sections` | Recursive tree | `children: [Section]` |

## Contract Stability

These shapes are the Phase 1 contract. Changes will be communicated via dispatch before implementation. The shapes are additive-compatible — new fields may be added but existing fields won't be removed or renamed without a dispatch.
