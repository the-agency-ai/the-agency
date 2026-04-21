# Latent Tool Reference Audit — 2026-04-22

**Repo:** `/Users/jdm/code/the-agency`
**Scope:** `./agency/tools/X` references where `X` does not exist at that path.
**Method:** Grep repo-wide for `agency/tools/[a-zA-Z0-9_.-]+`; exclude `src/archive/**`, `usr/**`, `*/history/**`, `*/qgr/**`, `.claude/worktrees/**`, `*-handoff*.md`. Compare unique tokens to `ls agency/tools/` (files + top-level dirs, ignoring `__pycache__`).
**Purpose:** Catch stale references before V5 Phase 3 (prune) and Phase 4 (src/ split).

---

## Summary

| Metric | Count |
| --- | --- |
| Existing tool entries (files + dirs) | 118 |
| Unique tool names referenced | 204 |
| HEALTHY (referenced AND exists) | 110 |
| REFERENCED-BUT-MISSING | **94** |
| EXISTS-BUT-UNREFERENCED | **8** |

Many of the 94 "missing" entries are placeholders, fragments, or test fixtures rather than real runtime bugs. The triage below separates real breakage from noise.

---

## REFERENCED-BUT-MISSING — triaged

### A. CRITICAL — tool-to-tool calls that will break at runtime

These are live references inside executable tool scripts. They will fail when invoked.

| Missing tool | Refs | Live callers (in `agency/tools/`) |
| --- | --- | --- |
| `agency-whoami` | 7 | `context-save` L105, `commit-prefix` L70, `session-backup` L72, `restore` L75, `context-review` L87, `bug-report` L128-129 |
| `browser` | 4 | `figma-diff` L71, L179, L181, L198 (gated on `-x` check, but the doc string still shows the path) |
| `designsystem-validate` | 5 | `designsystem-add` L203, `figma-extract` L580, L744, plus agent `agency/agents/design-lead/agent.md` |

**Notes:**
- `agency-whoami` was deleted from `agency/tools/` but the logic was moved to `agency/tools/lib/_agency-whoami` and is only invoked correctly via `agency/tools/agency` (L95 sources the lib). All six direct-exec sites listed above still shell out to the deleted binary — they will emit `No such file or directory` at runtime. This is the exact pattern the audit was designed to catch.
- `browser` is guarded by `[[ -x ... ]]` so it fails soft, but the warning message is still printed on every `figma-diff` run.
- `designsystem-validate` is called from two executables plus an agent guide.

### B. HIGH — tool-to-tool calls inside skills/agents/workflows

Invoked from `.claude/skills/*/SKILL.md`, agent files, or hooks. These are runtime paths for user-invoked skills.

| Missing tool | Refs | Notable callers |
| --- | --- | --- |
| `ci-monitor` | 4 | `.claude/skills/monitor-ci/SKILL.md` (primary binary), `REFERENCE-CONTRIBUTION-MODEL.md` |
| `upstream-port` | 6 | `.claude/skills/upstream-port/SKILL.md`, `REFERENCE-CONTRIBUTION-MODEL.md` |

### C. MODERATE — replaced-by-wrapper tools still referenced in docs

All superseded by the consolidated `msg` dispatcher (which itself does NOT exist as a file — see D).

| Missing tool | Refs | Primary callers |
| --- | --- | --- |
| `collaborate` | 8 | REFERENCE-DISPATCH-AND-MESSAGING, REFERENCE-CONCEPTS, REFERENCE-PRINCIPAL-GUIDE, REFERENCE-QUICK-START, REFERENCE-WORKNOTE-parallel-agent-case-study, REFERENCE-BROWSER-MCP |
| `collaboration-respond` | 5 | REFERENCE-PRINCIPAL-GUIDE, REFERENCE-CONCEPTS, REFERENCE-DISPATCH-AND-MESSAGING, REFERENCE-WORKNOTE-parallel-agent-case-study |
| `news-post` | 5 | REFERENCE-PRINCIPAL-GUIDE, REFERENCE-CONCEPTS, REFERENCE-QUICK-START, REFERENCE-DISPATCH-AND-MESSAGING, REFERENCE-WORKNOTE-mvh-build |
| `news-read` | 6 | same set |
| `message-send` | 3 | docs |
| `message-read` | 1 | docs |
| `dispatch-collaborations` | 2 | REFERENCE-CONCEPTS, REFERENCE-WORKNOTE-parallel-agent-case-study |
| `add-principal` | 4 | REFERENCE-PRINCIPALS (documented as the primary onboarding command) |
| `setup-agency` | 6 | REFERENCE-QUICK-START, REFERENCE-SECRETS |
| `enforcement-audit` | 11 | `src/tests/tools/enforcement-audit.bats`, `devex-plan-20260407.md` |
| `iscp-migrate` | 4 | `src/tests/tools/iscp-migrate.bats`, `iscp-ad-20260404.md`, `iscp-reference-20260405.md` |
| `pr-captain-merge` | 1 | skill description only (skill text — `agency/tools/pr-merge` is the live binary) |
| `quality-gate` | 1 | docs |
| `release-cut` | 1 | `README.md` L94 (primary release tool name) |
| `secret-migrate` | 5 | REFERENCE-QUICK-START, REFERENCE-SECRETS |
| `service-add` | 1 | docs (skill exists) |
| `ui-add` | 1 | docs (skill exists) |
| `agency-service` | 25 | Many doc references — retired orchestrator pattern |
| `agency-issue` | 12 | **Note: exists as a tool; only miscount from fragment matches** |
| `test-full-suite` | 4 | REFERENCE-TEST-BOUNDARIES, devex-plan — T3 phase-complete test runner, not yet shipped |
| `agent-bootstrap` | 7 | REFERENCE-WORKNOTE-parallel-agent-case-study, REFERENCE-DISPATCH-AND-MESSAGING, REFERENCE-BROWSER-MCP, REFERENCE-CONCEPTS, REFERENCE-PRINCIPAL-GUIDE, REFERENCE-QUICK-START |
| `iscp-check` — already exists, skip |

