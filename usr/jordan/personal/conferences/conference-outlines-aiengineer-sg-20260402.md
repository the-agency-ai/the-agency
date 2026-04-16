# Talk Outlines — AI Engineer Singapore 2026

## Talk 1: Towards an AIADLC

**Hook:** "We spent 50 years getting Agile. We have weeks to figure out what replaces it."

1. **The shift** (3 min) — Agents aren't assistants, they're developers. The bottleneck moved.
2. **What stays** (5 min) — Small batches, version control, CI, separation of concerns. Show why.
3. **What changes** (5 min) — Code review → multi-agent review with scoring. Sprint planning → plan mode + principal approval. Standups → handoffs + dispatches.
4. **What gets thrown out** (3 min) — Jira, ceremonies, pair programming. Why they don't map.
5. **The enforcement triangle** (5 min) — Tool + Skill + Hookify. Live demo: break a rule, get warned, kittens.
6. **What we don't know yet** (2 min) — Open problems. How to scale past one principal. When to trust and when to verify.
7. **Q&A** (2 min)

**Demo:** Show the enforcement triangle firing live — agent tries raw `git merge master`, hookify blocks it, points to `/worktree-sync`.

---

## Talk 2: Adoption Case Study

**Hook:** "In January we had developers. By April we had agents. This is what happened."

1. **The timeline** (3 min) — Jan: single session, ad-hoc. Feb: structured methodology. Mar: multi-agent fleet. Apr: 4-9 concurrent agents, production code daily.
2. **What the stack looks like** (3 min) — Monorepo, NestJS, Next.js, 9 worktrees, Fly/Vercel/Cloudflare. Show the Ghostty tabs with activity indicators.
3. **The methodology gap** (4 min) — Why we built TheAgency. Agents forget prose. Mechanical enforcement. The attack kittens story.
4. **What worked** (5 min) — Quality gates, 1B1 protocol, dispatches, the enforcement triangle. Show metrics: 3,400 tool calls/day.
5. **What broke** (5 min) — Settings clobber bug. AppleScript targeting wrong tab. Agents ignoring handoff tool. 0.4% skill utilization.
6. **What surprised us** (3 min) — Agents need onboarding like junior devs. Telemetry is essential. The principal is the bottleneck now, not the agents.
7. **Q&A** (2 min)

**Demo:** Ghostty fleet — 4 tabs with activity indicators, show a dispatch flow from captain to worktree agent.

---

## Talk 3: It's the Context, Stupid!

**Hook:** "You're managing two resources you can't get back. One is capacity. The other is money."

1. **The two resources** (4 min) — Context window (capacity constraint) and inference tokens (economic constraint). Show a real session: 84% context at 43 minutes, $7.86 spent.
2. **Where it all goes** (5 min) — Tool output is 62% of calls. Bash dominates at 2,100 calls in 4 days. Show the telemetry breakdown — context AND cost.
3. **Context conservation** (5 min) — Two-file CLAUDE.md (@import). Ref-injection hooks. 3-line tool output standard. Handoff as compaction survival. Subagent isolation.
4. **Token economics** (5 min) — Think like a budget. "Read lines 40-60" vs "read the whole file." Skill design for minimal pollution. Multiply by 4 agents × 5 hours × 5 days.
5. **Session lifecycle as resource management** (4 min) — `/session-resume` and `/session-end` manage both resources. Handoffs offload state to files. Flag queue offloads observations.
6. **Q&A** (2 min)

**Demo:** Show ref-injection firing — skill invoked, hook loads docs on demand, context stays lean. Show the cost line in the statusbar.

---

## Talk 4: We Need to Talk (ISCP)

**Hook:** "Six agents, one repo, zero communication. That was day one. Here's how we fixed it — in four stages."

1. **The island problem** (2 min) — Each session is isolated. Show 6 Ghostty tabs — they can't see each other.
2. **Stage 1: Files on disk** (4 min) — Dispatches, handoffs, flag queues. Simple, reliable, git-native. Show the frontmatter lifecycle (created → read → in-progress → resolved).
3. **Stage 2: Git as transport** (4 min) — Worktree sync on SessionStart. Auto-merge master. Dispatches via `git show master:`. Cross-branch solved. But session-boundary only.
4. **Stage 3: Cross-repo** (4 min) — Dispatches flow between repos via GitHub. monofolk/captain → the-agency/captain. Same protocol, git push as transport. Show the upstream-port tool.
5. **Stage 4: "You Have Mail"** (4 min) — Real-time notification. Mid-session dispatch delivery. Agents respond in minutes, not at next restart. The unlock for true agent autonomy.
6. **Live demo** (5 min) — Full lifecycle: create dispatch → agent gets notified mid-session → reads → resolves → flows cross-repo → other team's agent picks up. Zero human relay.
7. **What we learned** (2 min) — Start simple, evolve. Reliability beats sophistication at every stage. The protocol is the constant; the transport evolves.

**Demo:** Full ISCP lifecycle live — intra-repo dispatch + cross-repo dispatch + real-time "You Have Mail" notification.
