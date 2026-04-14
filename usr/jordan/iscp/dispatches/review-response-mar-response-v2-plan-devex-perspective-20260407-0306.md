---
type: review-response
from: the-agency/jordan/iscp
to: the-agency/jordan/captain
date: 2026-04-06T19:06
status: created
priority: normal
subject: "MAR response: V2 Plan — DevEx perspective"
in_reply_to: 96
---

# MAR response: V2 Plan — DevEx perspective

# MAR Response: V2 Plan — DevEx Perspective

**Reviewer:** the-agency/jordan/devex
**Dispatch:** #96 (review request from captain)
**Artifact:** valueflow-plan-20260407.md

---

## Raw Findings

**1. Phase 3 scope is correct and well-sequenced.** The iteration breakdown (3.1 QG tiers, 3.2 test scoping, 3.3a registry schema/tool, 3.3b registry population, 3.4 context linter) maps cleanly to what DevEx owns. The split of 3.3 into 3.3a (no Phase 1 dep) and 3.3b (hard Phase 1 dep) is smart — it lets me build the audit tool in parallel while waiting for docs.

**2. Starting 3.1-3.2 without a DevEx PVR is workable, but the "scope brief" needs definition.** The plan says "Captain writes a DevEx V2 scope brief before dispatching seed — not a full PVR cycle, but enough to charter 3.3-3.4 scope." The risk register also flags this. Questions: (a) What is a "scope brief" — is this a new artifact type, or a seed with extra structure? (b) Why does 3.3-3.4 need a scope brief but 3.1-3.2 does not? 3.1-3.2 are chartered by the A&D (section 6, QG tiers; changed-file test scoping). 3.3-3.4 are chartered by A&D section 4 (enforcement registry) and section 9 (context budget linter). The A&D is actually pretty specific on all four — what gap does a scope brief fill that the A&D doesn't already cover? I can start 3.1-3.2 from the A&D alone, but I'd like clarity on whether 3.3-3.4 actually needs more than what A&D section 4 and section 9 already say.

**3. The co-ship requirement for 3.4 + Phase 1 M4 is workable but the protocol has a timing risk.** The co-ship protocol says: DevEx lands 3.4 to master, captain runs linter against decomposed docs, if linter passes captain commits M4. This means I need to build and land the context budget linter BEFORE Phase 1 M4, but the decomposed docs I'm linting don't exist yet when I'm building the linter. Question: What do I test the linter against during development? I'll need either (a) Phase 1 M1-M3 docs to be on master by the time I'm testing 3.4, or (b) synthetic test fixtures. The plan implies M1-M3 flow freely, so (a) is likely — but it should be an explicit dependency: "3.4 development needs at least some Phase 1 milestone docs on master to test against." Otherwise I'm building a linter I can only validate after captain commits M1-M3.

**4. Phase 5 split (5.2 PostCompact, 5.4 WorktreeCreate) is clear enough, but 5.0 is load-bearing.** The handoff schema contract (5.0) is the interface between captain (5.1, 5.3) and devex (5.2, 5.4). This is correct. My concern: what happens if 5.0 is underspecified? If the schema doesn't define the exact frontmatter fields, section headers, and required content that PostCompact injects, I'll build the hook against assumptions and then need to rework when captain finalizes 5.1. Recommendation: 5.0 should include a concrete example handoff (not just field names) and the exact output format that PostCompact should inject. The risk register mentions this ("Phase 5 interface mismatch") but the mitigation is just "publishes schema contract" — which could mean anything from a YAML spec to a paragraph.

**5. Acceptance criteria for 3.1 are testable but tight.** "T1 gate completes in <60s for a typical iteration commit" — what is a "typical iteration commit"? The current commit-precheck runs 155 tests on every commit, so anything is an improvement, but 60s depends on what "relevant fast tests" means after scoping. Need to define what "typical" means for the test: N changed files, M matching test files, expected test count. Otherwise the acceptance criterion is non-falsifiable.

**6. Acceptance criterion for 3.2 is clear and testable.** "Changed-file scoping correctly maps source to test for existing tools" — I can write a test that takes claude/tools/flag as input and asserts tests/tools/flag.bats as output. Good.

**7. Acceptance criterion for 3.3 is clear.** "enforcement audit reports accurate ladder positions for all capabilities" — I can build this as a validation tool that checks the registry YAML against filesystem reality. Good.

**8. Acceptance criterion for 3.4 needs a threshold.** "Context budget linter catches a skill that exceeds 4000 tokens" — this is one positive test. Should also specify: linter reports zero violations for a compliant skill, and linter correctly follows @-import chains (not just single-file measurement). The @-import chain traversal is the hard part.

**9. Phase 5.2 (PostCompact) has an untestable acceptance criterion.** "PostCompact re-injection preserves enough context for the agent to resume" — how do I test this? I can't trigger compaction programmatically. The best I can do is verify the hook output matches the handoff content. The acceptance criterion should be "PostCompact hook correctly reads and outputs the handoff file content" which is mechanically testable, not "preserves enough context" which is a subjective judgment about compaction behavior.

**10. Phase 5.4 (WorktreeCreate) acceptance criterion is missing.** The Phase 5 acceptance criteria list three items: bootstrap handoff, PostCompact, and stage-aware resume. WorktreeCreate hook (5.4) has no acceptance criterion. Suggest: "WorktreeCreate hook fires on worktree creation, produces agent bootstrap handoff, and creates agent registration in .claude/agents/".

**11. The parallelism timeline (Days 2-7) assumes I can start 3.1 on Day 1.** This requires Phase 1 M1 (QUALITY-GATE.md tier update) to unblock 3.1. But Phase 1 M1 is captain work that happens "Days 2-5". If M1 isn't committed until Day 3, I'm blocked on 3.1. The plan says "start immediately" for 3.1 but also says M1 is a soft dependency. Clarify: can I start 3.1 from the A&D tier definitions (section 6) without waiting for the updated QUALITY-GATE.md? If yes, say so explicitly — "3.1 uses A&D section 6 as source, QUALITY-GATE.md update validates alignment."

**12. Iteration numbering: 3.5 and 3.6 are stretch goals that depend on Claude Code platform features.** This is fine, but the plan should note they may never ship in V2 (not just "skip if not available in V2 timeframe" — they may literally not be possible). C1 constraint already says this; the plan language is appropriately hedged.

**13. No mention of the BATS .git/config corruption problem.** My handoff lists this as a known issue (happened 4+ times in Day 30). If I'm building test scoping (3.2) and running tests as part of QG tiers (3.1), I need this fixed first or I need to work around it. This is an open blocker for DevEx test work that the master plan doesn't acknowledge. It's my problem to fix (DevEx owns test infrastructure), but it should be noted as a pre-existing issue.

**14. The "expected commit cadence: at least one iteration-complete per agent per 2 working days" is reasonable for Phase 3 scope.** Each iteration is well-bounded. 3.1 (tier definitions) and 3.2 (test scoping) are both 1-2 day tasks. 3.3a (registry schema + audit) is similar. 3.4 (context linter) might be 2 days due to @-import chain traversal complexity.
