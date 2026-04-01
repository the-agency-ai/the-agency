---
allowed-tools: Bash(git diff:*), Bash(git log:*), Read
description: Classify git diffs as formatting-only vs substantive changes.
---

# Diff Summary

Classify git diffs as formatting-only vs substantive changes. Useful for understanding what actually changed vs what was just reformatted.

## Arguments

- $ARGUMENTS: Empty (working tree vs HEAD), `--staged`, or commit range (e.g., `HEAD~3..HEAD`).

## Steps

### Step 1: Get diffs

Run two diffs:
1. `git diff --stat {range}` — with whitespace
2. `git diff -w --stat {range}` — ignoring whitespace

If `--staged`: use `git diff --cached` instead.

### Step 2: Compare

For each file:
- If it appears in both diffs with the same change count → **SUBSTANTIVE**
- If it appears only in the first diff (disappears when ignoring whitespace) → **FORMATTING ONLY**
- If it appears in both but with different counts → **MIXED** (some substantive, some formatting)

### Step 3: Report

```
Diff Classification:

SUBSTANTIVE:
  src/parser.ts      | 42 ++++---
  src/types.ts       | 15 +++

FORMATTING ONLY:
  src/utils.ts       | 8 +++---
  src/config.ts      | 3 +--

MIXED:
  src/router.ts      | 25 +++--- (12 substantive, 13 formatting)

Summary: 2 substantive, 2 formatting-only, 1 mixed
```
