# Granola — External Transcript Ingestion

External meeting/conversation transcripts from Granola, ingested and indexed for agent access.

## Structure

```
granola/
  README.md              ← this file
  transcripts/           ← raw transcript files
  granola-{date}-{slug}.md  ← summary + front matter + pointer to transcript
```

## Naming convention

`granola-{YYYYMMDD-HHMM}-{slug}.md`

Example: `granola-20260412-1030-workshop-prep-with-abel.md`

The slug is derived from the Granola-generated summary title (kebab-cased).

## File format

Each summary file has:

```yaml
---
type: granola-transcript
date: YYYY-MM-DDTHH:MM
source: granola
summary_title: "The title Granola gave it"
transcript: transcripts/granola-{date}-{slug}-transcript.md
participants: [list, of, people]
---

## Summary

{Granola's summary here}

## Key decisions

{Extracted decisions, if any}

## Action items

{Extracted action items, if any}

## Transcript

See: [Full transcript](transcripts/granola-{date}-{slug}-transcript.md)
```

## How to use

Paste summary + transcript from Granola into the `granola-ingest` tool:

```bash
./usr/jordan/captain/tools/granola-ingest "summary title" < paste
```

Or invoke via skill (when built).
