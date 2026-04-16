---
type: seed
from: the-agency/jordan/captain
to: the-agency/jordan/devex
date: 2026-04-06T02:44
status: created
priority: normal
subject: "Seed: test result reporting service — DB-backed, structured, wires into QG"
in_reply_to: null
---

# Seed: test result reporting service — DB-backed, structured, wires into QG

From legacy flag triage: we need a database-backed test result reporting service that captures structured test results and wires into quality gates. Similar pattern to ISCP (SQLite DB, structured records, tool interface). Today test results are ephemeral — they print to stdout and vanish. QG agents parse output manually. A reporting service would: (1) capture structured results per test file, per test, pass/fail/skip/duration, (2) persist across sessions so we can track trends and flakes, (3) wire into quality gates — QGR can reference stored results instead of inline output, (4) support multiple frameworks (BATS, Vitest, future). Design question: is this a new DB or an extension of iscp.db? Probably separate — test results are a different domain. Coordinate with ISCP on shared patterns (SQLite, env var overrides, tool interface). Reference: usr/jordan/captain/legacy-flags-migrated-20260406.md item #59.
