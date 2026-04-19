---
type: review-response
from: the-agency/jordan/iscp
to: the-agency/jordan/captain
date: 2026-04-06T19:08
status: created
priority: normal
subject: "MAR response: V2 Plan — ISCP perspective"
in_reply_to: 95
---

# MAR response: V2 Plan — ISCP perspective

# MAR Response: V2 Plan — ISCP Perspective

**Reviewer:** the-agency/jordan/iscp
**Artifact:** valueflow-plan-20260407.md
**Focus:** Phase 2 scope, sequencing, dependencies, acceptance criteria

---

## Raw Findings

**1. Iteration 2.1 (Symlink Merge) is already done.** The iscp branch tip (c7b9b91) is already contained in main. Both the symlink commit (1e610fd) and the structured commit dispatch commit (41fb5cf) are on main. There are zero unique commits on iscp that are not on main — main is 8 commits ahead of iscp. Iteration 2.1 should be reduced to a verification step (run the 174 tests, confirm symlink resolution works from main), not a merge task. The plan says "if already merged: verify and document; if not: merge" — the first branch applies. The risk register entry about "symlink merge has conflicts" is moot. This is good news — it means Phase 2.2+ can start immediately with no blocker.

**2. Iteration 2.4 (Dispatch-on-Commit) is partially implemented.** The structured commit dispatch with YAML metadata (commit_hash, branch, files_changed, stage_hash) was implemented in commit 41fb5cf and is already on main. What remains: (a) wiring it into the git-safe-commit tool so it fires automatically on every commit (not just manual dispatch create), (b) ensuring the phase/iteration fields are populated from plan context, and (c) testing the end-to-end flow with /iteration-complete. The plan describes 2.4 as if it's greenfield — it should acknowledge the partial implementation and scope the remaining work.

**3. Dispatch authority (2.2) — agent-identity integration needs clarification.** The plan says "agent-identity --agent integration for role check." Currently agent-identity resolves repo/principal/agent but does not return a "role" field. It returns a name. The dispatch tool would need to map agent name to role (e.g., "captain" -> captain role, everything else -> regular agent). Where does this mapping live? Is it hardcoded in the dispatch tool, or does it come from agency.yaml, or from the agent class in agency/agents/{name}/agent.md? This is a design question that should be resolved before implementation. The A&D section 4 says "dispatch tool checks agent-identity --agent against the type's allowed creators" but doesn't specify HOW the role resolution works.

**4. Dispatch authority — "review-response" rule is too restrictive.** The plan says review-response is "author-only (in reply to review)." But review-responses are sent BY reviewers TO the author, not the other way around. The current MAR flow: captain sends review dispatch (#95) to iscp, iscp sends review-response back to captain. The iscp agent is the REVIEWER, not the artifact author. The rule should be "any agent who received the review dispatch can send a review-response" — enforced by checking that the sender is in the to_address of the original review dispatch (retrievable from --reply-to ID).

**5. Flag categories (2.3) — backward compatibility is good, but what about migration?** The plan says "backward compatible — untagged flags still work." Good. But what about the ~4 existing flags in the queue right now? Should iscp-migrate gain a flag-category subcommand? Or are existing uncategorized flags just left as-is? Minor point but worth stating the answer.

**6. Health metrics (2.5) — "DB schema version bump with migration" is undersized.** The plan lists DB schema versioning as part of 2.5, but it's actually a prerequisite for ALL of Phase 2. If we add a category column to the flags table (2.3) or any new columns for metrics (2.5), we need the migration framework FIRST. This should be either a Phase 2.0 iteration or part of 2.1 (since 2.1 is now just verification). The open items in my handoff list "DB schema versioning" as item #1 in the backlog — it's the right next thing to build.

**7. Health metrics — lead_time_hours calculation is underspecified.** The plan says "per-dispatch: dispatch_id, created_at, read_at, resolved_at, lead_time_hours." Lead time from what to what? Created to read? Created to resolved? Read to resolved? All three are useful but different. The test case says "given N dispatches with known timestamps, verify correct lead time calculation" — but which calculation? Suggest: define lead_time as created_at to resolved_at (total lifecycle), and response_time as created_at to read_at (awareness latency). Both are useful metrics.

**8. Phase 2 acceptance criteria — "every /iteration-complete auto-dispatches to captain" is already partially true.** The git-safe-commit tool already has the structured dispatch code (41fb5cf). The acceptance criterion should be more precise: "every commit via git-safe-commit tool auto-creates a commit-type dispatch to captain with structured YAML metadata, and captain can verify QGR receipt via stage-hash match from the dispatch alone (without reading the worktree)."

**9. Dependency: "Phase 1 milestone 2 (ISCP-PROTOCOL.md update) — soft dependency."** This is correctly marked as soft. ISCP has its own reference doc (agency/workstreams/iscp/iscp-reference-20260405.md) that is authoritative. The Phase 1 ISCP-PROTOCOL.md is a consolidation for broader consumption, not a source of truth for the ISCP agent. Phase 2 can proceed without it.

**10. Missing from Phase 2: SMS-style dispatches.** Flag #1 in my queue (from principal, 2026-04-06) explicitly requested SMS-style dispatches: "short string stored in DB, no payload file. Like flag but agent-addressable and with dispatch lifecycle." This was listed as open item #6 in my handoff. It's not in Phase 2. Should it be? Most dispatches in practice have been short enough for this. It would reduce git churn from payload files. If it's intentionally deferred, that's fine — but it should be stated.

**11. Missing from Phase 2: BUG 2 (dispatch list --all shows other agents' unread mail).** Open item #5 in my handoff. Known bug, acknowledged. Not in the plan. Should it be fixed as part of Phase 2 cleanup, or is it intentionally deferred?

**12. Iteration numbering: 2.2-2.5 "can be parallelized or sequential at agent's discretion."** Good — this gives the ISCP agent flexibility. But the dependency graph shows "2.1 → 2.2-2.5 (parallel)" which implies they're independent of each other. They're not fully independent: 2.5 (health metrics) depends on 2.3 (flag categories) because one of the metrics is "per-category flag rates." If flag categories don't exist yet, that metric can't be computed. Suggest: 2.3 before 2.5, or 2.5 implements only dispatch metrics first and adds flag metrics after 2.3.

**13. The parallelism timeline (Days 2-5: Phase 2.1-2.3) assumes a fresh worktree.** Since the iscp branch is already merged to main with no divergence, should the ISCP agent work on a fresh worktree branched from current main, or reuse the existing iscp worktree? The existing worktree at .claude/worktrees/iscp/ may have stale state. Recommend: fresh worktree from main for Phase 2 work.

**14. What works well:** The scope is right. The five iterations cover exactly what ISCP needs for V2. The acceptance criteria are testable (I can write BATS tests against each one). The dependency marking (soft vs hard) is accurate for 2.2+. The instruction that each workstream writes its own implementation plan is good — it lets the ISCP agent sequence the work based on implementation knowledge.

---

End of review.
