# Findings Consolidation Template

Use this template when consolidating findings from multiple review subagents.

## Process

1. Collect all findings from subagents
2. Deduplicate (same issue reported by multiple reviewers)
3. Validate each finding (is it real?)
4. Prioritize by severity
5. Create modification plan

## Consolidation Format

```markdown
# Consolidated Findings: {WORK-ITEM}

**Stage:** {review | tests}
**Date:** {YYYY-MM-DD}
**Source Reviews:** {count} code, {count} security, {count} test

## Summary

| Severity | Count |
|----------|-------|
| CRITICAL | X |
| HIGH     | X |
| MEDIUM   | X |
| LOW      | X |
| Total    | X |

## Findings

### CRITICAL

#### C1. {Issue Title}
- **Source:** Reviewer 1, Reviewer 3 (merged)
- **File:** `path/to/file.ts:123`
- **Issue:** Description
- **CWE:** CWE-XXX (if security)
- **Status:** valid
- **Action:** Description of fix to apply

### HIGH

#### H1. {Issue Title}
...

### MEDIUM

#### M1. {Issue Title}
...

### LOW

#### L1. {Issue Title}
...

## Duplicates Removed

- Finding X from Reviewer 2 = merged with C1
- Finding Y from Reviewer 1 = same as H2

## Invalid Findings

- Finding Z from Reviewer 3: {reason why invalid}

## Modification Plan

Apply in this order:

1. [ ] C1 - {file} - {brief description}
2. [ ] H1 - {file} - {brief description}
3. [ ] H2 - {file} - {brief description}
...

## Post-Application Checklist

- [ ] All modifications applied
- [ ] Tests run locally - GREEN
- [ ] No regressions introduced
- [ ] Ready for commit
```

## Status Values

- **valid** - Real issue, will fix
- **invalid** - False positive or not applicable
- **duplicate** - Same as another finding (note which)

## Key Principles

1. **Every valid finding gets fixed** - No deferral
2. **Apply all at once** - Don't fix piecemeal
3. **Document reasoning** - Explain why invalid findings are rejected
4. **Order matters** - Critical first, then by file locality
