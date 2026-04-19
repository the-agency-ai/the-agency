---
type: plan
workstream: the-agency
slug: structural-reset
artifact: plan-the-agency-structural-reset-20260419.md
version: 4
supersedes: history/plan-the-agency-structural-reset-20260419-1310.md (v1); v2 + v3 held in-conversation (pre-commit iterations)
principal: jordan
agent: the-agency/jordan/captain
date: 2026-04-19
pvr: pvr-the-agency-structural-reset-20260419.md
ad: ad-the-agency-structural-reset-20260419.md
mar_triages:
  - research/mar-pvr-structural-reset-20260419.md
  - research/mar-ad-structural-reset-20260419.md
  - (forthcoming) research/mar-plan-v2-structural-reset-20260419.md
driver: "Principal directive D45-R3 — 'This is required to get us in shipping shape'. Zero-defer, continuous-MAR."
---

# Plan — The Agency v46.0 Structural Reset (v4)

## 0. Context

v46.0 is the one-shot structural reset that unblocks the installer (#337) and every downstream shipping workstream.

**Iteration history:** Plan v1 → 4-lens MAR → 9 Plan blockers 1B1'd with principal → Plan v2 → 5-lens MAR (78 findings, 21 distinct clusters) → Plan v3 folds all ≥50 → Plan v3 re-MAR (49 findings, 1 HIGH, convergence pattern) → Plan v4 folds remaining ≥50 from v3 re-MAR.

**Standing directives (principal D45-R3):**
- **Zero defer.** Every MAR finding ≥50 is accepted and folded **before** execution. No "defer," no "later," no severity-based skip.
- **Continuous MAR.** Inspections at every phase boundary, not just endpoints.
- **Dual-use tooling.** Tools built for the-agency's reset are packaged into customer `agency-migrate-prep`.
- **Deterministic verification over self-report.** Captain verifies via tool output; receipts are informational.

**Bootstrap paradox acknowledgment** (fold P-8): this reset is the framework rebuilding itself while running on itself. Phase 0 builds tools inside `agency/tools/` (pre-rename); those tools participate in their own move. The operational strategy (untracked alias-shim for captain's session only — fold A-4/O-3/R-2/V-2/P-7) contains the paradox in captain-private scope. This is a one-time transitional condition, not a pattern — documented in release notes "Why now."

## 1. Nine Blocker Resolutions Folded (anchor — already Over-and-out'd with principal)

| # | Resolution | Plan anchor |
|---|---|---|
| 1 | Budget: single session, multi-phase with checkpoints. Build tooling if required. | Phase 0 |
| 2 | "Write the tools you need. That is Phase 1." → Phase 0 = tooling build. | Phase 0 |
| 3 | Post-rename tool path break → alias-shim strategy (revised from symlink per MAR A-4/O-3/R-2). | Phase 0d + Phase 1 + Phase 4.5 |
| 4 | Fully-qualified path substitutions + explicit allowlist + `agency-sweep` preview-first. | Phase 0 + Phase 4 |
| 5 | Manifest scope rule + sub-Q outcomes: starter-packs → `src/spec-provider/`; schemas + findings-* → `src/archive/`; hooks/hookify stay in `agency/`; 9 canonical classes / 9 archived non-classes / designex refactor / templates move. | Phase 2 |
| 6 | Receipts informational; captain verifies deterministically. | Phase 4 |
| 7 | Replace line-count heuristic with `subagent-diff-verify` (substring-level pattern check). | Phase 0 + Phase 4 |
| 8 | Drop shell globs; `git-rename-tree` using `git-safe ls-files`. | Phase 0 + all moves |
| 9 | 5-element customer migration loop (migrate-prep + `--migrate` gate + verify-v46 + health + report-repair-release). | Phase 0 + Phase 6 |

## 2. Core Principles (binding)

1. **Rename is pure move; content sweep is separate commit.** Phase 1 = directory rename (no content edits). Phase 4 = content sweep. `git log --follow` preserved across rename boundary.
2. **Archive before delete.** Every `git rm` inside `agency/` is preceded by `git-rename-tree {src} agency/workstreams/the-agency/history/flotsam/` OR principal-1B1 `--confirmed-zero-value=<rationale>`.
3. **Atomic per-phase commit; per-phase revertable.** Phase 4 is 5 commits (one per subagent); Phase 2 is 6 sub-phases (2a-2f) each with own commit; others one commit per phase.
4. **Fully qualified path substitutions only.** Regex on `claude/<known-subdir>/`; never bare `claude`. Explicit allowlist (rationale-per-line).
5. **Static + dynamic reference verification.** Static: `ref-inventory-gen` pre/post + `import-link-check`. Dynamic: every hookify rule fires against `.canary` file; full BATS green; `commit-precheck` on post-reset file.
6. **No raw shell globs in rename operations.** `git-rename-tree` (using `git-safe ls-files`) enumerates; `git mv` moves. Dotfiles handled by construction.
7. **MAR at every phase boundary.** 2-4 reviewers on phase output; findings fold before next phase.
8. **Every tool has BATS coverage with declared min-test-count before it's invoked.** (fold V-13)
9. **In-scope partition rule** (fold A-15 + v4 A-1): *In-scope* = files installed/executed/imported/discovered by Claude Code at session start. *Out-of-scope (not swept)*: `history/**`, `src/archive/**`, `usr/**`, `.git/**`, `.reset-wt/**` (subagent worktrees; captain-private), test fixtures with embedded `.git/` (e.g., `test/test-agency-project/**`). Out-of-scope files retain their `claude/` references as historical artifacts. `ref-inventory-gen` and `agency-sweep` apply this partition by default via `--exclude` flag (committed default list). `.reset-wt/` added to `.gitignore` at Phase 0a baseline.
10. **Phase 4.5 atomicity** (fold R-5): sequential operations stage changes into a single working tree; one commit at end; verify `agency-sweep --dry-run` shows zero pre-commit. If verification fails, `git-safe reset --hard HEAD` + redo. **No partial commit under any circumstance.**
11. **Hookify-bypass discipline** (fold O-7): every raw-tool invocation during reset uses `AGENCY_ALLOW_RAW=1 <cmd>` with audit-log entry including rationale; `git-rename-tree` wraps this internally so callers don't need to know. Table of privileged operations in §7.
12. **Adopter-artifact isolation + shim resilience** (fold P-7 + v3 R-3 HIGH + v4 R-1 mechanical backstop): the alias-shim is captain-private, untracked, session-scoped; never appears in any committed file, release note, runbook, or subagent receipt. **Protected against cleanup destruction** — `git clean -fd` during reset execution is FORBIDDEN without explicit `-e` exclusions covering shim + baseline dir; Phase 4.5 retry loop uses `git-safe reset --hard HEAD` only (never `git clean -fd`). Pre-Phase-4.5 flight check: `test -f <shim-path>` must pass. Encoded in `reset-rollback.sh` wrapper (Phase 0b deliverable, fold v3 R-8). **Mechanical backstop** (fold v4 R-1): hookify rule `hookify.block-git-clean-during-reset` added in Phase 0b — detects presence of `.git/RESET_IN_FLIGHT` sentinel file (created by `reset-rollback.sh` at Phase 0 entry, removed at Gate 7 exit) + `git clean -fd` invocation without `-e` covering shim path; BLOCKS with exit-2 and pointer to `reset-rollback.sh`. Defense in depth: principle + wrapper + hookify rule.
13. **Subagent worktree isolation** (fold v3 R-2): each Phase 4 subagent operates in a dedicated `git worktree add .reset-wt/subagent-{X} reset/subagent-{X}` created by captain pre-fan-out. Subagent receives worktree path in prompt. Worktrees cleaned up post-merge. Concurrent `git-safe` invocations don't race on index.lock.

## 3. Phase Structure

**Time budget:** phase-execution ~**365 minutes** + MAR-checkpoint overhead ~**35 minutes** = **~400 min total** (~6.7 hrs). Fold v3 O-1/O-3: reconciled sum; Phase 4 budget now includes serialized verification overhead explicitly.

| Phase | Exec min | Notes |
|---|---|---|
| 0 (baseline + tooling) | 90 | 12+ tools with BATS + declared min-test-counts |
| 1 (Great Rename) | 15 | Atomic `git mv`; 10 canaries |
| 2 (subdir reorg) | 30 | 2a-2f atomic sub-phases |
| 3 (archive/extract/delete) | 45 | 3a+3b+3c sub-phase commits |
| 3.5 + 3.6 (workstream consolidation) | 30 | Captain + agency + housekeeping splits |
| 4 (subagent sweep: fan-out + serialized verification) | **85** | 60 min fan-out + 25 min captain verification (fold v3 O-3) |
| 4.5 (@import + settings.json + shim cleanup) | 15 | Atomic single commit |
| 5 (hookify canary) | 15 | .canary fixtures |
| 6 (release notes + runbook + PR + QGR aggregation) | 40 | PR creation + QGR v46 aggregation |
| **Phase-exec total** | **~365 min** | |
| MAR overhead (9 checkpoints × ~3-5 min) | **~35 min** | |
| **Grand total** | **~400 min** | **Above prompt-cache window horizon** |

**Budget breakpoints** (fold v3 O-1) — pre-declared session-compact candidates:
- **After Phase 0 exit**: 90 min elapsed. If accumulated >120 min, `/session-compact` + `/compact-resume` at next session.
- **After Phase 3.6 exit**: ~210 min elapsed. Pre-declared natural handoff — if wall-clock >240 min at Gate 3.6, session-compact before Phase 4.
- Any gate exceeding 15-min fold budget → session-compact + principal 1B1.

**Budget-breach protocol** (fold O-1/O-12):
- Each checkpoint's fold-iteration capped at **15 min**; max **2 re-MAR cycles** per checkpoint.
- If a checkpoint exceeds its cap, captain writes `/session-compact` with full handoff (PHASE-CURSOR + fold-in-progress state + re-MAR findings pending), principal 1B1 required before proceeding. `/session-compact` + `/compact-resume` are first-class deliverables, not emergency exits.
- If Phase 0 tool build exceeds 90 min, session-compact at Phase 0 exit; Phase 1+ resumes next session.

**Phase cursor** (fold R-12): `usr/jordan/captain/reset-baseline-20260419/PHASE-CURSOR.txt` — each gate pass appends a JSONL line `{"phase":N,"status":"done","ts":<iso>,"prev_hash":<sha256>,"cursor_hash":<sha256>}`. SHA256 chain-hash; any tampered past entry invalidates chain. Cursor file committed at each gate pass (git-history is the tamper-evident record).

**Audit log** (fold O-6/V-1): Per-actor JSONL logs (captain + per subagent). Merged + sorted at Gate 6 via `audit-log-merge` tool (Phase 0b deliverable). Reconciliation = set-based: every WRITE-producing JSONL entry (`cmd` starts with `git mv`, `git rm`, `git-rename-tree`, `git-safe add`) has a matching rename/delete/add in its phase-commit's `git log --name-status`. `audit-log-reconcile` tool (fold A-12 + V-1 promoted) runs at Gate 6 with `--exit-nonzero-on-delta`.

### Phase 0 — Baseline + Tooling Build (~90 min)

**Objective:** Establish ground truth; build every tool Phase 1+ will use.

**Sub-phases:**

0a. **Pre-reset baseline**
   - `git-captain tag v45.3-pre-reset` + push (rollback anchor)
   - `usr/jordan/captain/reset-baseline-20260419/` captures:
     - `content-inventory.sha256` (every tracked file + SHA; V1 from A&D MAR)
     - `bats-baseline.txt` (full BATS — tap format — with **pass/fail/skip counts + test-name set**; fold O-10/V-13)
     - `ref-inventory-pre.txt` (via `ref-inventory-gen --pre --exclude src/archive/**,history/**,usr/**,test/test-agency-project/**`; fold A-5)
     - `hookify-rule-count.txt` (Phase 5 reads this; fold A-13)
     - `skill-count.txt`
     - `settings-checksum.txt`
     - `claude-md-checksum.txt`
     - `baseline-symlink-check.txt` = output of `find . -type l -not -path './.git/*' -not -path './test/test-agency-project/*' -not -path './node_modules/*'` (tree-wide; must be empty; fold V-8 + v3 R-5)
     - `sensitive-dirs-sha256.txt` = SHA256 of every file in `agency/hooks/`, `agency/tools/`, `.claude/` (fold V-12 — supply-chain anchor for non-manifest mutations)
   - `env-file-inventory.txt` = `find . -name '.env*' -not -path './.git/*' -not -path './node_modules/*' -not -path './test/test-agency-project/*'` (fold v4 R-4 — explicit enumeration for Phase 3c)
   - `PHASE-CURSOR.txt` initialized with phase-0a chain-hash

0b. **Tool build** (dogfooded; each tool ships with BATS fixture + declared min test count)

   | Tool | Purpose | BATS | Min tests |
   |---|---|---|---|
   | `git-safe ls-files` | Read-only subcommand added to allowlist (fold §Great Rename blocker #8). | `tests/tools/git-safe-ls-files.bats` | 4 |
   | `git-rename-tree` | Enumerate via `git-safe ls-files` + `AGENCY_ALLOW_RAW=1 git mv` each file. Internal bypass logging. | `tests/tools/git-rename-tree.bats` — canaries: `.gitkeep`, `.gitignore`, `.hidden-example`, deep-nested, unicode name, embedded-semicolon path (`test; rm -rf /`) | 10 |
   | `agency-sweep` | Path-substitution; `--dry-run` default; `--apply` requires explicit flag; `--output-patch` emits structured unified diff for captain apply (fold v4 A-2); always applies `ref-sweep-allowlist.txt` unless `--no-allowlist`. Multi-substitution-per-line supported. **Consumes subagent manifest YAML** (files + allowed_substitutions + rejected_substitutions); `rejected_substitutions` patterns trigger abort. **Cascade prevention**: post-substitution output is NOT re-matched against patterns (fold v3 A-4 + v3 O-10). | `tests/tools/agency-sweep.bats` — multi-sub-per-line (two patterns on one line, manifest-order applied), allowlist respected, dry-run default, manifest-mode rejected-substitution abort, cascade-prevention (replaced text does not re-trigger), overlapping patterns first-match-wins, **--output-patch emits valid unified-diff parseable by `git apply --check`** | 16 |
   | `ref-inventory-gen` | Pre/post manifest; every match classified `rename-target` / `allowlisted` / `unknown`. Scan scope: all `git-safe ls-files` tracked files minus `--exclude` globs. `--strict` exits nonzero on any `unknown`. | `tests/tools/ref-inventory-gen.bats` — canary per include/exclude category | 10 |
   | `import-link-check` (fold V-5 + v3 V-4) | Parses patterns across expanded scope (fold v3 V-4): **`@import <path>`** and **`required_reading: <path>`** frontmatter and **`<!-- @import <path> -->`** inline comments across `.claude/**`, `agency/**` (incl. `agency/agents/**/agent.md` cross-class imports, `agency/templates/**` placeholders, `agency/hookify/**` inline `@agency/REFERENCE-*.md` references), root `CLAUDE.md`. Asserts every target file exists on disk. | `tests/tools/import-link-check.bats` — valid + orphan + agent-cross-class + template + hookify-inline fixtures per pattern type | 10 |
   | `subagent-scope-check` | Given manifest + branch, verifies changed-file set ⊆ manifest globs; **asserts non-emptiness unless `expected_changes: 0` declared** (fold V-9). | `tests/tools/subagent-scope-check.bats` | 6 |
   | `subagent-diff-verify` | Given manifest + branch: for each changed line, reconstruct `-` → `+` by applying manifest's allowed substitutions in order; assert reconstruction equals actual `+`. Any mismatch → reject. Rejects whitespace-only changes (`--ignore-all-space` comparator). File-type reject list: binary, `test/test-agency-project/**`, any allowlisted path. | `tests/tools/subagent-diff-verify.bats` — single-sub, multi-sub-per-line, same-length corruption, whitespace drift, binary-file reject | 10 |
   | `subagent-overlap-check` (fold R-3 new) | Scans 5 subagent manifests for content-duplication across scopes (e.g., test fixture embedding tool-script snippet); flags file pairs requiring exclusive ownership or serialized merge. | `tests/tools/subagent-overlap-check.bats` | 5 |
   | `audit-log-merge` (fold O-6 new) | Merges per-actor JSONL logs sorted by ts; detects duplicate event IDs. | `tests/tools/audit-log-merge.bats` | 4 |
   | `audit-log-reconcile` (fold V-1 new) | Validates every WRITE event has matching commit name-status; every commit has ≥1 audit entry. `--exit-nonzero-on-delta`. | `tests/tools/audit-log-reconcile.bats` — missing entry + extra entry + perfect-match fixtures | 6 |
   | `hookify-rule-canary` | Per-rule dry-run canary: matches regex against synthetic payload, asserts exit-2 (block) or non-zero (warn) or 0+inform-message (inform). **Never executes the actual blocked command.** Per-rule `.canary` file committed alongside rule with expected match-key (fold V-6, O-17). | `tests/tools/hookify-rule-canary.bats` — block-raw-tools canary + warn canary + destructive-command-safety canary | 8 |
   | `agency-verify-v46` (customer-side + internal versions; fold V-11) | **Customer-side** (`agency-verify-v46 --customer`): validates against embedded v46 manifest (tree shape, settings.json hook paths, agent registration shape, ISCP tool smoke via dispatch-create dry-run, no residual claude/ at root, no hook ENOENT). **Internal** (`agency-verify-v46 --internal`): adds BATS-parity + ref-inventory delta vs `reset-baseline-20260419/`. | `tests/tools/agency-verify-v46.bats` — customer happy + internal happy + broken-state rejection | 10 |
   | `agency-migrate-prep` | Customer-side wrapper: local backup tag (`v45.3-pre-reset-local`), `agency-sweep --dry-run` preview, `agency-sweep --apply` with customer confirmation, config update (settings.json, agent registrations), prep marker `.agency/migrate-prep-v46.ok`. Idempotent, dry-run-first default. UX contract per §6. | `tests/tools/agency-migrate-prep.bats` — idempotent re-run, dry-run default, confirmation-required-on-apply | 10 |
   | `agency update --migrate` (subcommand) | Hard version gate: v45.x → v46.0 refuses without `--migrate` AND `.agency/migrate-prep-v46.ok` marker. Exit nonzero + runbook pointer. | `tests/tools/agency-update-migrate.bats` — refuses without flag + without marker | 6 |
   | `agency update --migrate-back` (fold V-7/R-13) | Rollback subcommand. Checks dirty tree (refuse or `--force`); restores from `v45.3-pre-reset-local` tag; clears prep marker. | `tests/tools/agency-migrate-back.bats` — round-trip equivalence vs v45.3 snapshot (content-inventory.sha256 match modulo prep artifacts); dirty-tree refusal; force override | 8 |
   | `agency-health` | Broken-state detection: mismatched tree (residual `claude/` dir + v46 settings), `@import` resolve failures, agent registration path mismatches. | `tests/tools/agency-health-v46.bats` | 6 |
   | `agency-report` | Packages `agency-verify-v46` diagnostic into dispatch (to `the-agency/captain`) + cross-repo GH issue auto-filed. | `tests/tools/agency-report.bats` | 4 |
   | `gate-check-{0,1,2,3,3.5,3.6,4,4.5,5,6,7}.sh` (fold v3 O-6 — 11 gates; fold v4 V-3 — tightened floor) | Per-phase gate scripts; composite mechanical checks; exit 0 happy; nonzero per-criterion via fixture injection. | `tests/tools/gate-check.bats` — per-gate happy-path + per-exit-criterion negative-case | **≥73** (sum of 1 happy + 1 per criterion across gates: 10+4+8+7+8+6+6+6+5+7+6 = 73 minimum) |
   | `smoke-battery.sh` (fold v3 V-3 new) | Phase 6 smoke wrapper: each battery item (handoff/dispatch/flag/agency-health/session-resume/bats/ref-injector/commit-precheck/ISCP/skill-validate/skill-verify) becomes a scripted assertion; exit 0 only if all pass. | `tests/tools/smoke-battery.bats` — per-item assertion + full-script happy + fail-inject per item | 12 |
   | `reset-rollback.sh` (fold v3 R-3 + v3 R-8 new) | Safe rollback wrapper encoding forbidden-`-fd` + shim-excluding `git clean` patterns. `reset-rollback.sh --pre-commit` / `--post-commit-phase-revert` / `--full-reset-to-tag` modes. | `tests/tools/reset-rollback.bats` — shim preserved, baseline dir preserved, tag-reset works | 6 |

   **Total tool rows: 20** (new-since-v2: `import-link-check`, `subagent-overlap-check`, `audit-log-merge`, `audit-log-reconcile`, `agency update --migrate-back`, `smoke-battery.sh`, `reset-rollback.sh`, `hookify.block-git-clean-during-reset` = 8 net-new; rest are extensions of existing tools or refinements).

   **Phase 0 tool internals discipline** (fold R-1): every Phase 0 tool uses runtime path resolution (`$AGENCY_ROOT` or `dirname`-self-resolution) — no baked `claude/` or `agency/` literals in tool bodies. BATS fixtures use repo-root-relative paths resolved at runtime. Rationale: Phase 1 rename doesn't require Phase-4 sweep of these tool contents for path strings.

   **Sensitive-dir supply-chain baseline** (fold R-1 + V-12): `agency/hooks/`, `agency/tools/`, `.claude/` sha256 manifest captured in Phase 0a. Post-Phase-4.5 `gate-check-4.5.sh` asserts: for every file NOT in any subagent manifest, SHA256 matches Phase 0 manifest (unchanged). For files IN a manifest, `subagent-diff-verify` covers them.

   **Allowlist** — `agency/tools/ref-sweep-allowlist.txt` with ≥14 seed entries + rationale per line:
   ```
   \.claude/	Anthropic Claude Code discovery dir — never renamed
   CLAUDE\.md$	Root bootloader filename
   anthropic/claude-code	Upstream project reference
   \$CLAUDE_PROJECT_DIR	Environment variable
   "Claude Code"	Product name
   claude-code/CHANGELOG	Anthropic changelog refs
   Claude Code	Product name (no quotes)
   claude\.com	Company domain
   @claude\.com	Anthropic email
   test/test-agency-project/	Test fixture with embedded .git/ (fold P-3, Principle 9)
   src/archive/	Archived content retains historical refs (Principle 9)
   history/	Historical content retains refs (Principle 9)
   usr/	Principal sandbox retains refs (Principle 9)
   workstreams/*/transcripts/	Transcripts retain refs
   ```

0c. **Subagent manifests** (partitioning principle; file-lists generated by `ref-inventory-gen` at start of Phase 4)

   **Partitioning rules** (fold A-6/A-10/A-2):
   - Subagent **A — Framework tools**: `agency/tools/**`
   - Subagent **B — Framework docs**: `agency/REFERENCE*.md`, `agency/README*.md`, `agency/CLAUDE-THEAGENCY.md` (**NOT** root `CLAUDE.md` — owned by Phase 4.5)
   - Subagent **C — Tests**: `tests/**` (excluding `test/test-agency-project/**` which is fixture)
   - Subagent **D — Discovery surfaces (body only)**: `.claude/skills/**`, `.claude/commands/**`, `agency/agents/**` (**NOT** `.claude/agents/**/*.md` @imports — owned by Phase 4.5)
   - Subagent **E — Config**: `agency/hooks/**`, `agency/hookify/**`, `agency/config/**`, `package.json`, `.gitignore`, `.gitattributes`

   **Out-of-scope** (excluded from Phase 4; fold A-2 + Principle 9):
   - `src/**` (except `src/archive/**` — already archived content; confirmed not swept)
   - `usr/**` (principal sandbox)
   - `history/**`, `workstreams/*/history/**`, `workstreams/*/transcripts/**`
   - `test/test-agency-project/**` (embedded fixture)

   **Phase 4.5 exclusive scope:**
   - Root `CLAUDE.md` @import rewrites
   - `.claude/settings.json` hook paths
   - `.claude/agents/**/*.md` @import headers
   - Alias-shim cleanup

   **Subagent manifest format** (YAML):
   ```yaml
   subagent: A
   ownership_priority: 1  # A=1, B=2, C=3, D=4, E=5 (fold v3 R-1 — deterministic tie-break)
   files:
     - agency/tools/**
   excludes:  # fold v3 A-1 — explicit, not implicit via Principle 9
     - agency/workstreams/*/history/**
     - agency/workstreams/*/transcripts/**
   allowed_substitutions:
     - pattern: "agency/tools/"
       replacement: "agency/tools/"
     - pattern: "agency/hooks/"
       replacement: "agency/hooks/"
     # etc.
   rejected_substitutions:
     # mirrors allowlist — assertions that these must NOT change
     - ".claude/"
     - "CLAUDE.md"
   expected_changes: null  # or 0 if subagent legitimately has no changes
   ```

   `subagent-overlap-check` runs pre-fan-out to detect content-duplication across scopes (fold R-3). On detected overlap, `ownership_priority` gives tie-break: lower-priority subagent's scope is trimmed to exclude the overlapping file; resolution plan committed to `usr/jordan/captain/reset-baseline-20260419/subagent-overlap-resolution.md` pre-fan-out (fold v3 R-1).

   **Ownership-priority rationale** (fold v4 A-3): ranking A=1..E=5 reflects typical scope-narrowness — A (tools) narrowest, E (config) broadest; narrower-scope subagent wins on overlap because the narrower owner has more context on the content's semantics. `subagent-overlap-resolution.md` may override per case with captain-authored rationale.

0d. **Release notes skeleton + migration runbook skeleton** (expanded content manifest per P-1/P-2/P-4)

   **Release notes slots** (fold P-1):
   - Header + tag (`v46.0`) + date
   - TL;DR (2 lines)
   - Why now (fold P-8: bootstrap paradox acknowledgment; one-time transitional condition)
   - What changed (adopter-visible; fold v3 P-3 per-change impact + v3 P-8 templates move):
     - Directory rename `claude/` → `agency/` — **Adopter impact: see runbook § migration-paths for all 5+ path categories**
     - New top-level `src/` dir — **Adopter impact: none (source-code tree, not runtime)**
     - New canonical class `design-lead` (fold P-12) — **Adopter impact: if your repo registers a design agent, consider `@import @agency/agents/design-lead/agent.md` as the new canonical. Legacy `agency/agents/designex/` class directory replaced; `agency-migrate-prep` rewrites `@import @agency/agents/designex` references automatically (fold v4 P-3).**
     - Agent templates relocated from `agency/agents/templates/` to `agency/templates/` — **Adopter impact: any reference to `agency/agents/templates/` swept automatically by prep**
     - 9 non-class agents archived to `src/archive/agents/`: `apple, cos, discord, gumroad, iscp, marketing-lead, platform-specialist, project-manager, testname` — **Adopter impact: if your repo has `@import @claude/agents/{name}` OR `.claude/agents/*/{name}.md`, see runbook § agent-migration**
   - What's preserved (fold P-3 test fixture carve-out + v3 P-1): `usr/`, workstream data, `@import` semantics, **test fixture at `test/test-agency-project/` (embedded git repo — fixture's internal `claude/` references preserved verbatim as historical fixture content; adopters take no action on it)**, dispatches + flags
   - What's broken (migration-required):
     - `.claude/settings.json` hook paths (examples)
     - Root `CLAUDE.md` @import (examples)
     - Skill `required_reading:` frontmatter (examples)
     - Agent registration `@import` (examples)
     - Tool invocation paths (examples)
     - **Minimum 5 breaking-path categories with before/after examples** (fold P-5)
   - Migration summary (pointer to runbook)
   - Rollback (3 paths — origin `v45.3-pre-reset` tag, local `v45.3-pre-reset-local` tag, `agency update --migrate-back`)
   - Known diagnostic signatures (post-migration failures): hook ENOENT, @import not found, `required_reading` broken
   - Contact path: `agency-report` tool auto-opens cross-repo issue + dispatches to `the-agency/captain`
   - Link to A&D for mechanics-curious

   **Migration runbook slots** (fold P-2/P-4):
   - Prep: `agency-migrate-prep` invocation + flags + prompts
   - Update: `agency update --migrate` + gate explanation
   - Verify: `agency-verify-v46 --customer`
   - **Common failure modes table** (fold P-2):
     | Symptom | Diagnosis | Action |
     |---|---|---|
     | `Hook fire ENOENT claude/hooks/*.sh` | settings.json not rewritten | Re-run `agency-migrate-prep` OR manual sed: `sed -i 's|claude/hooks|agency/hooks|g' .claude/settings.json` |
     | `@import resolve error` at session start | CLAUDE.md @import stale | Manual rewrite: `sed -i 's|@claude/|@agency/|g' CLAUDE.md` |
     | `required_reading not found` in skill | Skill frontmatter stale | Re-run prep OR `agency-sweep --apply --files=.claude/skills/` |
     | `agency-verify-v46 --customer` fails | Customer-side validator detects inconsistency | Run `agency-report` to dispatch diagnostic + auto-file issue |
     | ISCP `dispatch list` errors | Agent registration path format v45 | Re-run prep to update `.claude/agents/**/*.md` @imports |
   - **Rollback decision tree** (fold P-4 + v3 P-2 dispatch rescue):
     | State | Mechanism | Preserved | NOT preserved |
     |---|---|---|---|
     | Prep done, update not run | `rm .agency/migrate-prep-v46.ok` | Everything | (reverts prep cleanup in working tree if mutated) |
     | Update done, v46 not committed | `agency update --migrate-back` (includes **dispatch rescue**: scans v46-format dispatches at `agency/workstreams/*/dispatch-*.md`, renames to v45-format paths, writes rescue report at `.agency/migrate-back-rescue-v46.log`) | `usr/` data, v45-format dispatches + any v46 **dispatches** rescued by tool | Any un-rescuable **dispatches** flagged in rescue log — require manual action per log instructions (fold v4 P-2 explicit wording) |
     | v46 committed locally, not pushed | `git reset --hard v45.3-pre-reset-local` | Git history up to pre-reset | Post-reset commits (including `usr/` edits) |
     | v46 pushed | `git reset --hard v45.3-pre-reset` (origin tag) | Git history up to pre-reset origin | Post-reset commits + any unpushed work |
   - **Post-migration dispatch rescue detail** (v3 P-2): `agency update --migrate-back` includes explicit rescue for v46-format dispatches created between `--migrate` and rollback. Tool scans, renames, logs. Adopter reviews `.agency/migrate-back-rescue-v46.log` post-rollback. Un-rescuable entries are listed with manual-action instructions; never silently lost.
   - Contact + report: `agency-report` tool instructions

**Gate 0 exit criteria** (`gate-check-0.sh`):
- v45.3-pre-reset tag pushed to origin
- Baseline inventory complete + committed (all files in 0a list present)
- All Phase 0 tools pass BATS green with **test count ≥ declared min per tool** (fold V-13)
- Allowlist file committed with ≥14 seed entries + rationale per line
- Subagent manifests declared (partitioning principle; files TBD Phase 4)
- Release notes + migration runbook skeletons present with all §0d slots (even if stubbed)
- Sensitive-dirs SHA256 manifest captured (`sensitive-dirs-sha256.txt`)
- No symlinks under repo root (`baseline-symlink-check.txt` empty)
- `PHASE-CURSOR.txt` chain-hash entry for phase-0 done

**MAR checkpoint 0→1** — 3 reviewers (fold P-14: product-lens earlier):
- reviewer-operations: "Are the tools complete for Phase 1-6? Runtime-path-resolution discipline honored?"
- reviewer-verification: "Does baseline capture everything needed for Phase 6 parity check?"
- reviewer-product: "Release notes + runbook skeletons have all adopter-facing slots? Decision tree complete?"
- **Zero-defer fold budget: 15 min; max 2 re-MAR cycles.**

### Phase 1 — The Great Rename (~15 min)

**Objective:** Directory rename `claude/` → `agency/`. No content edits.

**Operations:**
1. Captain-session shim (UNTRACKED; fold A-4/O-3/R-2/V-2/P-7): captain sources `usr/jordan/captain/reset-baseline-20260419/reset-shim.sh` which aliases `./claude/tools/X` → `./agency/tools/X` bash-side only. **No symlinks in tree. Shim is session-scoped; removed at Gate 6.**
2. `AGENCY_ALLOW_RAW=1 git mv claude agency` (atomic directory rename; git handles dotfiles, rename-follow preserved; bypass logged to audit)
3. Verify rename-follow on **10 canaries** (fold V-8):
   - `agency/CLAUDE-THEAGENCY.md`
   - `agency/tools/git-safe`
   - `agency/REFERENCE-QUALITY-GATE.md`
   - `agency/hookify/hookify.block-raw-tools.md`
   - `agency/tools/lib/_log-helper` (deep-nested)
   - `agency/config/manifest.json`
   - `agency/data/.gitkeep` (dotfile)
   - `agency/workstreams/the-agency/transcripts/dialogue-transcript-20260419.md` (unusual long name — if exists, else skip)
   - `agency/assets/theagency-logo-constellation.svg` (binary canary; fold V-8)
   - `agency/workstreams/the-agency/README.md` (if present)
   - For each: `git log --follow --oneline -- {path}` returns pre-rename history

**One commit:** `feat(v46.0): Phase 1 — Great Rename claude/ → agency/`

**Gate 1 exit** (`gate-check-1.sh`):
- Directory rename complete
- **No symlinks or tracked files introduced** (`git ls-files claude/` returns empty; fold V-2)
- All 10 canaries pass `git log --follow`
- `git diff --stat HEAD^` shows zero content changes (rename-only)
- Audit log contains `AGENCY_ALLOW_RAW=1` entry for `git mv` invocation with rationale
- `PHASE-CURSOR.txt` chain-hash entry for phase-1 done

**MAR checkpoint 1→2** — 2 reviewers:
- reviewer-architect + reviewer-verification as before

### Phase 2 — Subdir Reorg (~30 min)

**Objective:** Establish `src/` tree; move non-installed artifacts; refactor `designex` per extraction rule.

**Phase 2f designex refactor rule** (fold A-3):
- **Class content** (→ `agency/agents/design-lead/agent.md`): responsibilities + review protocol + handoff contract + universal capabilities (design strategy, token stewardship, QA, design review authorship, extraction methods).
- **Instance content** (→ `.claude/agents/jordan/designex.md`): instance-specific tools (`figma-extract`, `designsystem-*`), designex voice/personality, principal-specific context.
- **Rule committed** as comment block at top of `agency/agents/design-lead/agent.md`.
- `.claude/agents/jordan/designex.md` writes `@import @agency/agents/design-lead/agent.md` (POST-rename path directly — fold R-10: no broken `@claude/` import committed).

**Sub-phases** (each atomic commit):

2a. **Establish src/ tree**: `mkdir src/ src/archive/ src/spec-provider/`; commit.

2b. **Starter-packs → `src/spec-provider/starter-packs/`**: `git-rename-tree`; commit.

2c. **Dead artifacts → `src/archive/`**:
   - `git-rename-tree agency/schemas src/archive/schemas`
   - `git-rename-tree agency/tools/findings-save src/archive/tools/findings-save` (note: `git-rename-tree` handles single-file move via `ls-files -- <path>`)
   - `git-rename-tree agency/tools/findings-consolidate src/archive/tools/findings-consolidate`
   - `git-rename-tree tests/schemas src/archive/tests/schemas`
   - `git mv tests/tools/findings.bats src/archive/tests/tools/findings.bats`
   - Commit.

2d. **9 non-class agents → `src/archive/agents/`**:
   - For each of `apple, cos, discord, gumroad, iscp, marketing-lead, platform-specialist, project-manager, testname`: `git-rename-tree agency/agents/{name} src/archive/agents/{name}`
   - **iscp note** (fold A-11): archiving the **class directory** `agency/agents/iscp/`. The instance registration `.claude/agents/jordan/iscp.md` is retained; in Phase 4.5, its `@import` header updates to `@agency/agents/workstream-lead/agent.md` (matches iscp-is-a-workstream-lead-instance per principal 1B1 Over-and-out). The iscp service code (`agency/tools/` iscp binaries, `tests/tools/iscp-*.bats`) is untouched.
   - Commit.

2e. **Templates move**: `git-rename-tree agency/agents/templates agency/templates`; commit.

2f. **Designex refactor** (per extraction rule above):
   - `mkdir agency/agents/design-lead`
   - Write `agency/agents/design-lead/agent.md` (class content + extraction rule comment header)
   - Write/update `.claude/agents/jordan/designex.md` (instance registration with `@import @agency/agents/design-lead/agent.md`)
   - `git-safe rm -r agency/agents/designex` (now replaced)
   - Commit.

**Gate 2 exit** (`gate-check-2.sh`; fold A-1/O-9/V-14 — deterministic list, no free-text confusion):
- `agency/agents/` contains exactly these 9 entries (alphabetized): `captain, design-lead, researcher, reviewer-code, reviewer-design, reviewer-scorer, reviewer-security, reviewer-test, workstream-lead`
- Assertion: `ls agency/agents/ | sort | diff - <canonical-classes.txt)` returns empty
- `src/` tree present with `spec-provider/starter-packs/`, `archive/schemas/`, `archive/tools/`, `archive/tests/`, `archive/agents/` (9 entries)
- `agency/templates/` present (moved out of agents/)
- `agency/starter-packs/`, `agency/schemas/`, `agency/tools/findings-*` all absent
- `.claude/agents/jordan/designex.md` contains `@import @agency/agents/design-lead/agent.md`
- `agency/agents/designex/` absent
- BATS: every test in `tests/` (excluding `src/archive/tests/`) passes
- `PHASE-CURSOR.txt` chain-hash entry for phase-2 done

**MAR checkpoint 2→3** — 3 reviewers (architect, operations, risk).

### Phase 3 — Archive + Extract + Delete (~45 min total, 3 atomic sub-phases)

3a. **Archive** (~15 min): per PVR + principal call list → `agency/workstreams/the-agency/history/flotsam/` with `HISTORICAL-PATH-NOTE.md`.

   **Deferred-items call-out** (fold P-9):
   - `agency/workstreams/gtm/` and `agency/workstreams/proposals/` — **NOT archived or deleted**. Leave in place with `TODO-MOVE-TO-THE-AGENCY-GROUP.md` marker file. Reference-swept in Phase 4 but structurally preserved.
   - `claude/principals/jordan/resources/secrets/*.env` — flagged for Phase 3c deletion; handled separately (not archived — see 3c).
   - `agency/workstreams/test; rm -rf /` (injection test artifact; fold P-13): explicit `--confirmed-zero-value="injection test from security audit, zero legitimate content"` with principal-1B1 override. Handled via `git-rename-tree` (blocker #8 dotfile/metachar safety); release notes references as "legacy injection-test artifact removed" without pathname.

3b. **Data extraction** (~15 min; fold R-4 + v3 R-4 ordering):
   - Enhanced DB integrity protocol — **integrity checks run FIRST on pristine source**, THEN WAL checkpoint + VACUUM + dump:
     - **Pre-VACUUM (pristine source)**:
       - `PRAGMA integrity_check;` — must return `ok`
       - `PRAGMA foreign_key_check;` — must return empty (no FK violations)
       - `PRAGMA quick_check;` — must return `ok`
       - `SELECT COUNT(*) FROM <table>` per table — record pre-VACUUM row counts
     - **VACUUM + dump**:
       - `PRAGMA wal_checkpoint(TRUNCATE); VACUUM;` (stable byte image)
       - `SELECT COUNT(*) FROM <table>` per table — record post-VACUUM row counts; **assert equal to pre-VACUUM counts** (any inequality → principal 1B1)
       - `sqlite3 {db} .dump > {db}.sql`
     - **Round-trip validation**: `sqlite3 :memory: < {db}.sql; .tables` matches expected tables AND `SELECT COUNT(*)` per table matches **pre-VACUUM** source counts (fold v4 R-3 — explicit reference point for closed-loop verification)
     - `sha256sum {db} {db}.sql` → `history/flotsam/legacy-bug-dbs-20260419/MANIFEST.txt` (records pre-VACUUM + post-VACUUM row counts + SHA256)
   - Applied to `bug.db`, `bugs.db`, and any other DB surfaced in Phase 0 inventory.

3c. **Deletion** (~15 min; fold R-6/O-8 + v3 R-6 expanded regex):
   - `.env` removal — HEAD-only (explicit acknowledgment):
     - Pre-check: real-credential detection — if ANY hit: **STOP** — principal 1B1 escalation; rotate credentials + decide on history-scrub; separate work.
       - API key prefixes: `(sk-[A-Za-z0-9]{20,}|AKIA[A-Z0-9]{16}|ghp_[A-Za-z0-9]{30,}|xoxb-|Bearer [A-Za-z0-9]{20,})`
       - JWT tokens: `eyJ[A-Za-z0-9_-]{20,}\.eyJ[A-Za-z0-9_-]{20,}\.`
       - Entropy check: any non-comment line with a `=` containing a 32+ char base64/hex/alphanumeric value that does NOT match placeholder patterns (`your_key_here`, `xxxxx...`, `replace_me`, `<KEY>`, `example_...`)
       - `.env` file pattern: `find . -name '.env*' -not -path './.git/*' -not -path './node_modules/*' -not -path './test/test-agency-project/*'` (captured as dedicated Phase 0a artifact `env-file-inventory.txt`; fold v4 R-4; includes `.env.local`, `.env.production`, etc.)
     - If placeholders only: `git-safe rm` specific files (no glob — explicit list from Phase 0 inventory)
     - Commit message states: "remove .env files from tree HEAD; **history retention intentional** — follow-up issue filed for optional history scrub. Any real credentials previously present have been rotated." (fold R-6 — commit message honest)
     - File a follow-up GH issue: "History scrub for .env files (optional; force-push coordination required)"
   - `git-safe rm agency/bug.db agency/bugs.db` (extracted in 3b)
   - Other confirmed-dead files per Phase 0 inventory
   - Commit.

**Gate 3 exit** (`gate-check-3.sh`):
- All archived dirs under `history/flotsam/` with `HISTORICAL-PATH-NOTE.md`
- DB dumps validated (integrity + quick_check + foreign_key_check + WAL checkpointed + row counts verified)
- No `.env` files at repo root (HEAD-only; history scrub follow-up filed)
- No `claude/principals/`, `claude/plans/`, `claude/proposals/` (except `workstreams/proposals/` held per fold P-9), `claude/reviews/`, `claude/knowledge/`
- `agency/workstreams/gtm/` + `agency/workstreams/proposals/` present with TODO markers
- `PHASE-CURSOR.txt` phase-3 chain-hash entry

**MAR checkpoint 3→3.5** — 2 reviewers (risk, verification).

### Phase 3.5 — Workstream Content Split (~20 min; fold V-4)

**Objective:** Split `agency/workstreams/captain/` per content-type (3 destinations, not 2).

**Triage rules** (fold R-11 — explicit decision tree):
- **Filename matches `*-handoff*.md`** → `usr/jordan/captain/history/flotsam/` (personal state)
- **Filename matches `dispatch-*.md`** or `*-dispatch-*.md` → `agency/workstreams/the-agency/history/legacy-captain-workstream-20260419/` (shared artifact)
- **Filename matches `dialogue-transcript*.md`** AND dated 2026-04-19 (this reset's own transcript) → `agency/workstreams/the-agency/transcripts/dialogue-transcript-20260419.md` (**ACTIVE**, not archived; fold V-4)
- **Filename matches other transcript** → `agency/workstreams/the-agency/history/legacy-captain-workstream-20260419/`
- **Filename matches `seed-*.md`** → `agency/workstreams/the-agency/history/legacy-captain-workstream-20260419/`
- **Any file** → pre-move secret-scan (`grep -rEi '(api[_-]?key|bearer|secret.*=|password.*=|sk-[A-Za-z0-9]{20,})'` on the file); any hit → principal 1B1 before move.
- **Anything else** → captain inspects + decides; log decision in audit log.

**Operations:**
1. Apply triage file-by-file using `git-rename-tree`
2. `HISTORICAL-PATH-NOTE.md` in each destination dir
3. Commit.

### Phase 3.6 — Workstream Consolidation + Sensitive-Dir Re-baseline (`workstreams/agency` + `workstreams/housekeeping`; fold A-7 + v3 V-5/R-11)

**Objective:** Consolidate the ambiguous root-level workstream dirs (PVR §4.4 required). **Re-baseline sensitive-dir SHA256 manifest post-rename (fold v3 V-5/R-11) for Phase 4 supply-chain comparisons against post-rename paths.**

**Operations:**
1. For each of `agency/workstreams/agency/` and `agency/workstreams/housekeeping/`: apply the Phase 3.5 triage rules (personal / shared / active transcript) to move content into:
   - `usr/jordan/captain/history/flotsam/` (personal state)
   - `agency/workstreams/the-agency/history/legacy-{agency,housekeeping}-workstream-20260419/` (shared)
2. `HISTORICAL-PATH-NOTE.md` in each destination
3. **Re-baseline sensitive-dir SHA256** (fold v3 V-5/R-11): rebuild `sensitive-dirs-sha256.txt` over current (post-Phase-1-rename) paths in `agency/hooks/`, `agency/tools/`, `.claude/`. Commit the refreshed manifest. Phase 4 supply-chain check uses THIS refreshed baseline, not Phase 0a's pre-rename version.
4. Commit.

**Gate 3.5+3.6 exit** (`gate-check-3.5.sh` + `gate-check-3.6.sh`):
- `agency/workstreams/` contains only: `the-agency/, mdpal/, mock-and-mark/, iscp/, devex/, designex/, gtm/ (TODO-hold), proposals/ (TODO-hold)` and expected per-app workstreams
- `agency/workstreams/captain/` absent
- `agency/workstreams/agency/` absent
- `agency/workstreams/housekeeping/` absent
- Active dialogue transcript at `agency/workstreams/the-agency/transcripts/dialogue-transcript-20260419.md`
- `PHASE-CURSOR.txt` phase-3.5 chain-hash entry

**MAR checkpoint 3.5→4** — 3 reviewers (operations, verification, risk).

### Phase 4 — Reference Sweep (~85 min — 60 min fan-out + 25 min serialized verification)

**Pre-Phase-4:**
1. `ref-inventory-gen --partition --subagents A,B,C,D,E --exclude <out-of-scope list>` → 5 concrete subagent manifests (files)
2. `subagent-overlap-check` → detect content-duplication across subagent scopes; any overlap assigned to one subagent exclusively OR flagged for serial-merge-order (fold R-3)
3. Sensitive-dir baseline hash comparison point (already captured Phase 0a)

**Orchestration** (fold O-4 + v3 O-2 subagent handoff + v3 R-2 worktree isolation):
- **Mechanism**: Captain uses Task-tool subagents (in-conversation general-purpose agents) with scope-limited prompts. NOT worktree-workflow agents, NOT /dispatch.
- **Parallelism**: 5 subagents spawn in one Agent-tool batch (single captain message, 5 parallel invocations).
- **Subagent-to-captain handoff** (fold v3 O-2): subagent does NOT write directly to captain's git working tree. Subagent runs `agency-sweep --apply --manifest {X}.yaml --output-patch` and returns a **structured patch description** (file list + per-file unified diff). Captain applies the patch to the corresponding worktree serially (prevents concurrent-index-lock races).
- **Worktree isolation** (fold v3 R-2): captain creates 5 dedicated worktrees pre-fan-out: `git worktree add .reset-wt/subagent-{X} reset/subagent-{X}`. Captain applies each subagent's returned patch inside that worktree, commits there, then verifies. Post-Phase-4 merge, worktrees cleaned up (`git worktree remove`).
- **Serialization with ownership_priority order** (fold v4 R-2): captain processes completed subagent patches in `ownership_priority` order (A=1 first, then B, C, D, E), NOT arrival order. Rationale: deterministic replay across reset attempts; if A and E both arrive at t=10, A is applied/verified first even if E arrived milliseconds earlier. Nondeterminism from arrival-order eliminated.
- **Verification budget**: ~5 min × 5 = 25 min allocated (included in Phase 4's 85-min total per fold v3 O-3).
- **Branch naming**: `reset/subagent-{X}` branches created in parallel worktrees.

**Per-subagent operation:**
- Input: `subagent-{X}-manifest.yaml` (files + allowed_substitutions + rejected_substitutions + expected_changes)
- Command: `agency-sweep --apply --manifest subagent-{X}-manifest.yaml --branch reset/subagent-{X}`
- Output: subagent branch with exactly those changes; subagent writes `subagent-{X}-receipt.md` (informational)
- Subagent's BATS run deferred to merged state (fold R-7: avoid shared-fixture collision — per-subagent branch BATS is ONLY scope-local, cross-scope BATS runs post-merge)

**Captain verification per subagent** (5 checks; fold O-11):
1. `git-safe diff --stat reset/subagent-{X}` — file list ⊆ manifest (mechanical via `subagent-scope-check`)
2. `subagent-scope-check --manifest ... --branch ...` — programmatic scope + **non-emptiness assertion** (fold V-9)
3. `subagent-diff-verify --manifest ... --branch ...` — every changed line reconstruction passes (fold O-5/V-3/R-8: substring-level, multi-sub-per-line, whitespace-reject, file-type-reject-list)
4. `ref-inventory-gen --post --scope-manifest subagent-{X}-manifest.yaml` — expected delta achieved; zero unknown outside allowlist
5. **Scope-local BATS only** (fold O-11/R-7): BATS tests that exercise files in manifest scope (declared per tool: `test-scope: local | cross`). Cross-scope BATS runs post-merge.

Any of 1-5 fails → reject branch; subagent redoes; captain re-verifies.

**Merge** — each subagent branch merges into `reset/phase-4-merged` as separate commit (5 commits):
- `feat(v46.0): Phase 4A — tool refs swept (subagent A)`
- `feat(v46.0): Phase 4B — doc refs swept (subagent B)`
- `feat(v46.0): Phase 4C — test refs swept (subagent C)`
- `feat(v46.0): Phase 4D — discovery-surface body refs swept (subagent D)`
- `feat(v46.0): Phase 4E — config refs swept (subagent E)`

**Post-merge full BATS** (fold R-7): captain runs complete BATS suite ONCE on `reset/phase-4-merged` (not per-subagent-pre-merge — avoids shared-fixture corruption from parallel runs).

**Supply-chain check** (expanded; fold V-12/R-1 + v3 R-9 deletion assertion):
- `git-safe diff --name-status reset/phase-4-merged^..reset/phase-4-merged | awk '$1=="A"' | grep -E '^(A\s+)?(agency/hooks|agency/tools|\.claude)/'` — **zero NEW (added) files** in sensitive dirs (sweep is edits-only; fold R-12)
- `git-safe diff --name-status reset/phase-4-merged^..reset/phase-4-merged | awk '$1=="D" || $1~/^R/' | grep -E '^(D|R\d+)\s+(agency/hooks|agency/tools|\.claude)/'` — **zero DELETED AND zero RENAMED files** in sensitive dirs (fold v3 R-9 + v4 R-5: catches accidental/malicious deletions AND renames-out; sweep is content-edit-only, no structural moves permitted in sensitive dirs)
- **Sensitive-dir SHA256 check** (fold V-12/R-1 + v3 V-5/R-11): for every file in `agency/hooks/`, `agency/tools/`, `.claude/` NOT in any subagent manifest, SHA256 matches **refreshed `sensitive-dirs-sha256.txt` from Phase 3.6** (unchanged). For files IN a manifest, `subagent-diff-verify` already covered them. Union proves supply-chain integrity.

**Gate 4 exit** (`gate-check-4.sh`):
- 5/5 subagent branches pass all 5 checks
- Merge commits clean (5 commits); revertable per subagent
- `ref-inventory-gen --post --strict` exits 0 (zero unknown; zero non-allowlisted `claude/...`)
- Supply-chain check passes (zero NEW files + SHA256 match for untouched)
- Post-merge full BATS green (pass-count ≥ baseline pass-count; fail-count == 0)
- `PHASE-CURSOR.txt` phase-4 chain-hash entry

**MAR checkpoint 4→4.5** — **FULL 4-LENS** (architect, operations, verification, risk).

### Phase 4.5 — @import + settings.json + Shim Cleanup (~15 min; ATOMIC; fold R-5)

**Objective:** Rewrite `@import` paths (LAST — per R6); update `.claude/settings.json`; clean up Phase 1 alias-shim.

**Entry check** (fold v3 R-3 shim resilience): BEFORE starting Phase 4.5, captain asserts `test -f <shim-path>` passes; if shim missing, re-create from `usr/jordan/captain/reset-baseline-20260419/reset-shim.sh` template before proceeding.

**Atomic operation** (fold R-5 + v3 O-4 retry diagnostic):
1. Stage: rewrite root `CLAUDE.md` @imports (`@claude/` → `@agency/`)
2. Stage: rewrite `.claude/settings.json` hook paths (`$CLAUDE_PROJECT_DIR/claude/hooks/` → `$CLAUDE_PROJECT_DIR/agency/hooks/`)
3. Stage: rewrite `.claude/agents/**/*.md` `@import` headers (incl. `.claude/agents/jordan/iscp.md` → `@agency/agents/workstream-lead/agent.md` per fold A-11 + designex owned here per v3 A-2: **Phase 4.5 owns ALL `.claude/agents/**/*.md` @import headers including designex**; Phase 2f writes designex body + initial @import POST-rename, Phase 4.5 confirms/adjusts)
4. Stage: remove Phase 1 alias-shim — `rm usr/jordan/captain/reset-baseline-20260419/reset-shim.sh` (no tree-level cleanup needed — shim was untracked/session-scoped per Principle 12)
5. **Pre-commit verification** (on UNCOMMITTED tree):
   a. `agency-sweep --dry-run` on entire tree — must show 0 substitutions that would change anything outside allowlist
   b. `ref-inventory-gen --post --strict` exits 0
   c. `import-link-check` exits 0 (every @import + required_reading resolves — expanded scope per fold v3 V-4)
   d. BATS `tests/` full green
   e. `commit-precheck` on a newly modified file — passes
   f. `hookify-rule-canary --all` — all rules fire (Phase 5 canary smoke; `.canary` fixtures land in Phase 5 per fold v3 V-9 — here Phase 4.5 just exercises the rules)
   g. **settings.json validation** (fold v3 R-10 + v4 V-2 schema fix): `jq empty .claude/settings.json` (JSON syntax valid). Hook-path-existence check uses the actual Claude Code settings.json schema (`hooks.{PreToolUse,PostToolUse,SessionStart,...}[].hooks[].command` where `command` is a shell string typically referencing `$CLAUDE_PROJECT_DIR/<path>`): extract every `command` string, expand `$CLAUDE_PROJECT_DIR` to repo root, extract first path-looking argument matching `^[^\s]+\.(sh|py|js)$`, assert `test -f`. Any ENOENT → fail. Implementation: `jq -r '.. | objects | .command? // empty' .claude/settings.json | while read cmd; do <extract-path-regex>; test -f "$path" || exit 1; done`
6. **Retry loop** (fold v3 O-4 diagnostic + v3 R-3 shim-safe rollback): if ANY verification fails:
   - Capture failure diagnostic to `usr/jordan/captain/reset-baseline-20260419/phase-4.5-attempt-N.log` (test name, diff-verify output, fail category)
   - `reset-rollback.sh --pre-commit` — wraps `git-safe reset --hard HEAD` with shim-exclusion guard; **NEVER uses `git clean -fd`** (would destroy shim)
   - Re-stage with diagnostic-informed fix
   - Attempt counter max 3; attempt 4 → session-compact + principal 1B1
7. If ALL pass → **single commit**: `feat(v46.0): Phase 4.5 — @import rewrites + settings.json + shim cleanup (atomic)`

**Fleet advisory** (fold R-5 + v3 O-9 overhead reduction):
- **At end of Phase 4 / Gate 4 pass** (not at Phase 4.5 start, per v3 O-9 lead-time): captain dispatches `status:reset-in-flight-window` to fleet — advisory "do not start new sessions on reset branch until Gate 4.5 green"; runs parallel with Phase 4 verification overhead
- Principal 1B1 pre-Phase-4.5 is a SINGLE check-in ("starting 4.5; ETA 20 min; dispatch sent; proceed?"), not a dialogue — not a blocker unless principal says halt.

**Gate 4.5 exit** (`gate-check-4.5.sh`):
- Single atomic commit landed
- `agency-sweep --dry-run` shows 0 out-of-allowlist substitutions
- `ref-inventory-gen --post --strict` returns 0 unknown
- `import-link-check` returns 0 orphans
- Full BATS green
- `test ! -e claude && test ! -L claude` — no claude dir OR symlink at repo root (fold R-9)
- Sensitive-dir SHA256 unchanged for untouched files (vs **Phase 3.6 refreshed** `sensitive-dirs-sha256.txt`; fold v4 V-5)
- `PHASE-CURSOR.txt` phase-4.5 chain-hash entry

**MAR checkpoint 4.5→5** — **FULL 4-LENS**.

### Phase 5 — Hookify Validation (~15 min)

**Objective:** Every hookify rule (count = `hookify-rule-count.txt` from baseline; fold A-13) fires correctly.

**Operations:**
1. `hookify-rule-canary --all` — dry-run each rule per V-6/O-17 canary protocol (synthetic payload matching rule's regex, asserts expected block/warn/inform behavior; NEVER executes actual blocked command)
2. Each rule's `.canary` file lives alongside it (`agency/hookify/{rule}/{rule}.canary`); canary's first line declares expected match-key

**Gate 5 exit** (`gate-check-5.sh`):
- N/N hookify rules fire correctly (N = baseline count; fold A-13)
- `agency/hookify/` contains one `.canary` per rule
- No ENOENT on any live path in any rule body
- `PHASE-CURSOR.txt` phase-5 chain-hash entry

**MAR checkpoint 5→6** — 2 reviewers (verification, risk).

### Phase 6 — Release Notes + Runbook + PR Assembly (~40 min)

**Operations:**
1. Finalize `agency/workstreams/the-agency/release-notes-v46.0.md` per §0d slots (all sections filled, ≥5 breaking-path before/after examples per fold P-5)
2. Finalize `agency/workstreams/the-agency/migration-runbook-v46.0.md` per §0d slots (symptom-diagnosis-action table + rollback decision tree)
3. **Full post-reset captain smoke battery** (fold V-15 + v3 V-3 — scripted assertions, not green-by-inspection; `smoke-battery.sh` tool with BATS fixture in Phase 0b):
   - `/handoff read` → output parses with declared structure
   - `/dispatch list --json | jq 'length >= 0'`
   - `/flag list --json | jq 'length >= 0'`
   - `/agency-health --json | jq .status == "ok"`
   - `/session-resume --dry-run` exits 0
   - BATS `tests/` parity: pass-count ≥ baseline; fail-count == 0 (fold O-10)
   - `ref-injector` live test: iterate EVERY skill with `required_reading`; each must resolve (fold V-5)
   - `commit-precheck` on post-reset file green
   - ISCP tool battery: `flag create/list/clear`, `dispatch create/read/resolve`, `agent-identity` resolves correctly
   - `skill-validate` green on all skills
   - `skill-verify` green
4. **Import-resolution smoke test** (fold O-13 + v3 O-8 honest naming): captain spawns a fresh Task-tool subagent with directive "read CLAUDE.md, list skills, invoke /handoff read, report." Subagent inherits captain's hydrated env BUT performs cold @import resolution — surfaces import breakage in the @import chain. **Caveat (v3 O-8)**: this is an INTRA-session import-resolution smoke, not a true adopter-cold-start (adopter's `claude` CLI performs full bootstrap). Genuine cold-start is tested separately in Gate 7 by invoking `claude --one-turn "echo handoff"` in a subprocess and asserting exit 0.
5. **Audit log reconciliation**: `audit-log-reconcile --exit-nonzero-on-delta` against `reset-audit-20260419.log` vs reset-branch commits. Zero delta (set-based per §Audit log).
6. Commit audit log + reconciled cursor chain as Phase 6 deliverable.
6.5. **QGR v46.0 aggregation** (fold v3 O-5): Aggregate all 9 continuous-MAR checkpoint receipts (0→1, 1→2, 2→3, 3→3.5, 3.5→4, 4→4.5, 4.5→5, 5→6, 6→merge) into single artifact `agency/workstreams/the-agency/qgr/qgr-v46.0-reset-20260419.md` — references phase-cursor chain-hash as proof-of-gate-passage, summarizes each checkpoint's findings + folds. `pr-create` reads this as the QGR receipt. If `pr-create` tool does not accept this shape, patch is a Phase 0b deliverable.
7. **PR creation** (fold O-15 — decision):
   - **Use `./agency/tools/pr-create`** (safe tool, not raw `gh`). This reset's scope satisfies `/release` requirements modulo version-bump — captain manually bumps `agency/config/manifest.json` to `46.0.0` pre-PR creation, commits as part of the same phase, then invokes `pr-create --title "D45-Rn: the-agency v46.0 Structural Reset" --body "<full body>"`.
   - `/release` skill is NOT invoked as a single skill — its sub-steps (commit-precheck, push, pr-create) are performed inline because this work already has QGR-equivalent via the continuous-MAR chain, not the standard QG.

**Gate 6 exit** (`gate-check-6.sh`):
- Release notes + runbook complete with all §0d slots filled
- `smoke-battery.sh` exits 0 (scripted green, not inspection)
- Cold-start smoke subagent returns green
- Audit log reconciled (zero delta)
- Version bumped in manifest.json (`46.0.0`)
- PR created via `pr-create`; PR body includes scope, test plan, rollback plan, adopter-facing migration instructions, runbook link
- `PHASE-CURSOR.txt` phase-6 chain-hash entry

**MAR checkpoint 6→merge** — **FULL 5-LENS** (architect, operations, verification, risk, product).

**PR open; principal review + approve; `pr-merge --merge` (never squash, never rebase).**

### Gate 7 — Post-merge Master Smoke (~10 min; captain on master)

**Operations:**
1. `/post-merge` skill
2. Re-run full `smoke-battery.sh` on master HEAD
3. Re-run cold-start smoke on master
4. If RED: `pr-merge revert` BEFORE any fleet dispatch
5. If GREEN:
   - Create GitHub release with release notes body (via `gh release create v46.0`)
   - Broadcast `main-updated` to fleet agents (per `/sync-all`)
   - **Cross-repo dispatch to monofolk via PR in monofolk repo** (fold O-16): open PR in monofolk with migration runbook pointer + post-v46 sync instructions; dispatch `main-updated-v46` with migration runbook path after PR opens
   - Cross-repo dispatch to all worktree agents; worktrees rebase on their own cadence (async; captain tracks 9 green receipts as milestone — not blocking Gate 7 exit)

**Gate 7 exit** (`gate-check-7.sh`):
- Master `smoke-battery.sh` exits 0
- Master cold-start smoke green
- GitHub release created
- Monofolk PR opened (not direct-push per memory)
- Fleet dispatched
- v46.0 release tag on origin

## 4. Continuous-MAR Discipline (summary, updated)

| Checkpoint | Lenses | Trigger |
|---|---|---|
| 0→1 | operations, verification, **product** (fold P-14) | After Phase 0 tool build |
| 1→2 | architect, verification | After Great Rename |
| 2→3 | architect, operations, risk | After subdir reorg |
| 3→3.5 | risk, verification | After archive/extract/delete |
| 3.5→4 | operations, verification, risk | Before subagent fan-out |
| 4→4.5 | **4-lens** | After subagent merge |
| 4.5→5 | **4-lens** | After @import rewrite |
| 5→6 | verification, risk | After hookify canary |
| 6→merge | **5-lens with product** | Pre-PR-open |

Zero-defer, per-checkpoint 15-min fold budget, max 2 re-MAR cycles, session-compact escalation (fold O-1/O-12).

## 5. Rollback Paths (expanded; fold P-4)

- **Remote/origin**: `v45.3-pre-reset` tag — master reset-merge if PR lands bad
- **Per-subagent Phase 4**: each subagent branch tagged `reset/subagent-{X}-pre-merge` before merge commit
- **Per-phase Phase 2/3**: atomic sub-phase commits; `git-safe reset --hard HEAD^` (fold O-14 — correct command) undoes the most recent commit
- **Pre-commit within phase**: `reset-rollback.sh --pre-commit` (wraps `git-safe reset --hard HEAD` with shim-exclusion guards). **`git clean -fd` without `-e` exclusions covering shim + baseline dir is FORBIDDEN during reset execution** (fold v3 R-3/R-8). Always use `reset-rollback.sh` wrapper.
- **Adopter local**: `v45.3-pre-reset-local` tag from `agency-migrate-prep`
- **Adopter `--migrate-back`**: BATS-tested round-trip (content-inventory.sha256 equivalence modulo prep artifacts; dirty-tree refusal; `--force` override)

## 6. Adopter-Facing Tool UX Contract (fold P-6)

For `agency-migrate-prep`, `agency-verify-v46 --customer`, `agency-report`, `agency update --migrate`, `agency update --migrate-back`:

**Invocation signature**: `agency-{tool} [--flag]...`; `--help` returns usage synopsis + all flags + exit codes.

**Output format**: newline-per-event human-readable default; `--json` emits structured JSON (keys: `event`, `severity`, `path`, `message`).

**Exit codes**: 0 success; 1 user-facing failure (actionable error message); 2 framework failure (runbook pointer); ≥10 reserved for specific gate failures (documented per tool below).

**Per-tool reserved exit codes** (fold v4 P-4):

| Tool | Exit codes (specific) |
|---|---|
| `agency-verify-v46 --customer` | 10=tree-shape mismatch; 11=settings.json stale; 12=agent-registration mismatch; 13=ISCP smoke fail; 14=hook-path ENOENT |
| `agency-migrate-prep` | 10=prep marker already present (idempotent noop warning); 11=sweep dry-run found unresolvable pattern; 12=config update failed; 13=backup tag creation failed |
| `agency update --migrate` | 10=version gate refused (no `--migrate`); 11=prep marker missing; 12=mid-update integrity check failed |
| `agency update --migrate-back` | 10=dirty tree refusal (use `--force` with care); 11=no `v45.3-pre-reset-local` tag; 12=dispatch rescue had un-rescuable entries (non-fatal; review log) |
| `agency-report` | 10=no verify-v46 diagnostic to report; 11=cross-repo issue creation failed; 12=dispatch send failed |

**Default safety**:
- `agency-sweep` → `--dry-run` default; `--apply` requires explicit flag
- `agency-migrate-prep` → prompts for confirmation before destructive substitution step; `--yes` flag to bypass for automation
- `agency update --migrate` → refuses without `.agency/migrate-prep-v46.ok` marker
- `agency update --migrate-back` → refuses on dirty tree; `--force` override with warning

**Idempotency**: all tools safe to re-run; rerun on done-state reports no-op. State captured in `.agency/` markers.

**Help text**: each tool has `--help` output that includes a 1-line purpose + 3 most-common usage examples.

BATS fixtures (Phase 0b) include adopter-UX assertions: help-text present, --json schema valid, exit code per scenario.

## 7. Privileged-Ops Table (fold O-7)

Every raw-tool invocation during reset routes through a safe wrapper or explicit `AGENCY_ALLOW_RAW=1` with audit entry:

| Operation | Wrapper | Bypass | Audit entry fields |
|---|---|---|---|
| `git mv {src} {dst}` | `git-rename-tree` | Internal `AGENCY_ALLOW_RAW=1` | `cmd`, `src`, `dst`, `rationale="phase-N rename"` |
| `git mv {src} {dst}` (single file) | `git-rename-tree` (handles both) | Internal | Same |
| `git rm {file}` | `git-safe rm` | Internal if configured, else explicit `AGENCY_ALLOW_RAW=1` | `cmd`, `file`, `rationale` |
| `git reset --hard` | `reset-rollback.sh --pre-commit` / `--post-commit-phase-revert` / `--full-reset-to-tag` | Explicit `AGENCY_ALLOW_RAW=1 git reset --hard` (if wrapper insufficient) | `cmd`, `target`, `rationale` |
| `git clean -fd` | FORBIDDEN during reset without `-e` exclusions (shim + baseline dir); use `reset-rollback.sh` instead | Explicit `AGENCY_ALLOW_RAW=1 git clean -fd -e usr/jordan/captain/reset-baseline-20260419 -e <shim-path>` (fold v3 O-7) | `cmd`, `excludes`, `rationale` |
| `git stash`, `git cherry-pick` | NOT permitted in reset; reach for them = forced session-compact + principal 1B1 | n/a | n/a |
| `git commit` | `/git-safe-commit` | n/a (commit skill handles) | n/a |
| `git push` | `git-captain push` | captain-only | n/a |
| `git tag` | `git-captain tag` | captain-only | n/a |
| `rm -r` on tracked files | `git-safe rm -r` | Internal | Same as `git rm` |
| `rm` on untracked files | raw `rm` acceptable | n/a | Optional audit |

Gate checks assert audit log contains bypass entry per raw invocation (matching phase).

## 8. Success Criteria (expanded; fold P-10 adopter-outcome SCs)

1. `agency init` on bare repo scaffolds v46.0 structure
2. `agency update --migrate` v45.x → v46.0 on v45.3 snapshot passes `agency-verify-v46 --customer`
3. `agency update` (no `--migrate`) v45.x → v46.0 REFUSES with runbook pointer
4. BATS parity: pass-count ≥ baseline; fail-count == 0 (fold O-10)
5. All hookify rules fire canary post-reset
6. `agency-health` green on master post-merge
7. Every worktree reports green after rebase
8. Zero broken `@import` (via `import-link-check` + live `ref-injector` test per skill; fold V-5)
9. Every file's `git log --follow` preserves pre-reset history
10. **Migration runbook includes before/after examples for ≥5 breaking-path categories** (fold P-5)
11. `--migrate-back` round-trip BATS-tested (content equivalence + dirty-tree refusal + --force override; fold V-7/R-13)
12. Audit log reconciles zero-delta (fold O-6/V-1)
13. No `.env` files at repo root; HISTORICAL retention acknowledged + follow-up issue filed (fold R-6)
14. No legacy root-level subdirs at tree root
15. `.claude/` preserved with Anthropic discovery semantics intact
16. **Cross-repo monofolk smoke passes `agency-verify-v46 --customer`** after migration
17. ISCP tools resolve correctly in post-reset agent identity
18. Zero supply-chain NEW files in sensitive dirs + SHA256-unchanged for out-of-manifest files
19. **Adopter outcome A** (fold P-10 + v3 P-7 measurable + v4 P-1 scope clarified): Monofolk completes v45.x → v46.0 migration with **≤1 `agency-report` invocation AND 0 principal-initiated dispatches ABOUT MIGRATION ISSUES** to the-agency/captain (measured via audit log post-migration with dispatch-subject classifier). Unrelated concurrent dispatches (other workstreams) don't count. Hard metric — not subjective.
20. **Adopter outcome B** (fold P-10): Post-migration monofolk reports a round-trip dispatch (create → read → resolve) working at v46.0 format
21. PHASE-CURSOR chain-hash validates end-to-end (no tampered entries)

## 9. Zero-Defer Policy (binding — unchanged)

- Every MAR finding ≥50 accepted and folded before next phase starts
- No "defer post-merge", no "later release", no severity-based skip
- Structural gaps → re-MAR; iterate until clean
- Findings needing principal 1B1 → flagged, raised, resolved before execution

## 10. Open Questions (principal review required)

**None currently requiring principal 1B1.** Folded findings either captured by Plan-v2 1B1s OR resolved within captain scope per standing directives. If Plan-v3 MAR surfaces questions that captain cannot decide autonomously, they're flagged here.

---

**Plan v4 status:** v2 + v3 ≥50-finding folds all applied. v3 re-MAR convergence: 78 → 49 findings, 29 → 1 HIGH (R-3 shim-resilience, folded in Principle 12). Awaiting Plan-v4 re-MAR. On re-MAR clean pass (expected trivial findings given convergence pattern), Plan v4 is execution-ready.

**v3 → v4 folded additions** (v3 re-MAR ≥50 findings folded):
- v3 R-3 HIGH (shim resilience): Principle 12 expanded; `reset-rollback.sh` wrapper in Phase 0b
- v3 O-1 (time budget reconciliation): table fixed, 345 exec + 35 MAR = 380 min; breakpoints pre-declared
- v3 O-2 (subagent→captain handoff): patch-return model via `agency-sweep --output-patch`
- v3 O-3 (Phase 4 verification budget): Phase 4 now 85 min (60 fan-out + 25 verification)
- v3 O-4 (Phase 4.5 retry diagnostic): per-attempt logs + attempt counter
- v3 O-5 (QGR aggregation): step 6.5 `qgr-v46.0-reset-20260419.md`
- v3 O-8 (cold-start honest): renamed to "import-resolution smoke" + true cold-start in Gate 7
- v3 O-9 (fleet advisory overhead): moved to Phase 4 / Gate 4 lead-time
- v3 O-10 (agency-sweep cascade): BATS coverage + principle
- v3 R-1 (overlap resolution): `ownership_priority` in manifest + resolution plan artifact
- v3 R-2 (worktree isolation): 5 dedicated worktrees pre-fan-out
- v3 R-4 (DB integrity ordering): checks BEFORE VACUUM; pre-VACUUM row counts
- v3 R-5 (symlink check scope): tree-wide `find`
- v3 R-6 (.env regex): JWT + entropy + `.env.*` file pattern enumeration
- v3 R-8 (reset-rollback wrapper): Phase 0b tool
- v3 R-9 (deleted files): zero-DELETED assertion in supply-chain
- v3 R-10 (settings.json syntax): `jq empty` + hook-path-existence check at Phase 4.5 step 5g
- v3 R-11/V-5 (sensitive-dir SHA256 refresh): rebuilt at Phase 3.6
- v3 V-1 (v45.3-snapshot-fixture): via `test/test-agency-project/` substrate + `git archive`
- v3 V-3 (smoke-battery.sh): in Phase 0b tool table with BATS
- v3 V-4 (import-link-check scope): expanded to agents/templates/hookify inline patterns
- v3 A-2 (designex @import ownership): Phase 4.5 exclusive for all `.claude/agents/**/*.md` @import headers incl. designex
- v3 P-1 (test fixture wording): "embedded git repo" not "submodule"
- v3 P-2 (dispatch rescue path): in `--migrate-back` tool + rollback table
- v3 P-3 (per-change adopter impact): each "What changed" bullet gains impact line
- v3 P-7 (SC 19 measurable): ≤1 agency-report + 0 principal pings
- v3 P-8 (templates move): in "What changed" list

**Low-priority residuals deferred** (<50 scored; not blocking):
- A&D micro-amendment log for src/ scope expansion (v3 A-7; documentation polish)
- test-scope tagging protocol formalization (v3 A-8; implicit in tool builds)
- VACUUM-on-copy option (v3 A-6; current in-place VACUUM is operationally fine per v3 R-4 reorder)
- STUB-PHASE-6 marker convention (v3 V-6; section-level filled-vs-empty is visually obvious)
- gate-check multi-criterion BATS count >50 (v3 V-11; already reflected in ≥50 min-test declaration)
