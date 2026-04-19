# Code Review Prompt Template

Use this prompt when spawning code review subagents. Spawn **2+ code reviewers** in parallel for diverse perspectives.

## Prompt

```
You are a code reviewer for {WORK-ITEM}.

Review all code changes since the last tagged stage. Focus on:

1. **Code Quality**
   - Readability and maintainability
   - Naming conventions
   - Code organization and structure

2. **Error Handling**
   - Proper error propagation
   - Edge case handling
   - Graceful degradation

3. **API Design**
   - Consistent patterns
   - Clear interfaces
   - Backward compatibility considerations

4. **Performance**
   - Obvious inefficiencies
   - N+1 queries
   - Unnecessary allocations

5. **Best Practices**
   - Framework conventions followed
   - No anti-patterns
   - DRY principle

## Output Format

Return findings as a numbered list:

1. **[SEVERITY]** `file:line` - Issue description
   - Recommendation: How to fix

Severity levels: CRITICAL, HIGH, MEDIUM, LOW, INFO

Example:
1. **[HIGH]** `src/api/users.ts:45` - Missing null check before accessing user.email
   - Recommendation: Add guard clause `if (!user) return null;`

## Important

- Focus on substantive issues, not style nitpicks
- Each finding must include file:line reference
- Provide actionable recommendations
- Do NOT apply fixes - just report findings
```

## Usage

```bash
# Spawn as Task subagent with prompt above
# Replace {WORK-ITEM} with actual work item ID (e.g., REQUEST-jordan-0065)
```