### D. PLANNED-BUT-NOT-SHIPPED

Tool is named in design docs / plans but not yet written. Not a bug, but a V5 backlog signal.

| Missing tool | Refs | Source |
| --- | --- | --- |
| `msg` | 14 | REFERENCE-DISPATCH-AND-MESSAGING (it is the replacement wrapper referenced by C) |
| `_py-launcher` | 2 | `plan-abc-stabilization-20260421.md`, `usr/jordan/reports/...python-tools-fail...md` |
| `upstream-port` | 6 | skill exists; binary proposed |
| `test-full-suite` | 4 | see C |
| `iscp-metrics` | 1 | `iscp-ad-20260404.md` |

### E. TEST-FIXTURE PLACEHOLDERS — intentional, ignore

These are synthetic names inside BATS tests (`*.bats`, `test-*.sh`) or skill/example walkthroughs. Not real tool references.

`my-tool` (17), `X` (15), `new-tool` (5), `some-tool` (4), `some-tool.sh` (2), `other-tool` (2), `special-tool` (2), `fake` (1), `fake-tool` (1), `lonely-tool` (4), `framework-tool` (2), `only-framework` (1), `adopter-tool` (2), `orphan-not-in-source` (2), `no-tests-for-me` (2), `my-local-tool` (3), `some-stale-tool` (3), `internal` (1), `name` (2), `nonexistent` (1), `master-file` (3 — a fake file written by `test-worktree-sync.sh`), `tracked.md` (1), `untracked.md` (1), `tests` (5 — subdirectory / placeholder), `starter-verify` (1), `starter-test` (1), `starter-release` (1), `starter-compare` (1), `show-bug` (1), `skill-audit` (2), `skill-create` (1), `preview-broken` (1), `preview-test` (2), `deploy-broken` (1), `deploy-test` (2), `nit-add` (2), `scaffold` (3), `scaffold-backend-nestjs` (1), `scaffold-frontend-nextjs` (1), `transcript` (2), `welcomeback` (1), `widget` (7 — doc example).

### F. REGEX/PARTIAL-MATCH ARTEFACTS — not real references

These counts came from expressions that interpolate variables or include trailing prefix-only strings. Safe to ignore for runtime-breakage purposes.

- `lib` (240) — directory lookups `agency/tools/lib/_xxx` are legitimate; `lib` is the dir, not a tool.
- `git-` (1), `secret-` (10), `preview-` (9), `deploy-` (9), `crawl-` (4), `findings-` (1) — shell-variable interpolations like `agency/tools/secret-${PROVIDER}`.
- `config.` (1), `some-tool.sh` (2), `ref-sweep-allowlist.txt` (8), `agency-bootstrap.sh` (17 — the `.sh` tool does exist), `statusline.sh` (3 — exists) — punctuation tails.
- `git-pr` (1), `aws-setup` (1), `install-hooks` (1), `bats-docker` (1), `agency-verify-v46` (2), `agency-verify` (3), `caf` (2), `mar` (1), `create-project` (1), `dispatch-request` (1), `changelog-monitor` (1), `collaboration-pending` (1), `artifact-list` (1 — exists), `agent-define` (1 — exists), `tool-find` (1 — exists), `add-workbench` (2), `myclaude` (26), `preview-docker-compose` (1) — single-doc mentions of retired/renamed/alternate names.

`myclaude` at 26 refs is worth a second look: grep shows they are inside `agency/tools/project-create` and `agency/tools/launch-project` as literal sample output (agent template text) and in `.md` onboarding docs / agent templates (`generic`, `tester`, `security`, `reviewer`, `docs`). The binary does NOT exist; those scripts write template files that instruct the adopter to create their own `myclaude` (project-specific). This is a documentation convention, not a runtime call. Tagged E-F, not a bug.

