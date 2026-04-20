# Autonomous Execution Protocol

**Quick Reference:** Read ALL plans first, write completion reports IMMEDIATELY after each iteration, STOP on blockers.

## When This Applies

When executing sprints autonomously (without user interaction between iterations).

## Pre-Execution Checklist

**Before starting autonomous sprint execution:**

1. **Read the sprint plan thoroughly** - Understand goals, scope, and success criteria
2. **Read ALL iteration plans** - Not just the first one; understand the full sequence
3. **Validate dependencies are met** - Check that prerequisites from prior sprints/iterations exist
4. **Identify and FLAG blockers upfront** - Do NOT discover blockers mid-execution
5. **Assess autonomous feasibility** - Can this actually be done without user input?

**If ANY blocker exists:**

- STOP before starting
- Document the blocker clearly
- Request clarification or create collaboration request (`./tools/collaborate`)
- Do NOT proceed with assumptions

## Iteration Completion Requirements

**After EACH iteration:**

1. **Write iteration completion report IMMEDIATELY** - Not after multiple iterations
2. **Include in report:**
   - What was done (specific changes)
   - What was tested (commands run, results)
   - Files changed (full paths)
   - Blockers encountered (if any)
   - Deviations from plan (if any)
3. **Do NOT batch multiple iteration completions** - Each iteration gets its own report

**Location:** `claude/workstreams/{workstream}/epic###/sprint###/sprint###-iteration###-{workstream}-completion.md`

## Sprint Completion Requirements

**Write sprint completion ONLY when:**

1. ALL iterations are complete
2. ALL iteration completion reports are written
3. Sprint goals are actually achieved

**NEVER write a sprint completion prematurely.** This causes confusion about actual project status.

**Sprint completion includes:**

- Summary of all iterations
- Overall sprint outcome
- Any outstanding issues
- Recommendations for next sprint

## Blocker Handling

**If a blocker is discovered during execution:**

1. **STOP execution immediately** - Do not attempt workarounds
2. **Document the blocker clearly:**
   - What you were trying to do
   - What failed or is missing
   - What you need to proceed
3. **Create collaboration request if needed** - Use `./tools/collaborate`
4. **Do NOT proceed with assumptions** - Wait for resolution

**Common blockers:**

- Missing dependencies (files, packages, configurations)
- Unclear requirements in the plan
- Technical constraints not anticipated
- Need input from another workstream

## Why This Protocol Matters

- **Iteration reports** are communication tools - other agents and users rely on them
- **Premature sprint completions** cause false confidence about project status
- **Upfront blocker identification** saves time vs. mid-execution discovery
- **Reading all plans first** prevents rework from missed dependencies

---

*Part of The Agency framework*
