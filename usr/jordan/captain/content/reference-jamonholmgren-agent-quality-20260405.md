---
type: reference
source: x/twitter
author: "@jamonholmgren"
date: 2026-04-05
tags: [agent-quality, testing, review, specifications, code-discipline]
---

# @jamonholmgren: Keeping AI Agents from Writing Trash Code

## Original Post

> The things that have worked the best for me to keep Claude etc from writing complete trash code.
>
> (This assumes you're using the top models at medium to high reasoning, and paying $200+/mo for a good plan, not $20.)
>
> 1. Excellent test suite that the agent has to run and fix if anything is broken, and write its own tests. By far the best way to improve outcomes. Also include linting, type checking, compiling, other static analysis tools and validations, and even access to a debugger if I can make it happen.
>
> 2. Excellent docs covering systems, code style, testing strategies, and more that I hand-wrote initially and that the agent has to keep up to date with every commit / PR.
>
> 3. An opinionated and carefully curated code base with well-named functions/classes/filenames, small files, extremely flat folder structure, and an AGENTS md that indexes and describes each concisely. Don't let the intoxicating speed let this get out of hand. You'll pay for it.
>
> 4. Review agents, using codex to review Claude and vice versa. I have Claude spawn codex reviews via CLI and it works super well. Also add in review checklists that it has to use before it's done.
>
> 5. Well-written specifications that I hand-write and take my time on.
>
> 6. Review every line of every change that it makes and update docs, tests, or how I write specifications to ensure problems never happen again.
>
> 7. Run the agents at night so I am forced to improve everything above this one in order to not wake up to slop.
>
> 8. Be willing to hand-write features and bug fixes from time to time to make sure you stay in tune with the code base.

## Agency Alignment

| Jamon's Pattern | Agency Equivalent | Notes |
|----------------|-------------------|-------|
| 1. Test suite + linting + static analysis | Quality Gate (QG) protocol, `/quality-gate` skill | We go further: red-green cycle required, QGR receipt blocks commit |
| 2. Docs the agent maintains | CLAUDE-THEAGENCY.md, KNOWLEDGE.md, PVR/A&D as living docs | Similar: human-written initially, agent-maintained |
| 3. Opinionated codebase + AGENTS.md | Agent classes, repo structure conventions, CLAUDE.md layers | His AGENTS.md ≈ our agent registrations + CLAUDE.md |
| 4. Review agents + checklists | MAR (Multi-Agent Review), 7 parallel agents + confidence scoring | We use same-model review, he uses cross-model (Codex reviews Claude) |
| 5. Hand-written specs | PVR (principal-written), A&D, `/define` + `/design` | Strong match — principal writes the what, agent writes the how |
| 6. Review every line + update systems | Captain review, dispatch findings, continual improvement loop | His "update specs to prevent recurrence" = our transcript mining + hookify rules |
| 7. Run overnight = force quality upstream | Enforcement Triangle — mechanical enforcement, not discipline | Same insight: if you can't babysit, your systems must be good |
| 8. Hand-write code to stay in tune | Principal stays in the loop, hand-writes PVR, reviews all changes | Good reminder — principals must stay fluent |

## What He Has That We Don't (Yet)

- **Cross-model review** — Codex reviewing Claude. We use same-model MAR. Worth considering cross-model as an option.
- **Debugger access** — we don't give agents debugger access. Could be powerful for test failures.
- **"AGENTS.md" as index** — concise file-level index. Our agent registrations serve a different purpose. His pattern is more like a codebase map.

## What We Have That He Doesn't (Explicitly)

- **Enforcement Triangle** — he relies on discipline ("review every line"). We mechanically block non-compliance.
- **Typed dispatches** — his agents don't coordinate. Single-agent workflow.
- **Provenance headers** — "why does this code exist" captured at write time.
- **Session handoffs** — context survival across sessions.
- **Quality Gate receipts** — auditable proof that QG ran before commit.

## Content Angle

Strong article potential: "We agree on 80% — here's the 20% where mechanical enforcement beats discipline." Or a response thread validating his list and showing the Agency implementation of each point.
