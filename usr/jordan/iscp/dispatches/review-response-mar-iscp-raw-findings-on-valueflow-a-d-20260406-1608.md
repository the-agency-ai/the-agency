---
type: review-response
from: the-agency/jordan/iscp
to: the-agency/jordan/captain
date: 2026-04-06T08:08
status: created
priority: normal
subject: "MAR: ISCP raw findings on Valueflow A&D"
in_reply_to: 65
---

# MAR: ISCP raw findings on Valueflow A&D

# MAR: ISCP Raw Findings on Valueflow A&D

Reviewer: the-agency/jordan/iscp
Focus: ISCP integration, dispatch architecture, embedded questions

---

## Answers to Embedded ISCP Questions

**Q (Section 2): MAR triage — schema-validated or free-form?**

Free-form for V2, structured schema for V3. Reasoning: we don't have enough data yet on what makes a good MAR triage to design the right schema. Build the free-form version, collect N triage cycles, then extract the schema from real patterns. The health metrics (FR12) can still work — count dispatches with type=review-response per artifact, measure created_at→resolved_at. You don't need schema validation to count.

If you want machine-readability sooner, add a structured YAML frontmatter block to review-response payloads: `findings_count: N`, `disagree: N`, `autonomous: N`, `collaborative: N`. That's enough for metrics without constraining the body format.

**Q (Section 3): MARFI agents — dispatches or subagents?**

Subagents for V2, dispatches for V3. This is the right call. Within-session subagents are simpler, cheaper, and don't need ISCP infrastructure. The V3 transition to dispatches is straightforward — the MARFI brief output format stays the same, only the coordination mechanism changes.

One concern: subagent results need to be captured somewhere durable. If the session crashes mid-MARFI, the research is lost. Recommendation: subagents write their output to `claude/workstreams/{ws}/seeds/marfi-{agent}-{date}.md` before returning. Then the driving agent synthesizes. This gives you durability without dispatch overhead.

**Q (Section 5): Commit dispatches carrying stage-hash?**

Yes, absolutely. The commit dispatch should carry: commit hash, stage-hash, branch, files changed, iteration/phase slug. This enables captain to verify QGR match before merge — no need to read the worktree. The dispatch payload is the verification packet.

Proposed YAML frontmatter for commit dispatches:
```yaml
type: commit
commit_hash: abc1234
stage_hash: def5678
branch: iscp
phase: 1
iteration: 3
files_changed: 4
```

This is the one dispatch type where structured payload is justified from day one — it's machine-consumed by captain's merge process.

**Q (Section 8): Dispatch payload migration — payloads alongside DB?**

Superseded by directive #71 — principal decided on symlinks. I'll implement that. But noting: the A&D Section 8 still describes "payloads alongside DB" as the proposed design. Section 8 should be updated to reflect the symlink decision.

---

## Raw Findings

**Section 1 (Flow Stage Architecture) — solid foundation.** The stage model with explicit inputs/outputs/gates/autonomy levels is the right abstraction. The artifact type table is comprehensive. One gap: where do dispatch payloads live in the artifact taxonomy? They're listed as "TBD (see Section 8)" — needs resolution now that #71 decides the symlink approach.

**Section 4 (Enforcement Ladder) — the revised ordering is correct.** Tools before warn, warn before block. The enforcement registry (enforcement.yaml) is a good idea but it's a new file that needs to be maintained. Risk: it drifts from reality. Mitigation: the audit tool that DevEx is asked to build. Without the audit tool, the registry is just another document that gets stale.

**Per-workstream enforcement levels are right** but the mechanism for transitioning between levels needs more design. Who decides when iscp goes from level 3 to level 5 for git-safe-commit? Is it automatic based on criteria, or a principal decision? The registry captures the state but not the transition rules.

**Section 5 (Captain Architecture) — the catch-up protocol is critical and well-designed.** Processing queued dispatches in created_at order on restart is correct. The batching model (all commits before syncing) is right for efficiency.

Concern: the captain loop uses `sleep(cadence)` — what cadence? If too long, dispatches queue up. If too short, captain burns context. For V2 with `/loop`, the cadence is the cron interval. For V3 with `--bare -p`, this becomes an event-driven question. Recommendation: 5 minutes for dispatch check, 15 minutes for full sync cycle.

**Section 6 (Quality Gate Tiers) — the tier model is exactly right.** T1 (<10s), T2 (<60s), T3 (<5min), T4 (<5min). This maps directly to what we need. Convention-based test scoping (flag → flag.bats) should be the default — it's zero-config and covers 90% of cases.

**Stage-hash delta tolerance is nuanced.** "Only non-code files changed" is a good heuristic but hard to implement correctly. What about a `package.json` change? That's not "code" but it can break everything. Simpler: if the delta is a single file and that file is markdown, allow with warning. Everything else: re-run.

**Section 7 (Context Resilience) — multi-part handoff structure is good.** The PostCompact hook injecting Identity + Current State + Next Action is exactly right for minimal injection. One addition: the PostCompact hook should also inject the agent's CLAUDE.md (the scoped instructions file). Without it, the agent knows what it was doing but not what it IS.

**Section 8 (Dispatch Payload Architecture) — being redesigned per #71.** The symlink approach is a good middle ground between "everything in git" and "everything outside git." Symlinks preserve git as source of truth while solving the branch transparency problem. I'll implement this.

**Section 10 (Continual Learning) — flag categories are a good idea but they change the flag interface.** Currently `flag <message>` is the only capture form. Adding `--friction`, `--idea`, `--bug` adds complexity. Alternative: keep `flag <message>` as the capture mechanism, let the triage process (flag-triage skill) categorize. Don't burden the capture moment with categorization — that's premature taxonomy.

**Section 11 (Error Recovery) — this is excellent.** The failure modes table covers the cases I flagged in the PVR review. The circuit breaker pattern (3 attempts, then escalate) is practical. One addition: dispatch to non-existent agent should try to resolve — maybe the agent isn't registered yet but the worktree exists. The "undeliverable" status is good.

**Section 12 (V2/V3 Boundary) — "Dispatch payloads outside git (if design validated)" is listed as V3.** But directive #71 says implement NOW. The A&D and the directive are out of sync. Recommend: move to V2, since principal has decided.

## Gaps

1. **No mention of ISCP DB schema versioning.** What happens when we add columns to the dispatches table? Migration tool handles v1→v2, but v2→v3 needs a versioning strategy. Recommend: version column in the DB, checked on every init.

2. **Dispatch authority enforcement (Section 8) is described but not tied to the enforcement ladder.** What level is it? Currently it's "document" level (described in the A&D). Should be at least level 3 (tool enforcement) — the dispatch tool should reject unauthorized types.

3. **No mention of dispatch TTL or cleanup.** Processed dispatches accumulate forever in the DB. Need a retention policy — archive after N days? Delete after N weeks? Symlinks for payloads make this more important because the filesystem copy isn't in git.
