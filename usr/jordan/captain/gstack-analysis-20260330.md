# gstack Analysis for Agency 2.0

**Date:** 2026-03-30
**Source:** `/Users/jordan_of/code/gstack/` (Garry Tan / YC — v1.1.0)
**Purpose:** What to adopt, adapt, or ignore for The Agency

---

## What gstack Is

A single-user Claude Code skill pack for solo YC founders. Two pillars: (1) persistent headless Chromium daemon with compiled CLI, (2) opinionated workflow skills as SKILL.md markdown prompts. A **product, not a framework** — designed for one person. The Agency is multi-agent, multi-principal. That context colors everything below.

---

## Adopt (High Priority)

### 1. Template System for Skills

**Pattern:** SKILL.md files are generated from `.tmpl` templates with `{{PLACEHOLDER}}` tokens. A build step (`gen-skill-docs.ts`) resolves placeholders from resolver modules. CI catches stale generated files via `--dry-run`.

**Why it matters:** We have 42+ commands with shared-block drift — QG methodology prose copied across multiple commands. A template system with a build step solves this mechanically.

**What to adapt:** Our skills include YAML frontmatter, not just prose. The template system should generate frontmatter too. Resolvers should inject our preamble, methodology references, and telemetry footers.

### 2. Preamble Injection

**Pattern:** Every skill starts with `{{PREAMBLE}}` — a tiered bash block (tiers 1-4) that handles session context, config, telemetry, and learnings count. Output is printed to stdout and parsed by Claude as natural language context.

**Tiers:** T1 = minimal (update check, telemetry). T2 = T1 + voice directive + completeness principle. T3 = T2 + repo mode + search-before-building. T4 = T3 + test failure triage.

**ELI16 mode:** When 3+ sessions running, every question re-grounds user on context ("which project, which branch").

**Why it matters:** Our 42 commands start cold — no universal context injection. The ELI16 insight is sharp for multi-agent: when juggling windows, every question should include context.

**What to adapt:** Our preamble should read handoff.md state (our primary continuity mechanism), not just session $PPID.

### 3. Learnings JSONL

**Pattern:** Per-project JSONL at `~/.gstack/projects/{slug}/learnings.jsonl`. Schema: `{ts, skill, type, key, insight, confidence, source, branch, commit, files[]}`. Types: pattern/pitfall/preference/architecture/tool. Sources: observed/user-stated/inferred/cross-model. Confidence decays 1pt/30 days for non-user-stated entries. Dedup at read time (latest winner per key+type).

**Why it matters:** Our biggest memory gap. We have handoff.md (session-to-session, unstructured) and Claude Code auto-memory (unstructured). Neither is per-skill, typed, confidence-scored, or searchable across sessions. In our multi-agent context, learnings become shared team memory — more valuable for us than for a solo founder.

**What to adapt:** Store at `usr/{principal}/{project}/learnings.jsonl` (version-controlled, principal-scoped) not `~/.gstack/` (local-only). Our memory model is repo-committed.

### 4. Confidence-Scored Findings

**Pattern:** Every review finding gets a 1-10 confidence score with display rules: 9-10 show normally, 5-6 show with caveat, 3-4 suppress to appendix, 1-2 only if P0 severity. Format: `[SEVERITY] (confidence: N/10) file:line — description`.

**Why it matters:** Our review agents treat all findings equally, creating noise. Confidence scoring + suppression rules would dramatically improve signal-to-noise.

**What to adopt:** Directly. Inject `{{CONFIDENCE_CALIBRATION}}` into our reviewer agents.

---

## Adopt (Medium Priority)

### 5. Decision Classification

**Pattern:** `/autoplan` classifies every intermediate question:
- **Mechanical** — one clearly right answer, auto-decide silently
- **Taste** — reasonable people disagree, auto-decide with recommendation, surface at final gate
- **User Challenge** — both models agree user's stated direction should change, NEVER auto-decide

**Why it matters:** We treat all code-review findings similarly. Making the classification explicit lets us auto-fix mechanical issues and only surface Taste + User Challenge for human review. The User Sovereignty principle ("two models agreeing is signal, not mandate") belongs in our review dispatch protocol.

### 6. Diff-Scope Categorization

**Pattern:** `gstack-diff-scope` categorizes changes: SCOPE_FRONTEND / SCOPE_BACKEND / SCOPE_TESTS etc. Used to conditionally run reviews — skip design reviewer if no frontend changes.

**Why it matters:** Our QG runs all agents regardless of what changed. Diff-scope would make QG faster and more targeted.

