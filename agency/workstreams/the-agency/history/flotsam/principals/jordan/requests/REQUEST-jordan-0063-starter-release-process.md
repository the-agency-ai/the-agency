# REQUEST-jordan-0063: Starter Release Process - Tools, Documentation, and Security

**Status:** In Progress (Implementation Complete, Pending Test Review)
**Priority:** High
**Requested By:** jordan
**Assigned To:** captain
**Created:** 2026-01-18
**Updated:** 2026-01-18

## Summary

Establish robust release process for the-agency-starter with proper tooling, documentation, and security review.

## Scope
1. Familiarize with and audit starter-* tools
2. Fix starter-verify syntax error (line 320)
3. Document release process (verify/test before push)
4. Add pointer in CLAUDE.md
5. Full code & security audit with subagents
6. Test review

## Deliverables
- Fixed and audited starter-* tools
- Release process documentation
- CLAUDE.md updates
- Security audit findings addressed

## Acceptance Criteria

- [x] All starter-* tools reviewed and working
- [x] starter-verify syntax error fixed
- [x] Release process documented
- [x] CLAUDE.md has pointer to release docs
- [x] Code review complete (2 subagents)
- [x] Security audit complete
- [ ] Test review complete (76/76 tests passing, needs formal review)
- [x] No new security issues introduced

## Work Completed

### 2026-01-18 - Implementation

**Tools Reviewed:**
- `starter-compare` - Compare source to installed
- `starter-verify` - Verify installation
- `starter-cleanup` - Clean test artifacts
- `starter-test` - Run test suite (13 tests, 76 assertions)
- `starter-release` - Cut releases

**Bugs Fixed:**
1. `starter-verify` line 320 - Missing `main "$@"` call and function closing brace
2. `.mcp.json` - Removed `${workspaceFolder}` env that Claude Code doesn't support
3. `agency-server` - Added `import.meta.url` location detection for robust PROJECT_ROOT

**Security Audit (2 Subagents):**

Shell scripts (starter-*):
- 0 Critical, 4 High, 4 Medium, 6 Low

TypeScript (agency-server):
- 1 Critical, 3 High, 2 Medium, 1 Low

**Security Fixes Applied:**

| Severity | Issue | Fix |
|----------|-------|-----|
| CRITICAL | Command injection via execSync | Changed to execFileSync |
| HIGH | Path traversal in getAgentStatus | Added isValidName() validation |
| HIGH | Path traversal in get_workstream_context | Added path resolution check |
| HIGH | Path traversal in resource reading | Added file extension validation |
| HIGH | Unsafe rm -rf in starter-compare | Added safety checks |
| HIGH | Unsafe rm -rf in starter-cleanup | Added test directory check |
| HIGH | Unsafe rm -rf in starter-verify | Added path validation |
| HIGH | eval usage in starter-compare | Replaced with array-based find args |
| HIGH | eval usage in myclaude | Replaced with array-based command |
| HIGH | Command injection in browser tool | URL passed via env vars |

**Documentation Created:**
- `claude/docs/STARTER-RELEASE-PROCESS.md` - Full release workflow
- Updated `CLAUDE.md` with reference

**Tests:** 76/76 passing

---

## Activity Log

### 2026-01-18 - Created
- Request created by jordan

### 2026-01-18 - Implementation Complete
- Fixed starter-verify syntax error
- Fixed MCP server location detection
- Completed security audit with 2 subagents
- Applied all CRITICAL and HIGH severity fixes
- Created release process documentation
- Updated CLAUDE.md
- All 76 tests passing
