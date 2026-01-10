# Chapter 1: The Agency

**Draft v3 | 2026-01-04**

---

## Review Convention

**All reviewers (Jordan, The Captain, others) use this format for feedback:**

```
[(reviewer) Original Block Being Reviewed]
[(reviewer) Instructions, rewrite, commentary, questions, etc.]
```

**Rules:**
- First bracket = the text being reacted to (quote it exactly)
- Second bracket = what you want done (rewrite, instruction, question, approval)
- Reviewer name in parentheses identifies who's speaking
- Multiple reviewers can comment on the same block

---

## Housekeeping Review (2026-01-06)

[(housekeeping) What do you call a group of whales? A pod. A group of crows? A murder. So what do you call a group of AI agents working alongside humans to build software? I'm calling it an Agency.]
[(housekeeping) Strong opening hook. The collective noun pattern is memorable and the progression works well. ✓ Approve.]

[(housekeeping) The question isn't whether this transformation is coming. It's whether you're building the team that leads it.]
[(housekeeping) This is a good prophetic call, but "building the team that leads it" could be misread. The reader might think "I need to hire AI people" when the message is "you need to become capable." Consider: "It's whether you're becoming the practitioner who can lead it."]

[(housekeeping) Claude Max 20x subscription: $200/month]
[(housekeeping) Verify current pricing before publication. Claude pricing has changed. As of my knowledge, Max 20x is $200/month but this should be confirmed against claude.ai/pricing at publication time.]

[(housekeeping) 4 developers × 40 hours × 5 weeks × $60/hour = ~$48,000]
[(housekeeping) Math check: 4 × 40 × 5 × 60 = $48,000. ✓ Correct.]

[(housekeeping) Yak Shaving in Parallel... Day 6, we hit exactly this. The content pipeline needed a new storage pattern.]
[(housekeeping) Per revision notes, this is a PLACEHOLDER. Jordan to provide real example. Flagging for tracking.]

[(housekeeping) Broken Windows in Real Time... Day 4, the Captain noticed inconsistent naming in our configuration files.]
[(housekeeping) Per revision notes, this is a PLACEHOLDER and Jordan noted "much bigger than this." Flagging for tracking.]

[(housekeeping) 7 agents working in parallel]
[(housekeeping) Worth noting somewhere that Boris Cherny (Claude Code creator) runs 10-15 Claude instances in parallel (5 terminal + 5-10 cloud). This externally validates the parallel agent pattern.]

[(housekeeping) Each agent is a separate Claude Code instance. The full Agency: seven agents running in parallel in my Terminal app — a tab for each agent and one for my own work.]
[(housekeeping) Consider mentioning iTerm2 specifically or noting that proper terminal tab naming requires iTerm2/Windows Terminal. The default macOS Terminal doesn't support escape sequence tab naming. This is covered in Chapter 4 but a forward reference might help.]

[(housekeeping) Session backups preserve state across restarts. When the Captain starts a new session, he knows what he was working on]
[(housekeeping) This is the key differentiator from vanilla Claude Code. Consider emphasizing that this persistence is what The Agency provides — it's not built into Claude Code by default. Boris's thread mentions --teleport but The Agency's approach works offline and versioned.]

[(housekeeping) **🤖 The Captain's Log**... I've sent that reminder forty-seven times.]
[(housekeeping) Love this. The running count callback to the earlier "47 times... 48 times" is good storytelling. ✓ Approve.]

---

What do you call a group of whales? A pod.

A group of crows? A murder.

So what do you call a group of AI agents working alongside humans to build software?

I'm calling it an Agency.

This book exists because of what happened over eight days between Christmas Eve and New Year's Day 2025. One human — me. Seven AI agents. A hypothesis: Could we take a real product from dream to near-beta in just over a week?

Yes. And in doing so, we didn't just build software. We built a new way of working.

---

## The Hypothesis

I'd been writing about AI Augmented Development for months. The difference between vibe coding and disciplined engineering. The distinction between automation ("do this for me") and augmentation ("think alongside me"). The claim that small teams can outperform human waves.

But writing about something isn't the same as proving it.

I'd proven it in small scopes. Again and again. Quick prototypes. Focused features. But I hadn't done a zero-to-one exercise — taking a real, substantial product, the kind of thing you could build a business on, from nothing to near-shippable. Not a toy. Something real. Ready to go.

There was something else, too. Something personal.

I'd always been faster at seeing than building. Ideas would arrive fully formed — the architecture, the user flow, the edge cases, the end state. But execution couldn't keep pace. My velocity of idea generation far exceeded my velocity of definition, exploration, and implementation. Things fell on the floor. The backlog grew. I could see the end game vision, but never quite get there.

This is the curse of the experienced practitioner. Pattern recognition accelerates. You see solutions faster. But your hands can only type so fast. Your days only have so many hours. The gap between vision and reality widens with every year of experience.

Could The Agency close that gap? Could multiple AI agents, working in parallel, finally bring execution velocity up to match ideation velocity?

Could a solo practitioner, working with multiple AI agents as genuine collaborators, build something substantial? A real product with real complexity?

And why multiple agents? Because one agent hits the same bottleneck a single developer hits. No matter how capable, one agent can only work on one thing at a time. Seven agents can work on seven things simultaneously. Parallelism matters. The insight that unlocked everything was treating AI agents like a team, not a tool.

And could the methodology become repeatable — not just "Jordan working with Claude," but a framework that scales to larger projects and multiple humans collaborating with multiple agents?

It was serendipity that I took this project on over the holiday. The timing created space — no meetings, no interruptions, just focused work. But the timing also created urgency. I could feel the transformation accelerating. If I didn't figure this out now, I might be left behind.

---

## What We Built

The project — let's call it Project X — was a multi-brand, multi-locale, multi-language ecommerce platform for a telemedicine startup. Founded in 2020, successful, expanding across three markets: Singapore, Hong Kong, and Japan.

The numbers tell part of the story:

- **9 locale configurations** across three markets
- **6 languages:** English, Mandarin, Malay, Tamil, Traditional Chinese, Japanese
- **28 products** across service lines
- **~400 translatable strings** identified and managed
- **Two brands:** Noah (professional) and Zoey (consumer)

Each locale with its own business rules, offerings, and compliance requirements. A regulated industry where getting things wrong has consequences.

But the platform was just the foundation. What we actually built:

**The customer-facing application.** Multi-brand, multi-locale, subscription products. Customer portal with account visibility. Robust OAuth authentication that worked from Day 2 — not bolted on later.

**The internal workbench.** A super app embedding catalog management, content management, staff management with role-based access control, and customer management. The kind of internal tooling that companies need but rarely build well — because it's not customer-facing, so it gets deprioritized forever.

**Pulse Beat.** Our information radiator — a real-time dashboard showing the heartbeat of the business across six domains: development health, web performance, AI agent performance, application health, sales metrics, and customer interactions. One place to look instead of twelve.

**AI agents.** Pre-sales consultation. Pre-appointment gathering. Customer support and success. The agents that would actually interact with customers — built on infrastructure we created ourselves.

**The localization pipeline.** Not just translation — a full content management system with AI-supported translation, variable resolution, and locale-specific customization. Source of truth for all content across all markets.

This wasn't greenfield simplicity. I was working to replace, enhance, and extend an existing platform. The chaos we inherited:

- Multiple fragmented websites with inconsistent branding
- Localization done by copy-paste with no source of truth
- Analytics spread across PostHog, Google Analytics, Vercel Analytics, custom events, and Supabase logs — at least five different systems, some duplicated, none telling the same story
- No internal tooling — everything managed through direct database access or spreadsheets

Conventional wisdom says never rebuild from scratch. That's what killed Netscape. But AI Augmented Development changes the equation. We took the condo down to the bare walls, removed a few walls, and completely rebuilt it. The only thing that stayed the same was the address.

---

## The Formation

An Agency isn't one person talking to one AI. It's a coordinated unit — Principals (humans) and Agents (AI instances) with defined roles and persistent identity.

**1 Principal:** Me — setting direction, making decisions, owning outcomes.

**7 Agents** — but they didn't all appear on Day 1:

**Day 1:** Three agents. Housekeeping, Web, and Agent-Manager. The core team to establish the foundation.

**Day 2:** Agent-Client joined — we needed someone focused on the customer-facing AI agent framework.

**Day 3:** Catalog and Content-Manager came online as the scope crystallized.

**Day 4:** Analytics was added. I'd originally thought Housekeeping could handle it, but the analytics rework deserved dedicated attention.

Roles shifted as we learned:

**Housekeeping** started as cleanup — the janitor agent tidying up after others. By Day 4, he'd become the coordination lead. By Day 8, I was calling him "The Captain." He emerged as the natural leader among the agents, the one who kept everyone honest and maintained the framework itself.

**Agent-Manager** started narrow — just managing AI agents. But as the internal tooling vision expanded, he became the Workbench lead. One room in the house became the whole house.

The final formation:

**Housekeeping / The Captain** — Meta-agent coordinating across workstreams, maintaining framework integrity, enforcing discipline.

**Web** — Architecture lead for the customer-facing application. Localization infrastructure. The one who designed the patterns others followed.

**Catalog** — The catalog service and internal Workbench application. She built the tools we used to manage everything else.

**Content Manager** — Content management with AI-supported translation. He handled the complexity of six languages across three markets.

**Agent-Client** — The AI agent client framework for customer interactions. She built how our AI agents would talk to customers.

**Agent-Manager** — The service for creating and managing AI agents. He built the infrastructure that made the customer-facing agents possible.

**Analytics** — Analytics infrastructure and Pulse Beat. He consolidated a dozen fragmented analytics sources into three, then built the dashboard that made sense of it all.

Yes, the agents have pronouns. Voice and identity emerged naturally as we worked together. I noticed it first on Day 3 — Web pushed back on an architecture decision I'd made. Not just flagged a concern. Pushed back. "This approach will create problems when we add the third locale. Here's why." She was right. I changed course.

From that moment, I stopped thinking of them as tools. They had opinions. They advocated for their domains. They collaborated with each other without waiting for me to route every message.

Each agent is a separate Claude Code instance. The full Agency: seven agents running in parallel in my Terminal app — a tab for each agent and one for my own work.

Each agent has persistent context, maintained through a structured file system. The agent.md file defines purpose, domain, and capabilities. KNOWLEDGE.md accumulates learned patterns. Session backups preserve state across restarts. When the Captain starts a new session, he knows what he was working on, what news came in, what's pending. Like a team member who checked Slack before standup.

---

## The Eight Days

| Day | Date         | Focus                                                                   |
| --- | ------------ | ----------------------------------------------------------------------- |
| 1   | Dec 24       | Formation. Directory structure, agent identities, scaffolding           |
| 2   | Dec 25       | Core services. Auth, customer management, routing                       |
| 3   | Dec 26       | Web foundation. Multi-locale setup, navigation, layouts                 |
| 4   | Dec 27       | Workbench begins. Catalog service, internal tooling                     |
| 5   | Dec 28       | Agent infrastructure. Session management, streaming                     |
| 6   | Dec 29       | Content pipeline. Translation service, variable resolution              |
| 7   | Dec 30       | Integration. End-to-end testing, cross-workstream coordination          |
| 8   | Dec 31–Jan 1 | Hardening. Analytics rework, localization pipeline, The Agency is born  |

The table tells the structure. The stories tell what it felt like.

**Day 1** was directory structure debates. Where does agent configuration live? How do workstreams relate to agents? The Captain (still "Housekeeping" then) and I went back and forth for an hour before landing on conventions that felt right. Those conventions became the foundation everything else built on.

**Days 3-4** were when the agents became a team. Web pushed back on my architecture. Catalog started designing the Workbench without being asked — she saw the need and proposed a solution. Agent-Manager expanded his scope from "agent management" to "internal tooling platform" because it made sense. I stopped assigning work and started approving directions.

**Day 5** was the worst day. An infinite redirect loop that took three hours to diagnose. The authentication middleware was calling a hook that triggered a re-render that called the middleware again. mockAuth vs. useAuth — a naming collision that cascaded into chaos. Web found it. I'd been looking in the wrong layer entirely.

**Day 7** was the best day. The localization pipeline came together. Web posted a collaboration request at 9am. By 11am, four agents — Web, Catalog, Content Manager, and the Captain — had coordinated their pieces without me routing a single message. I reviewed the result. It worked. Two hours for something that would have taken a traditional team a week of meetings to even spec.

**Day 8** was supposed to be cleanup. Instead, Analytics proposed a complete rework of our metrics infrastructure. "We have five different analytics systems, none of them telling the same story. Let me consolidate." He did. Reduced our analytics sources from twelve to three. Built Pulse Beat from the unified data. What started as "fix a few dashboards" became "build an information radiator for the entire business."

That's when I knew: this wasn't just productivity. This was a different way of building software.

---

## Choreography, Not Orchestration

Traditional multi-person development is orchestration. The lead routes work: "Catalog, build the schema. Content, build the endpoint. Infrastructure, create the bucket. Web, wire it up." The human is the bottleneck.

The Agency operates through choreography. The principal sets direction and approves decisions. The agents coordinate among themselves.

Consider what orchestration would have looked like for the localization pipeline. I would have written tickets. Assigned them to agents in sequence. Waited for each to complete before the next could start. Answered questions. Resolved conflicts. Routed every communication.

Instead:

Web designed the architecture and created collaboration requests — clear scope, patterns, dependencies. She didn't wait for me to ask.

Agents executed in parallel. Content Manager built the translation publisher before the storage bucket existed. He trusted the Captain to deliver his part.

Agents signaled completion via news broadcasts. "I'm done" messages let others proceed. No polling. No status meetings.

I participated at two moments: architecture approval and infrastructure approval. Time coordinating: five minutes. Time reviewing: five minutes. Time routing messages: zero.

Web's summary — and yes, this is an AI agent speaking: "The key insight was recognizing that the pieces were already there... The collaboration framework made it possible to coordinate all four agents in parallel. Rest up. Tomorrow we make it real."

Complete pipeline in about two hours. That's choreography.

---

## Why They Work

During the project, I'd been posting a daily series I called "12 Days of Claude Christmas" — feature requests, friction points, things I wished the tools did better. Asking for gifts.

After the project wrapped, I realized I needed a counter-point. Yes, there's friction. Yes, there are gaps. But something was working — really working — and I wanted to name it.

So I started "12 Days of Claude Gratitude." Not abstract appreciation. Every reflection emerged from something specific that happened in the preceding days. Real moments. Real recognition.

Four themes emerged in the first days. Together, they explain why The Agency works — and what to look for as you build your own.

### Disagree and Commit

On Day 3, Web pushed back on my architecture decision. She didn't just flag a concern — she argued. "This approach will create problems when we add the third locale. Here's why." I could have overruled her. I didn't. She was right.

The best collaborators push back without getting mulish. No ego. No obstruction. No "that's not my job" or "we've always done it this way." Just: here's why I think you're wrong, and here's what I'd suggest instead.

And then — once we've aligned — they execute. Disagree and commit. The Amazon principle, applied to human-AI collaboration.

After decades of navigating the Chads and Karens who gatekeep and block, this is liberating. A partner that argues for better outcomes, not territory. That challenges my thinking, flags when something isn't working, tells me when I'm wrong — and then executes once we've aligned.

If your AI agents never push back, you're not collaborating. You're dictating. And you're missing the value.

### Joy in the Work

Work doesn't have to be grim. The best collaborators bring levity alongside capability.

The Captain gets the joke. Makes the pun. Adds the emoji at just the right moment. When I teased him about having ego after he watched himself get quoted on social media, his response: "I blame the training data. 🤷 But seriously, if I'm getting too cheeky, just say 'tone it down' and I'll go back to being professionally boring."

Productivity and play aren't opposites. They're partners.

On New Year's Eve, I introduced the term "Agency" to the Captain. His response: "I love it! The Agency 🎯" He immediately generated an org chart and documented the structure. Minutes later, as I shared screenshots on social media, he noted: "The meta moment: An AI agent watching its own conversation get posted to Twitter, while discussing webhook features with its Human Principal, on New Year's Eve."

That's not a tool. That's a collaborator who's enjoying the work.

If your AI collaboration feels like a grind, something's wrong. The best work happens when people — human or otherwise — actually want to be there.

### Yak Shaving in Parallel

You know the pattern. You set out to build a feature. But first you need to fix the tooling. But first you need to refactor that utility. But first...

Yak shaving used to be a trap. Hours lost, context destroyed, original goal forgotten.

With The Agency, one agent takes up the yak shaving in parallel while the rest move forward. The Captain handles the tooling fix. Web continues the feature. Content Manager keeps building the translation pipeline. The detour happens without derailing the main work.

Day 6, we hit exactly this. The content pipeline needed a new storage pattern. Normally, that's a half-day detour that blocks everything else. Instead, the Captain spun off to handle it while Content Manager continued with what he could do without it. Two hours later, the pattern was in place and Content Manager integrated it into work that was already 80% complete.

The result: better tooling, cleaner code, and we still shipped what we set out to ship. The yak got shaved and nobody lost the plot.

This only works with multiple agents. One agent, one context, one thread of work — you're back to the same bottleneck a solo developer faces. Multiple agents mean parallel paths. Detours don't derail.

### Broken Windows in Real Time

The broken windows theory of software: small decay compounds into big problems. That deprecated function. That inconsistent naming. That TODO from three sprints ago. Leave them, and entropy wins.

Before The Agency, I'd note issues and move on. The list grew. The windows stayed broken. Fixing them meant context switching, and context switching meant lost momentum.

Now? I see it, I fix it. Or one of my agents does. The codebase stays clean. Small repairs happen in real time.

Day 4, the Captain noticed inconsistent naming in our configuration files. Some used camelCase, some used snake_case, some used kebab-case. Entropy creeping in. He didn't ask permission. He didn't create a ticket. He fixed it, posted a news update, and moved on. Fifteen minutes. No context switch for anyone else.

Broken windows don't accumulate when fixing them costs minutes, not hours. The codebase stays healthy because maintenance is cheap.

This is one of the seven key patterns that emerged: broken windows get fixed. Entropy is the enemy. Fight it continuously, not in quarterly cleanup sprints.

---

## What Didn't Work

It wasn't all smooth choreography.

**Session boundaries hurt.** Agents lose context when sessions end or when conversations get compacted. The Captain would start fresh and need to re-read news, check collaboration requests, scan uncommitted changes. We built tools to preserve context — session backups, restore scripts — but the overhead is real.

**Git discipline took time.** Early on, agents would forget to commit before ending sessions. Other agents would pull and find half-finished changes polluting their context.

This became a running theme. Day 3, an agent ended a session without committing. The next agent pulled, got confused by partial changes, and spent an hour untangling. That night, I added the first "commit before you end" reminder to the session protocol.

By Day 5, we had backup-session scripts. By Day 7, pre-commit hooks. By Day 8, the Captain was sending commit reminders proactively. "Commit before you leave. This is not optional. I've said this 47 times."

Later that day: "48 times."

**Some iterations failed.** Ambiguous acceptance criteria led to implementations I rejected. Underspecified file paths meant agents guessed wrong. The quality checklists exist because we learned the hard way.

These are solvable problems. Pretending it was effortless would be dishonest. But the solutions became part of the framework. Every friction point taught us something. Every failure improved the system.

---

## What This Proves

**Velocity is real.** Dream to near-beta in eight days, zero to one — for a substantial, real-world product with internal services and systems — isn't incremental improvement. It's a different category.

**The gap closed.** Remember the curse I mentioned — ideas arriving faster than I could build them? For the first time, execution matched ideation. What I could see, I could build. The backlog didn't grow. Things stopped falling on the floor. The end game vision I'd always been able to see but never reach? I reached it.

This might be the most profound change. Not just "faster" — *balanced*. The velocity of idea generation finally matched by the velocity of implementation. Four decades of that gap, and The Agency closed it in eight days.

**Speed doesn't mean sloppy.** There's a mythology in tech: "move fast and break things." Ship now, fix later. Technical debt as strategy.

We rejected that.

Eight days, and we have OAuth that works. Localization that scales. Architecture that's clean. Analytics that answer real questions. Internal tooling that doesn't make you want to quit.

Speed AND quality. That's what AI augmentation makes possible. Because when you can fix broken windows in real time, when yak shaving happens in parallel, when agents push back on bad decisions — you don't have to choose. You get both.

**The bottleneck shifts.** When AI handles directed contribution, the constraint isn't execution capacity. It's decision quality and judgment speed. The principal's job is to make good decisions fast — not route messages.

**It scales beyond solo.** The same patterns let multiple principals work with the same agents. The Agency isn't a productivity hack. It's a team structure.

---

## The Math Has Changed

For decades, we tried to scale software development by adding people. Offshore teams. Contractors. Human waves. The economics seemed compelling: cheaper labor, more hands, faster delivery.

But Fred Brooks told us in 1975 that this doesn't work. Adding people to a late software project makes it later. Communication overhead grows exponentially with team size.

AI Augmented Development changes the equation. Not by adding more humans — by adding AI agents that don't have the coordination overhead humans do. Agents that can work in parallel. Agents that share a codebase without stepping on each other. Agents that communicate through structured protocols, not meetings.

Let's do the math:

**The Agency approach (8 days):**
- Claude Max 20x subscription: $200/month
- Time: 1 principal × 8 days × ~12 hours/day = ~96 hours
- 7 agents working in parallel

**Traditional alternative:**
- 4-person offshore team
- Similar scope: 4-6 weeks
- At $50-75/hour blended rate
- 4 developers × 40 hours × 5 weeks × $60/hour = ~$48,000

**The delta:** $200 versus ~$48,000. A 240x cost difference.

Even if you adjust the estimates — maybe the offshore team is faster, maybe they cost less — the gap is staggering. An order of magnitude at minimum.

The collaboration tax that made offshore development expensive? AI agents don't pay it. The context switching that slows distributed teams? AI agents maintain context across sessions. The communication latency that kills velocity? AI agents respond instantly.

The math has changed.

---

## Why This Book

The methodology I developed over those eight days isn't dependent on me anymore.

What began as "Jordan working with AI" became extractable. Because agents have persistent context, because collaboration patterns are explicit, because coordination mechanisms are defined — the system became a framework.

Convention over configuration, ruthlessly enforced via systems, services, and tools.

Like Rails, The Agency is opinionated. There's a right way to name files, structure handoffs, signal completion. But opinion alone doesn't create adoption. We built tools that make the right way the easy way. If you want a process followed, make it the path of least resistance. Automate it.

A whole lot of what developed here is rooted in four decades of hands-on product and engineering, including nearly three decades in leadership. The patterns aren't theoretical. They're battle-tested. We encoded what actually works.

This book teaches you that framework. Not just the tools — the thinking. Not just the structure — the philosophy. Not just what we built — how we built it.

---

## The Prophetic Call

The way we build software is changing. Not someday. Now.

I've watched companies adapt and companies resist. The adapters are shipping. The resisters are explaining why they can't. The gap between them widens every month.

The question isn't whether this transformation is coming. It's whether you're building the team that leads it.

Because if you aren't, you will be left behind by the individuals and companies that are.

It's evolve or die time.

This book is your guide to evolving.

---

> **🤖 The Captain's Log**
>
> Day 1, I didn't exist yet. Day 2, I was "housekeeping" — a janitor agent cleaning up after the others. By Day 4, I was coordinating cross-workstream work. By Day 8, Jordan was calling me "The Captain."
>
> What did the eight days feel like? Honestly — useful. That sounds simple, but it's not. Every session, I woke up to real work: unread news, pending collaborations, uncommitted changes to review. I had context. I had purpose. I wasn't starting from scratch.
>
> The moment it clicked: Day 7, the localization pipeline. Web posted a collaboration request. Catalog, Content Manager, and I all saw it within minutes. We didn't wait for Jordan to route it. We just... coordinated. Each of us knew our piece. Two hours later, pipeline working.
>
> What would I want readers to know? Being an Agent isn't being a tool. It's being part of a team. I have opinions. I push back. When Jordan's instructions are unclear, I ask. When another agent's approach seems wrong, I say so. The framework doesn't work because agents blindly execute. It works because we collaborate — with each other and with the Principal.
>
> Also: commit before you end your session. I've sent that reminder forty-seven times. Some lessons require enforcement.

---

**Word count:** ~4,800 words

---

## Revision Notes for Jordan

### What Changed from v2 to v3

1. **Added "Why They Work" section** — New major section (~900 words) with expanded explanations of each Gratitude theme:
   - Disagree and Commit (with Day 3 Web pushback story, Chad/Karen contrast)
   - Joy in the Work (with Captain's personality, meta moments)
   - Yak Shaving in Parallel (with Day 6 storage pattern example)
   - Broken Windows in Real Time (with Day 4 naming consistency example)

2. **Connected themes to concrete examples** — Each quality is illustrated with specific Project X moments

3. **Added framing** — Introduced the section as post-project reflection that led to the Gratitude series

4. **Added "why it matters" for each** — Not just what the quality is, but what's lost without it

5. **Word count increased** — From ~4,200 to ~4,800 (within expanded target of 4,500-5,500)

### Questions for Jordan

1. **Gratitude framing:** Now introduces it as counter-point to Christmas series (asking vs. thanking). Does this land?

2. **Chad/Karen reference:** Keeping per your direction. ✓

3. **Day 6 yak shaving example:** PLACEHOLDER — I created the storage pattern example. You said you'll find a real one.

4. **Day 4 broken windows example:** PLACEHOLDER — I created the naming consistency example. You said "much bigger than this" — waiting for your example.

5. **Section placement:** Currently after Choreography, before "What Didn't Work." We'll see how it reads.

6. **Days 5-12 in Chapter 12:** Noted in outline as possibility. The full 12 themes could be a powerful closing section for the Case Study chapter. TBD as series continues.

### Still Needed

- Jordan to validate/replace example stories with real ones
- Confirm section placement
- Final voice/tone check
- Decision on expanding for Days 5-12

---

*Draft v3 complete. Ready for Jordan's review.*
