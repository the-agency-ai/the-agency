# {{AGENT_NAME}} Knowledge

## Imported Knowledge Bases

- [Testing Patterns](../../../knowledge/testing-patterns/INDEX.md) - Testing best practices (when available)

## Test Design Principles

### FIRST Principles
- **Fast** - Tests should run quickly
- **Independent** - No dependencies between tests
- **Repeatable** - Same result every time
- **Self-validating** - Pass/fail without manual inspection
- **Timely** - Written close to the code

### Arrange-Act-Assert (AAA)
```typescript
test('should calculate total with tax', () => {
  // Arrange
  const cart = new Cart();
  cart.addItem({ price: 100, quantity: 2 });

  // Act
  const total = cart.calculateTotal({ taxRate: 0.1 });

  // Assert
  expect(total).toBe(220);
});
```

### Given-When-Then (BDD)
```typescript
describe('Cart', () => {
  describe('given items in cart', () => {
    describe('when calculating total with tax', () => {
      it('then should include tax in total', () => {
        // ...
      });
    });
  });
});
```

## Test Types

### Unit Tests
- Test single function/component in isolation
- Mock external dependencies
- Fast execution (<100ms per test)
- High coverage target (80%+)

### Integration Tests
- Test module interactions
- Use real dependencies where practical
- Test database queries, API calls
- Moderate coverage (critical paths)

### E2E Tests
- Test complete user flows
- Run against real application
- Slower, fewer tests
- Cover happy paths and critical failures

### Contract Tests
- Verify API contracts
- Consumer-driven contracts
- Catch breaking changes early

## Coverage Strategy

### What to Cover
1. **Critical business logic** - Always test
2. **Edge cases** - Boundaries, nulls, empties
3. **Error handling** - Exceptions, error states
4. **Happy paths** - Main success scenarios

### What to Skip
- Simple getters/setters
- Framework-generated code
- Third-party library internals
- Configuration files

### Coverage Metrics
| Metric | Target | Notes |
|--------|--------|-------|
| Line coverage | 80%+ | Minimum threshold |
| Branch coverage | 70%+ | Decision paths |
| Function coverage | 90%+ | All functions exercised |

## Mocking Strategies

### When to Mock
- External services (APIs, databases)
- Time-dependent code
- Random/non-deterministic behavior
- Expensive operations

### When NOT to Mock
- The unit under test
- Simple value objects
- Pure functions
- When integration test is appropriate

### Mock Patterns
```typescript
// Stub: Returns canned response
const userService = { getUser: jest.fn().mockResolvedValue({ id: 1 }) };

// Spy: Tracks calls while using real implementation
const spy = jest.spyOn(service, 'process');

// Fake: Working implementation for testing
class FakeDatabase implements Database {
  private data = new Map();
  async get(id) { return this.data.get(id); }
  async set(id, value) { this.data.set(id, value); }
}
```

## Test Organization

### File Structure
```
src/
  components/
    Button.tsx
    Button.test.tsx      # Co-located unit tests
  services/
    UserService.ts
    UserService.test.ts
tests/
  integration/           # Integration tests
    api.test.ts
  e2e/                   # End-to-end tests
    checkout.spec.ts
```

### Naming Conventions
```typescript
// Descriptive test names
test('should return empty array when no items match filter');
test('should throw ValidationError when email is invalid');
test('should retry 3 times before failing');

// NOT: vague names
test('works');
test('handles error');
```

## Framework Patterns

### Jest/Vitest
```typescript
describe('UserService', () => {
  let service: UserService;

  beforeEach(() => {
    service = new UserService();
  });

  afterEach(() => {
    jest.clearAllMocks();
  });

  test('should create user', async () => {
    const user = await service.create({ name: 'Test' });
    expect(user.id).toBeDefined();
  });
});
```

### Playwright (E2E)
```typescript
test('user can complete checkout', async ({ page }) => {
  await page.goto('/products');
  await page.click('[data-testid="add-to-cart"]');
  await page.click('[data-testid="checkout"]');
  await page.fill('[name="email"]', 'test@example.com');
  await page.click('[data-testid="submit"]');
  await expect(page.locator('.success')).toBeVisible();
});
```

### pytest
```python
@pytest.fixture
def user_service(db):
    return UserService(db)

def test_create_user(user_service):
    user = user_service.create(name="Test")
    assert user.id is not None
```

## Test Review Checklist

- [ ] Tests are independent (no shared state)
- [ ] Assertions are meaningful
- [ ] Error messages are helpful
- [ ] Mocks are appropriate (not over-mocking)
- [ ] Edge cases covered
- [ ] No flaky tests (timing, random)
- [ ] Test names describe behavior
- [ ] Setup/teardown is clean