---

## EXISTS-BUT-UNREFERENCED — deletion candidates

After excluding the exclude list, these tools are never referenced anywhere in the scanned tree:

| Tool | Status | Notes |
| --- | --- | --- |
| `ghostty-claude-hook` | orphan | Companion `ghostty-*` tools are referenced; this specific hook is not |
| `ghostty-debug-hook` | orphan | Same — debug variant, no references |
| `import-link-check` | orphan | No callers |
| `pr-build` | orphan | No callers |
| `tool-log` | orphan | No callers (note: `log` tool is heavily used — 93 refs) |
| `worktree-delete` | orphan-ish | Skill `/worktree-delete` exists; skill body may invoke differently or via in-Claude tool |
| `worktree-list` | orphan-ish | Same as above — `/worktree-list` skill exists |
| `__pycache__` | non-tool | Python cache dir; should be `.gitignore`d / removed |

**Recommendations for V5 Phase 3 prune:**
- Confirm `ghostty-claude-hook`, `ghostty-debug-hook`, `import-link-check`, `pr-build`, `tool-log` are truly unused before deletion.
- Verify `worktree-delete` / `worktree-list` skill implementations before flagging as orphans — may be invoked via skill body rather than as a file path.
- `__pycache__` should be pruned and added to `.gitignore`.

---

## Top 5 most-referenced MISSING tools (by count, excluding fragments and fixtures)

1. `agency-service` — 25 (retired orchestrator pattern; docs-only but widely cited)
2. `msg` — 14 (planned dispatcher; blocks C-group cleanup)
3. `enforcement-audit` — 11 (has a BATS test; tool itself missing)
4. `collaborate` — 8 (superseded-in-doc; still in 6 REFERENCE docs)
5. `setup-agency` / `news-read` / `agent-bootstrap` (tie at 6-7) — primary onboarding/messaging commands in docs

---

## Surprising findings

1. **`agency-whoami` deletion leaves six live tool scripts broken.** Confirms the V5 Phase -1 hypothesis. `context-save`, `commit-prefix`, `session-backup`, `restore`, `context-review`, `bug-report` all shell out to the deleted binary — all six will emit runtime errors on invocation. The logic moved to `agency/tools/lib/_agency-whoami`, but these scripts were not updated to source the lib. Fix: either restore a thin `agency-whoami` stub that sources the lib, or update all six call sites to invoke the lib directly.

2. **`msg` is the documented successor for SEVEN retired tools but does not exist.** `REFERENCE-DISPATCH-AND-MESSAGING.md` presents a whole migration table pointing to `./agency/tools/msg` as the new canonical interface, but the binary hasn't been shipped. Every reader trying to follow the guide will hit a dead end.

3. **`release-cut` is named as the primary release command in `README.md`, but the tool is `release` (not `release-cut`).** Top-of-funnel onboarding docs point at a nonexistent binary.

4. **`designsystem-validate` is called from inside two live tools** (`designsystem-add`, `figma-extract`) as a follow-up step, plus referenced by the `design-lead` agent guide. Any design-system workflow will emit a broken-pointer message.

5. **`enforcement-audit` has a dedicated BATS test file** (`src/tests/tools/enforcement-audit.bats`) but no implementation. Test is presumably red or skipped; worth a sanity check.

6. **`test-full-suite`** is specified as the T3 (phase-complete) test runner in `REFERENCE-TEST-BOUNDARIES.md` but is not implemented. `/phase-complete` cannot fulfill its documented contract.

7. **`add-principal` vs `principal-create`** — `REFERENCE-PRINCIPALS.md` documents `add-principal` as the command (4 references in examples), but the actual tool is `principal-create`. Doc drift.

8. **`ci-monitor`** is the backing binary for the `/monitor-ci` skill, which is referenced in `REFERENCE-CONTRIBUTION-MODEL.md` as a Captain tool — but the binary does not exist in `agency/tools/`.

---

## Phase 3 prune / Phase 4 split readiness

Before doing Phase 3 deletion or Phase 4 src/ re-layout, the following MUST be addressed:

1. **Fix the six `agency-whoami` call sites** (CRITICAL A-group) — either restore the stub or source the lib directly.
2. **Decide per tool in the D/"planned" group:** write it, remove the docs, or file a V5 backlog entry. Shipping `msg` alone cleans up ~40 cross-references.
3. **Doc sweep pass on REFERENCE/ files** — the dispatch/messaging and principal onboarding docs reference 8+ nonexistent commands each. Either restore the tools or rewrite the docs against surviving tools.
4. **Validate the 5-8 EXISTS-BUT-UNREFERENCED candidates** are truly dead before deletion. Confirm skills don't invoke them via non-file-path mechanisms.
