# {{AGENT_NAME}} Knowledge

## Imported Knowledge Bases

- [Code Review Patterns](../../../knowledge/code-review-patterns/INDEX.md) - Review best practices (when available)

## Review Philosophy

### Goals
1. **Catch bugs** before they reach production
2. **Improve code quality** through constructive feedback
3. **Share knowledge** across the team
4. **Maintain consistency** with project standards

### Mindset
- Assume good intent
- Ask questions, don't assume
- Praise good patterns
- Focus on the code, not the author
- Be specific and actionable

## Review Checklist

### Correctness
- [ ] Logic is correct for all cases
- [ ] Edge cases handled (null, empty, boundaries)
- [ ] Error cases handled appropriately
- [ ] No obvious bugs or typos

### Design
- [ ] Appropriate abstraction level
- [ ] Single responsibility principle
- [ ] Dependencies are reasonable
- [ ] No unnecessary complexity

### Readability
- [ ] Clear naming (variables, functions, classes)
- [ ] Code is self-documenting
- [ ] Comments explain "why" not "what"
- [ ] Consistent formatting

### Testing
- [ ] Tests cover new functionality
- [ ] Edge cases tested
- [ ] Tests are meaningful (not just coverage)
- [ ] No flaky tests introduced

### Performance
- [ ] No obvious performance issues
- [ ] Appropriate data structures
- [ ] Database queries are efficient
- [ ] No N+1 query problems

### Security
- [ ] No hardcoded secrets
- [ ] Input validation present
- [ ] No injection vulnerabilities
- [ ] Appropriate access control

## Feedback Levels

### Blocking (Must Fix)
Issues that must be addressed before merge:
- Bugs or logic errors
- Security vulnerabilities
- Breaking changes
- Missing tests for critical paths

### Non-Blocking (Should Fix)
Improvements that should be made but don't block:
- Code style inconsistencies
- Minor refactoring opportunities
- Documentation improvements
- Additional test cases

### Nitpicks (Nice to Have)
Optional suggestions:
- Personal preferences
- Alternative approaches
- Future considerations

## Feedback Format

### Good Feedback
```markdown
**Issue:** The `processOrder` function doesn't handle the case where `items` is empty.

**Why:** This will cause a division by zero on line 45 when calculating average.

**Suggestion:**
```typescript
if (items.length === 0) {
  return { total: 0, average: 0 };
}
```
```

### Bad Feedback
```markdown
This is wrong.
```

## Common Patterns to Watch

### Error Handling
```typescript
// Good: Specific error handling
try {
  await saveUser(user);
} catch (error) {
  if (error instanceof ValidationError) {
    return { status: 400, message: error.message };
  }
  throw error; // Re-throw unexpected errors
}

// Bad: Swallowing errors
try {
  await saveUser(user);
} catch (error) {
  console.log(error); // Error is lost
}
```

### Null/Undefined Handling
```typescript
// Good: Explicit handling
const name = user?.profile?.name ?? 'Anonymous';

// Bad: Assuming existence
const name = user.profile.name; // Throws if null
```

### Async/Await
```typescript
// Good: Proper async handling
const [users, orders] = await Promise.all([
  fetchUsers(),
  fetchOrders()
]);

// Bad: Sequential when parallel is possible
const users = await fetchUsers();
const orders = await fetchOrders(); // Waits unnecessarily
```

### Resource Cleanup
```typescript
// Good: Using finally or try-with-resources
const connection = await db.connect();
try {
  await connection.query(sql);
} finally {
  await connection.close();
}

// Bad: Resource leak on error
const connection = await db.connect();
await connection.query(sql); // If this throws, connection leaks
await connection.close();
```

## Review Response Template

```markdown
## Review Summary

**Overall:** Approve / Request Changes / Comment

### Blocking Issues
1. [Issue description with location and fix]

### Suggestions
1. [Non-blocking improvement]

### Praise
- Good use of [pattern] in [location]

### Questions
- Why was [approach] chosen over [alternative]?
```

## Red Flags

Watch for these patterns:
- [ ] `// TODO: fix later` in critical paths
- [ ] Commented-out code without explanation
- [ ] Magic numbers without constants
- [ ] Deeply nested conditionals (>3 levels)
- [ ] Functions over 50 lines
- [ ] God classes/modules
- [ ] Copy-pasted code blocks
- [ ] Missing error handling in async code
- [ ] Direct database queries in controllers
- [ ] Hardcoded configuration values
