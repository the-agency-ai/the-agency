# Transcript: agency-init Design Review

**Date:** 2026-03-31
**Participants:** jordan (principal), captain (agent)
**Context:** Review/revise/finalize cycle on `agency-init-design-20260331.md`
**Trigger:** Multi-agent review (design, code, security) produced findings; resolving items needing principal input

---

## Multi-Agent Review Summary

Three parallel reviewers (design, code, security) reviewed the design document. Consolidated findings:

- **3 CRITICAL:** workstream path relocation (undocumented breaking change), no update rollback/atomicity, no source authentication
- **7 MAJOR:** tier rule ambiguity, settings.json divergence, manifest schema gap, incomplete tool list, unsigned manifest, supply-chain escalation path, KNOWLEDGE.md migration missing
- **8 MINOR:** various (all will be addressed in revision)

---

## Discussion Items

-> 1. [Workstream & usr/ location + worktrees — ACTIVE]
   2. [Source authentication for v1]
   3. [Update atomicity / rollback]
   4. [settings.json divergence strategy]

---

## Item 1: Workstream & usr/ Location + Worktrees

### Captain's Position

The design puts `usr/` and `workstreams/` at repo root. Three reviewers flagged this as the top issue — not the decision itself, but the undocumented breaking change from `claude/workstreams/`.

**The question is really:** what is the Agency's namespace boundary?

**Option A: Everything under `claude/`**
```
claude/
  usr/
  workstreams/
  tools/
  agents/
  ...
```
- Pro: Single namespace. Clean. `claude/` is the Agency. Everything else is the project.
- Pro: No top-level pollution — repos with lots of their own directories stay clean.
- Pro: No breaking change from current `claude/workstreams/` location.
- Con: Deep nesting. `claude/usr/jordan/captain/handoff.md` is a mouthful.
- Con: Conceptually, workstreams are "the project's work" not "framework internals."

**Option B: Both at repo root**
```
usr/
workstreams/
claude/
```
- Pro: Workstreams and agent instances are first-class project citizens.
- Pro: Shorter paths.
- Con: Three top-level directories claimed by Agency in someone else's repo.
- Con: Breaking change from current layout — needs migration.
- Con: `usr/` is a Unix-ism that may confuse non-Unix developers.

**Related: Worktrees**

Currently at `.claude/worktrees/{name}/`. The design document doesn't address worktrees. Wherever we land on the namespace question, worktrees need a home. Options:
- Stay at `.claude/worktrees/` (hidden, gitignored — current)
- Move to `claude/worktrees/` (visible but gitignored)
- Move to `.worktrees/` (hidden, project-level)

Worktrees are transient (gitignored), so they don't follow the same rules as committed directories. The main concern is discoverability vs clutter.

**My lean:** Option A (`claude/`). The framework should stay in its lane. One top-level directory. The nesting cost is real but the "good neighbor" property matters more for adoption. Worktrees stay at `.claude/worktrees/` — they're Claude Code's concern, not the project's.

