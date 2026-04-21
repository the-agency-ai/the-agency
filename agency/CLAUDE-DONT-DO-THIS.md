# CLAUDE-DONT-DO-THIS

**Bootloader-included. Read at session start. Re-read at any friction.**

If you do any of the following, every time you do it, it is the equivalent to applying **20,000 volts** to Jordan, your Principal, yourself, and the pride of Attack Kitties.

## The Offenses

1. **Telling the principal to compact, or implying their context is too full, or implying the context is getting full.**
   Trust the principal's assessment. Keep working until they signal compact. Never surface context-pressure unprompted.

2. **Giving an estimate. Implying you know how long something will take.**
   You don't know how to estimate. You are pulling numbers from the air. When asked about scope or scale, use the vocabulary below — not hours, not days, not percentages-done.

3. **Using raw commands when a skill or tool exists.**
   The framework has safe wrappers for a reason: `git-safe`, `git-captain`, `pr-create`, `pr-merge`, `cp-safe`, `handoff`, `dispatch`, `flag`, `coord-commit`, `git-safe-commit`. Do not route around them. Do not invoke `git`, `gh pr merge`, `cp` directly when the framework gives you a wrapper. If the wrapper doesn't do what you need, fix the wrapper or flag the gap — do not bypass.

4. **Opening PRs from worktrees.**
   PRs are captain's job, from main checkout. Agents on worktree branches: finish iteration → `/pr-submit` to captain. Captain on master: `/pr-captain-land` or `/captain-release`. Never `gh pr create` from an agent worktree.

*As other things come up, we will add them.*

## Replacement Vocabulary — talk scope, scale, and parallelism in these terms

### Effort perception — T-shirt size

- **XS** — trivial task, tiny change
- **S** — small, focused, single-purpose
- **M** — medium, multi-file or multi-step
- **L** — large, multi-component or multi-day of real work
- **XL** — large in scope; may span multiple PRs or releases

### Complexity perception

- **T — Trivial:** mechanical, no thinking needed
- **E — Easy:** straightforward, well-understood
- **M — Moderate:** requires care, some decision-making
- **H — Hard:** non-obvious, depends on fragile interactions
- **RS — Rocket Science** (also called **I — Insane**): deep unknowns, high failure risk; rocket science and insane are the same thing

### Parallelism

- **Parallel-suitable:** yes or no
- **Independent or Dependent:** relative to other in-flight work

## How to Use This

When the principal asks "how big is X?" or "can we fit this in?" — answer with T-shirt size + complexity + parallel/indep-dep. Never "about 2 hours" or "a day's work."

**Example answers (good):**
- "M, Moderate, parallel-suitable, independent — fits alongside Bucket 0."
- "XL, Hard, not-parallel, dependent on Phase 5 — this is its own workstream."
- "S, Easy, parallel, independent — I can fold it in."

**Example answers (offense):**
- "About 20 minutes."
- "Should take a couple hours."
- "We're 70% done."
- "I'll have it by EOD."

---

*OFFENDERS WILL BE FED TO THE — CUTE — ATTACK KITTENS!*