### 7. Three-Tier Skill Testing

**Pattern:**
| Tier | What | Cost | Speed |
|------|------|------|-------|
| 1 — Static | Parse skills, validate command references against registry | Free | <5s |
| 2 — E2E | Spawn `claude -p` as subprocess, stream NDJSON | ~$3.85 | ~20min |
| 3 — LLM-judge | Sonnet scores skill docs on clarity/completeness/actionability | ~$0.15 | ~30s |

Diff-based test selection: each test declares file dependencies; only affected tests run.

**Why it matters:** We have zero automated skill testing. As Agency 2.0 grows, this matters.

### 8. Spec Review Loop (Fix Cycle)

**Pattern:** `{{SPEC_REVIEW_LOOP}}`: Write doc → dispatch adversarial reviewer subagent (fresh context) → fix → re-dispatch, max 3 iterations. Convergence guard: if same issues on consecutive iterations, persist as "## Reviewer Concerns" and stop.

**Why it matters:** Directly applicable to `/define` (PVR review), `/design` (A&D review), `/plan-complete` (final review). The convergence guard prevents infinite loops.

### 9. Skill-Owned Hook Declarations

**Pattern:** Skills declare `hooks:` in frontmatter YAML. `/investigate` hooks Edit/Write to enforce debug scope boundary via `check-freeze.sh`.

**Why it matters:** Our hookify rules are global. Per-skill hooks are tighter — the skill declares what it needs enforced. `/define` could hook Write to prevent code file creation. `/investigate` could lock edits to the bug's directory.

---

## Adopt (Lower Priority)

### 10. Review Dashboard as Shared State

**Pattern:** JSONL review log with staleness detection (N commits since review) and via-tracking (review run by /ship vs /review directly). Any skill can write; /ship reads to gate shipping.

**What to adapt:** Add `commit` hash and `via` field to QGR entries for staleness detection.

### 11. AskUserQuestion Format Discipline

**Pattern:** Every question re-grounds (project + branch + task), simplifies (plain English), recommends (with Completeness X/10 per option), and lists options with effort scales.

### 12. Bisectable Commits

**Pattern:** `/ship` decomposes diff into logical commits ordered by dependency. Each logical unit = one commit.

### 13. User Sovereignty + Layer 1/2/3 Knowledge

**Pattern:** User Sovereignty: "two models agreeing is signal, not mandate; always ask before acting." Knowledge layers: tried-and-true (L1), new-and-popular (L2), first-principles (L3) — prize L3 above all.

### 14. Eval Store with Cross-Run Comparison

**Pattern:** Structured JSON per test run with git branch, SHA, per-test records. Auto-comparison against previous run. "REGRESSION: X was passing, now fails."

**Why it matters:** We have no QG trend tracking. An eval store would answer "are we getting better?"

---

## Ignore

| Pattern | Why |
|---------|-----|
| Persistent browser daemon | Core gstack product, not relevant to Agency |
| `gstack-update-check` | Public distribution model, we commit to master |
| Repo-mode detection (solo vs collaborative) | We're always multi-agent collaborative |
| Supabase telemetry pipeline | We're local-only |
| Multi-host output (Claude/Codex/Factory) | We're Claude Code-only (for now) |
| Community PR guardrails | Single-maintainer concerns |
| ETHOS.md as injected philosophy | Garry's personal voice; our equivalent is process discipline |
| Compiled binary distribution | We use shell scripts |

---

## Key Structural Differences

1. **Scope.** gstack = single-user. Agency = multi-agent, multi-principal.
2. **Memory.** gstack = `~/.gstack/` (local-only). Agency = `usr/{principal}/` (repo-committed).
3. **Skills.** gstack = self-contained workflow documents. Agency = shorter commands + hookify + agent dispatch.
4. **Testing.** gstack = three automated tiers. Agency = zero. Gap.
5. **Philosophy injection.** ETHOS.md = personal builder voice. Agency = process discipline (Work Pattern, QG protocol).

---

## Top 5 Actionable Items

1. **Template system** — `{{PLACEHOLDER}}` + build step. Solves shared-block drift across 42 commands. Highest ROI.
2. **Learnings JSONL** — per-project, typed, confidence-scored memory. Biggest gap. Multi-agent amplifier.
3. **Confidence scoring** — on all review findings. Immediate noise reduction.
4. **Decision classification** — Mechanical/Taste/User Challenge. Auto-fix easy stuff, surface real decisions.
5. **Diff-scope for conditional QG** — skip irrelevant review agents. Faster quality gates.
