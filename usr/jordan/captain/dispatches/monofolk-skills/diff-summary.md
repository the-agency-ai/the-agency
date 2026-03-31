---
allowed-tools: Bash(git diff:*), Bash(git status:*)
description: Classify git diffs as formatting-only vs substantive changes
---

# /diff-summary

Quickly classify whether the current dirty state is formatting-only (e.g., oxfmt table normalization) or has substantive code changes.

## Arguments

`$ARGUMENTS` may contain:

- Empty — diff working tree vs HEAD
- `--staged` — diff staged changes vs HEAD
- A commit range (e.g., `HEAD~3..HEAD`)

## Steps

1. Run both diffs:
   - `git diff --stat` (with whitespace)
   - `git diff -w --stat` (ignoring whitespace)

   If `--staged` is in arguments, add `--cached` to both commands.
   If a commit range is given, use it instead of the default HEAD comparison.

2. Compare the two outputs file by file:
   - If `git diff -w --stat` shows **no changes at all**: **formatting only**
   - If `git diff -w --stat` shows **fewer files** than `git diff --stat`: **mixed** — files missing from `-w` are formatting-only, remaining are substantive
   - If same files appear in both but a file's line count drops significantly in `-w`: **mixed** — that file has both formatting and substantive changes within it
   - If both show the **same files with similar line counts**: **substantive changes** (no significant whitespace-only component)

3. For mixed diffs, list each file with its classification (formatting-only, substantive, or mixed-within-file).

4. Report the classification clearly:

   ```
   Diff classification: FORMATTING ONLY
   3 files changed (all whitespace/formatting)

   — or —

   Diff classification: SUBSTANTIVE
   5 files changed (all have real content changes)

   — or —

   Diff classification: MIXED
   Formatting only: docs/workflow/flow.md (141+/120-)
   Substantive: apps/backend/src/main.ts, tools/lib/validate.ts
   ```
