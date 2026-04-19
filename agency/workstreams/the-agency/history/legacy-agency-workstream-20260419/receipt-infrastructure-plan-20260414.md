---
type: plan
project: receipt-infrastructure
workstream: agency
date: 2026-04-14
ad: agency/workstreams/agency/receipt-infrastructure-ad-20260414.md
status: active
owner: the-agency/jordan/captain
---

# Plan: Receipt Infrastructure — Phase 1 (Core Tools)

## Scope

Phase 1 only. Build the three core tools, migration path, and tests. Phase 2 (QG integration) and Phase 3 (RG for methodology artifacts) follow in separate plans.

## Phase 1: Core Tools

### Iteration 1.1: diff-hash tool
**Goal:** Deterministic hash computation with parameterized base.

**Tasks:**
1. Build `agency/tools/diff-hash` — diff mode (branch vs base, excluding `agency/receipts/`) and file mode (single artifact hash)
2. Support `--base`, `--file`, `--json` flags
3. Full SHA-256 internally, 7-char truncation for display
4. BATS tests: diff mode, file mode, JSON output, empty diff error, receipts exclusion

5. Document hash timing in A&D: Hash A = before review, Hash B = after review, Hash C = after triage, Hash D = after principal, Hash E = after all clean (DevEx finding #3, MAR finding #1 — folded here)

**Done when:** `bats tests/tools/diff-hash.bats` passes, tool produces stable hashes, hash timing documented in A&D.

### Iteration 1.2: receipt-sign tool
**Goal:** Write signed receipts with five-hash chain.

**Tasks:**
1. Build `agency/tools/receipt-sign` — accepts all 5 hashes + metadata via CLI flags
2. Enforce naming convention: `{org}-{principal}-{agent}-{workstream}-{project}-{qgr|rgr}-{hash}-{YYYYMMDD-HHMM}.md`
3. Write receipt format v1 with all frontmatter fields
4. Hash D auto-detection: if hash-d == hash-c, set source to "auto-approved"
5. Fail hard on missing required fields — no partial receipts
6. Omit hash_d_transcript when auto-approved (DevEx finding #9)
7. BATS tests: valid receipt, missing fields, auto-approve detection, format validation

**Done when:** `bats tests/tools/receipt-sign.bats` passes, receipts written to `agency/receipts/`.

### Iteration 1.3: receipt-verify tool
**Goal:** Find and verify receipts for current code/artifacts.

**Tasks:**
1. Build `agency/tools/receipt-verify` — find receipts matching workstream+project, verify Hash E
2. Accept explicit `--workstream` and `--project` flags; fall back to branch name parsing (MAR finding #2)
3. Read `diff_base` from receipt frontmatter for recomputation (DevEx finding #7)
3. Support `--file` for verifying specific receipt
4. For mixed PRs: verify all artifact types present have matching receipts
5. Exit 0 = valid, exit 1 = blocked (with actionable message)
6. BATS tests: valid receipt passes, stale receipt fails, missing receipt fails, mixed PR

**Done when:** `bats tests/tools/receipt-verify.bats` passes.

### Iteration 1.4: Migration + pr-create update
**Goal:** Transition from old QGR system to new receipts (DevEx finding #1).

**Tasks:**
1. Update `pr-create` to call `receipt-verify` instead of inline hash logic
2. Backward compat: `receipt-verify` also checks old `usr/**/qgr-*.md` location during transition
3. Update `agency/receipts/.gitkeep` to `.gitignore` if needed
4. Remove old stage-hash references from pr-create (DevEx finding #2 — stage-hash stays for pre-commit, diff-hash for receipts)
5. Document migration in receipt infrastructure reference doc

**Done when:** `pr-create` uses `receipt-verify`, old and new receipts both work during transition.

### Iteration 1.5: Integration test + cleanup
**Goal:** End-to-end test spanning all 3 tools, test isolation, backward compat sunset.

**Tasks:**
1. Integration BATS test: diff-hash → receipt-sign → receipt-verify chain
2. Integration test: pr-create + receipt-verify path
3. Test isolation: all tests use temp dirs / fixture repo, never write to real `agency/receipts/`
4. Backward compat test: receipt-verify finds old `usr/**/qgr-*.md` format
5. Sunset condition: backward compat removed when no old-format receipts exist in repo (documented)

**Done when:** Integration tests pass, test isolation verified, sunset condition documented.

## Completion Criteria

- 3 tools built and tested (diff-hash, receipt-sign, receipt-verify)
- pr-create uses receipt-verify
- End-to-end integration test passes
- Migration path documented and working with sunset condition
- All BATS tests pass with proper isolation (temp dirs)
- Hash timing documented in A&D (folded into iteration 1.1)

## What Phase 1 Does NOT Include

- QG skill integration (/quality-gate, /iteration-complete, /phase-complete) — Phase 2
- RG for methodology artifacts (/review-gate, /define, /design) — Phase 3
- Receipt registry/DB — flagged future (#104)
- Universal artifact naming — flagged future (#103)
