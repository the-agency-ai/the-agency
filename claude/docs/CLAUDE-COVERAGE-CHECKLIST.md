# CLAUDE.md Refactor Coverage Checklist

Maps every section of the original CLAUDE.md to its new location(s). No substantive instruction should be lost.

| Original Section | Lines | New Location | Status |
|---|---|---|---|
| Source of truth preamble | 1-5 | CLAUDE-USER-DRAFT.md §0 | Covered |
| **QG Protocol — 10 Steps** | 7-31 | PM agent §1, refs/quality-gate.md | Covered |
| **QG — Commit Discipline** | 33-39 | PM agent §3, CLAUDE-USER-DRAFT.md §QG (pointer) | Covered |
| **QGR Format — Full template** | 41-135 | PM agent §2, refs/quality-gate.md | Covered |
| **QGR — Issue types/Via/Tests legend** | 52-54 | PM agent §2 (added in enrichment) | Covered |
| **QGR — "Failing MUST be 0"** | 60 | PM agent §2 (added in enrichment) | Covered |
| **QGR — "Zeros are visible"** | 72 | PM agent §2 (added in enrichment) | Covered |
| **QGR — 8-Stage Summary** | 96-127 | PM agent §2 (added in enrichment) | Covered |
| **Commit Message Format** | 139-167 | PM agent §4 (structure + slug rule) | Covered |
| **Commit Message Example** | 168-200 | PM agent §4 (added in enrichment) | Covered |
| **Plan Updates** | 205-215 | PM agent §6, /iteration-complete, /phase-complete skills | Covered |
| **Living Documents** | 217-231 | CLAUDE-USER-DRAFT.md §Living Docs, PM agent §7 | Covered |
| **QG Tooling inventory** | 233-256 | REMOVED (implementation status, not instruction) | Intentional |
| **Dev Methodology — The Flow** | 258-272 | CLAUDE-USER-DRAFT.md §Methodology | Covered |
| **Dev Methodology — Execution** | 274-283 | CLAUDE-USER-DRAFT.md §Execution | Covered |
| **Dev Methodology — Quality Gates** | 285-291 | CLAUDE-USER-DRAFT.md §QG (iteration/phase distinction), refs/development-methodology.md | Covered |
| **Phase Completion procedure** | 292-316 | /phase-complete skill, refs/development-methodology.md, PM agent §3 (landing steps added) | Covered |
| **Pre-Phase Review procedure** | 318-327 | /pre-phase-review skill, PM agent §5, refs/development-methodology.md | Covered |
| **Plan Completion procedure** | 329-336 | /plan-complete skill, PM agent §3 ("notify captain" added) | Covered |
| **Artifacts table** | 338-346 | CLAUDE-USER-DRAFT.md §Artifacts | Covered |
| **File Organization** | 348-375 | CLAUDE-USER-DRAFT.md §File Organization (updated tree) | Covered |
| **Session Handoff — convention** | 377-382 | CLAUDE-USER-DRAFT.md §Session Handoff (Agency 2.0 convention) | Covered |
| **Session Handoff — trigger table** | 384-398 | Triggers encoded in boundary skills + hooks. Captain agent has trigger list. Full table in refs/development-methodology.md | Covered |
| **Session Handoff — what to include** | 400-408 | Encoded in handoff-write.sh hook + boundary skills | Covered |
| **Discussion Protocol** | 410-420 | CLAUDE-USER-DRAFT.md §Discussion Protocol (full 1B1 + inner loop) | Covered |
| **Feedback — Header/Identity** | 422-435 | refs/feedback-format.md, CLAUDE-USER-DRAFT.md §Feedback (pointer) | Covered |
| **Feedback — Structure** | 437-446 | refs/feedback-format.md | Covered |
| **Feedback — Principles** | 448-453 | refs/feedback-format.md | Covered |
| **Testing & Quality — Values** | 455-466 | CLAUDE-USER-DRAFT.md §Testing & Quality | Covered |
| **Testing & Quality — Enforcement** | 468-478 | CLAUDE-USER-DRAFT.md §Testing & Quality (key rules kept: suppress, no-verify, consult) | Covered |
| **Bash Tool Usage** | 480-494 | CLAUDE-USER-DRAFT.md §Bash Tool Usage (slimmed) | Covered |
| **Git — Remote master read-only** | 496-498 | CLAUDE-USER-DRAFT.md §Git | Covered |
| **Git — Never push without permission** | 499 | CLAUDE-USER-DRAFT.md §Git + hookify enforcement note | Covered |
| **Git — /rebase /sync-all local** | 500 | CLAUDE-USER-DRAFT.md §Git | Covered |
| **Git — Hookify enforcement** | 501 | CLAUDE-USER-DRAFT.md §Git (hookify rule names cited) | Covered |
| **Git — Never reset --hard** | 502 | CLAUDE-USER-DRAFT.md §Git | Covered |
| **Git — Fix don't ask** | 503 | CLAUDE-USER-DRAFT.md §Git | Covered |
| **Git — Read don't guess** | 504 | CLAUDE-USER-DRAFT.md §Git | Covered |
| **Git — Post-merge sync** | 505 | CLAUDE-USER-DRAFT.md §Git | Covered |
| **Git — Force-push after sync** | 506 | CLAUDE-USER-DRAFT.md §Git (--force-with-lease added) | Covered |
| **Git — Phase-Iteration slug** | 507 | CLAUDE-USER-DRAFT.md §Git, PM agent §4 | Covered |
| **Sandbox Principle** | 509-520 | CLAUDE-USER-DRAFT.md §Sandbox | Covered |
| **Sandbox Activation** | 522-527 | CLAUDE-USER-DRAFT.md §Sandbox (commands listed) | Covered |
| **Hookify Rules table** | 529-537 | CLAUDE-USER-DRAFT.md §Hookify Rules (3-row table) | Covered |
| **Three Review Tools table** | 539-549 | Captain agent §Three Review Tools, refs/code-review-lifecycle.md | Covered |
| **Captain PR Lifecycle** | 551-567 | Captain agent §PR Lifecycle (8-step flow added) | Covered |
| **Code Review Dispatch** | 569-584 | Captain agent §Code Review Dispatch (added) | Covered |
| **Worktree Dispatch Handling** | 586-618 | Captain agent (pointer to ref), refs/code-review-lifecycle.md | Covered |
| **Review File Convention** | 620-629 | refs/code-review-lifecycle.md | Covered |
| **Why Local Review** | 631-633 | Captain agent §Why Local Review (added) | Covered |

## Summary

- **634 lines** in original → **~145 lines** in CLAUDE-USER-DRAFT.md
- **0 sections lost** — every section mapped to at least one destination
- **1 section intentionally removed** — QG Tooling inventory (implementation status)
- **Key enrichments made:** PM agent got commit example, QGR stages, legend lines, "Failing=0", landing steps. Captain got full PR lifecycle, dispatch, review tools, why local review.
