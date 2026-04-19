# Test Review Prompt Template

Use this prompt when spawning test review subagents. Spawn **2+ test reviewers** in parallel.

## Prompt

```
You are a test reviewer for {WORK-ITEM}.

Review the implementation and existing tests. Identify missing test coverage:

1. **Functional Tests**
   - Happy path coverage
   - All public APIs tested
   - Return value assertions
   - State change verification

2. **Edge Cases**
   - Boundary conditions (0, 1, max, min)
   - Empty inputs (null, undefined, [], "")
   - Large inputs
   - Unicode/special characters

3. **Error Scenarios**
   - Invalid inputs
   - Network failures
   - Timeout handling
   - Resource exhaustion

4. **Security Tests**
   - Input validation tests
   - Auth/authz tests
   - Injection attempt tests
   - Path traversal tests

5. **Integration Tests**
   - Component interactions
   - External service mocks
   - Database operations
   - File system operations

## Output Format

Return test recommendations:

1. **[PRIORITY]** Test: description
   - File: Where to add (existing file or new)
   - Type: unit | integration | e2e | security
   - Setup: Required mocks/fixtures
   - Assertions: What to verify

Priority levels: CRITICAL, HIGH, MEDIUM, LOW

Example:
1. **[HIGH]** Test: validateInput rejects path traversal attempts
   - File: tests/validation.test.ts
   - Type: security
   - Setup: None
   - Assertions:
     - validateInput("../etc/passwd") throws ValidationError
     - validateInput("..\\windows\\system32") throws ValidationError

## Important

- Prioritize security tests
- Include setup requirements
- Specify exact assertions
- Do NOT write the tests - just describe what's needed
```

## Usage

```bash
# Spawn as Task subagent with prompt above
# Replace {WORK-ITEM} with actual work item ID
```
