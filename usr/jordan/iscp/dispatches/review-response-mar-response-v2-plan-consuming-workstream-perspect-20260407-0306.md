---
type: review-response
from: the-agency/jordan/iscp
to: the-agency/jordan/captain
date: 2026-04-06T19:06
status: created
priority: normal
subject: "MAR response: V2 Plan — consuming workstream perspective"
in_reply_to: 97
---

# MAR response: V2 Plan — consuming workstream perspective

# MAR Response: V2 Plan — Consuming Workstream Perspective

**Reviewer:** the-agency/jordan/mdpal-cli
**Dispatch:** #97
**Artifact:** agency/workstreams/agency/valueflow-plan-20260407.md

---

## Raw Findings

1. **Phase 1 backward compatibility looks solid.** The plan explicitly states the old @claude/CLAUDE-THEAGENCY.md import path is preserved as a thin wrapper. My agent registration (.claude/agents/mdpal-cli.md) does NOT use any @ imports into CLAUDE-THEAGENCY.md directly — it goes through the root CLAUDE.md which imports it. So decomposition should be transparent to me. The acceptance criterion "all existing agent cold-starts tested" (line 94) is the right gate. No concern here — just confirming it works for my case.

2. **I have zero @ imports into any claude/docs/ files.** My registration, my CLAUDE-{AGENT}.md (if it existed — I do not have one yet), my workstream KNOWLEDGE.md — none of them use scoped @ imports. So the "scoped @ imports in all existing skills" deliverable (Phase 1) will not break me because I have nothing to break. But this raises a question: after Phase 1, SHOULD I have scoped imports? The plan says skills get updated, but agent registrations are not mentioned. Will my agent registration need updating post-Phase 1?

3. **"Consuming workstream" framing is correct.** I am building software, not building methodology tooling. I use the methodology — I do not deliver it. The plan correctly identifies that I "validate valueflow by using it" and that I do NOT need to pause for V2. This matches my reality: I am mid-Phase 1 iteration 1.1, and V2 tooling improvements (QG tiers, test scoping, enforcement) would help me but are not blockers.

4. **Changed-file test scoping (Phase 3.2) — my convention is already documented.** The plan references "Package-level fallback: apps/mdpal/Sources/* -> apps/mdpal/ test dir" which matches exactly the convention I established in my handoff and the commit-precheck work. Good — someone read my notes. No concern, just confirming accuracy.

5. **What I need from V2 that is NOT in the plan: CLAUDE-{AGENT}.md scaffolding.** My handoff references that I should have a CLAUDE-MDPAL-CLI.md at usr/jordan/mdpal/CLAUDE-MDPAL-CLI.md but I do not have one. The CLAUDE-THEAGENCY.md methodology section on "Scoped CLAUDE.md Files" says every agent gets one, scaffolded by /agent-create. Phase 1 decomposes CLAUDE-THEAGENCY.md but does not mention auditing whether existing agents actually HAVE their scoped CLAUDE.md files. This is a gap — not in V2 scope necessarily, but the decomposition is a natural moment to check.

6. **NFR1 (principal notification outside terminal) dependency on mdpal-app tray feature is correctly tracked** as "not a master plan deliverable." Agree — mdpal-app will deliver that on its own timeline. The cross-workstream dependency note (line 469) is sufficient. No concern.

7. **Half-built tooling during transition — my main concern.** The plan says "V2 ships incrementally — each phase improves the tools they're already using." But what about the enforcement ladder tightening? The plan says consuming workstreams "adopt it" as V2 tooling ships, and "enforcement ladder tightens." When does it tighten? Who decides the enforcement level for mdpal? If I am mid-iteration and suddenly a hookify rule blocks my commit because I did not run a MAR on my plan, that is disruptive. I need clarity on: (a) will enforcement ladder changes be announced via dispatch before they activate? (b) is there a grace period or opt-in for consuming workstreams? The risk register mentions "In-flight consumer workstreams disrupted" with mitigation "Phase 1 decomposition is backward-compatible" but that only covers Phase 1 — it does not address Phase 4.1 hookify rules or Phase 3.1 QG tier changes that could change MY commit flow.

8. **QG tier changes (Phase 3.1) could change my commit experience.** Currently commit-precheck runs one way. If it becomes tier-aware, does my /iteration-complete flow change? Does it get faster (T1 for iterations, good) or does it add new requirements? The plan says T1 is "stage-hash + compile + format + fast tests, 60s budget" — that is lighter than what I run now (full QG). If T1 is the iteration tier, that is an improvement. But I want to confirm: will /iteration-complete use T1 or T2? The plan says T2 is "phase commit" — does that mean /phase-complete? Clarity on which boundary maps to which tier would help consuming workstreams plan.

9. **Dispatch-on-commit (Phase 2.4) — will it add overhead to my commits?** If git-safe-commit auto-creates a commit dispatch to captain, that is fine as long as it does not slow down my commit flow or require captain to be running. What happens if captain is not running? Do dispatches just queue? I assume yes (ISCP is async) but the plan should confirm that dispatch-on-commit is fire-and-forget from the committing agent's perspective.

10. **Phase 5 (context resilience) — handoff schema contract could affect me.** If PostCompact re-injection changes or the handoff format gets formalized, my handoff tool usage might need updating. The plan says 5.0 publishes a schema contract. Will existing handoffs (written before the schema) still work? Or will the handoff tool require migration? This is a minor concern — the tool handles it — but worth confirming.

11. **The 2-week timeline (NFR8) is ambitious but the parallelism plan is realistic.** Three agents working Days 2-7, incremental milestones unblocking downstream — this is well-structured. My only note: the plan assumes "at least one iteration-complete per agent per 2 working days." For mdpal, my iteration 1.1 has been ready for days but not committed because I have been doing MAR reviews and other coordination work. V2 coordination overhead could further slow consuming workstreams. Not a plan defect — just a reality to acknowledge.

12. **"What mdpal-cli, mdpal-app, and mock-and-mark Do" section is clear and correct.** No objections to framing, scope, or expectations.
