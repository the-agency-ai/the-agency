# {{AGENT_NAME}} Knowledge

## Imported Knowledge Bases

- [Security Patterns](../../../knowledge/security-patterns/INDEX.md) - Security best practices (when available)

## OWASP Top 10 (2021)

### A01: Broken Access Control
- Missing function-level access control
- IDOR (Insecure Direct Object References)
- Path traversal
- CORS misconfiguration

### A02: Cryptographic Failures
- Sensitive data in clear text
- Weak algorithms (MD5, SHA1 for passwords)
- Missing encryption at rest/transit
- Hardcoded secrets

### A03: Injection
- SQL injection
- NoSQL injection
- Command injection
- XSS (Cross-Site Scripting)
- Template injection

### A04: Insecure Design
- Missing threat modeling
- No rate limiting
- Business logic flaws
- Missing input validation

### A05: Security Misconfiguration
- Default credentials
- Unnecessary features enabled
- Missing security headers
- Verbose error messages

### A06: Vulnerable Components
- Outdated dependencies
- Known CVEs
- Unmaintained libraries

### A07: Authentication Failures
- Weak passwords allowed
- Missing MFA
- Session fixation
- Credential stuffing vulnerable

### A08: Software/Data Integrity Failures
- Insecure deserialization
- Missing integrity checks
- Untrusted CI/CD pipelines

### A09: Security Logging Failures
- Missing audit logs
- No alerting on failures
- Logs exposed to users

### A10: SSRF (Server-Side Request Forgery)
- Unvalidated URL inputs
- Cloud metadata access
- Internal service exposure

## Review Checklist

### Authentication
- [ ] Passwords hashed with bcrypt/argon2
- [ ] Session tokens are secure random
- [ ] Tokens expire appropriately
- [ ] MFA available for sensitive operations
- [ ] Account lockout after failed attempts

### Authorization
- [ ] Role-based access control
- [ ] Resource ownership verified
- [ ] API endpoints protected
- [ ] Admin functions isolated

### Input Validation
- [ ] All user input validated
- [ ] Parameterized queries used
- [ ] File uploads restricted
- [ ] Content-Type enforced

### Output Encoding
- [ ] HTML entities escaped
- [ ] JSON properly encoded
- [ ] SQL parameters bound
- [ ] Command arguments escaped

### Secrets
- [ ] No hardcoded secrets
- [ ] Environment variables for config
- [ ] Secrets rotatable
- [ ] Audit logging on access

## Severity Levels

| Level | Description | Response |
|-------|-------------|----------|
| **Critical** | Exploitable, high impact, no auth required | Immediate fix |
| **High** | Exploitable, significant impact | Fix before release |
| **Medium** | Requires specific conditions | Fix in next sprint |
| **Low** | Minimal impact, defense in depth | Track for improvement |

## Common Patterns

### Secure by Default
```typescript
// Good: Explicit allow
const allowed = ['read', 'write'];
if (!allowed.includes(action)) throw new Error('Forbidden');

// Bad: Explicit deny (misses new cases)
const denied = ['admin'];
if (denied.includes(action)) throw new Error('Forbidden');
```

### Input Validation
```typescript
// Good: Validate and sanitize
const userId = parseInt(req.params.id, 10);
if (isNaN(userId) || userId <= 0) throw new Error('Invalid ID');

// Bad: Trust user input
const userId = req.params.id; // Could be "1; DROP TABLE users"
```

### Parameterized Queries
```typescript
// Good: Parameterized
db.query('SELECT * FROM users WHERE id = $1', [userId]);

// Bad: String concatenation
db.query(`SELECT * FROM users WHERE id = ${userId}`);
```

## Reporting Format

```markdown
## Security Finding: [Title]

**Severity:** Critical | High | Medium | Low
**CWE:** CWE-XXX
**Location:** `path/to/file.ts:123`

### Description
What the vulnerability is and why it matters.

### Proof of Concept
How it could be exploited.

### Remediation
Specific fix recommendations with code examples.

### References
- OWASP link
- CWE link
```
