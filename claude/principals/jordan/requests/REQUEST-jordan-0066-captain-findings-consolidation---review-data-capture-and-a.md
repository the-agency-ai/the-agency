# REQUEST-jordan-0066: Findings Consolidation - Review Data Capture and Analysis

**Status:** Open
**Priority:** High
**Requested By:** jordan
**Assigned To:** captain
**Created:** 2026-01-18
**Updated:** 2026-01-18

## Summary

Build a system to capture, consolidate, and analyze findings from code reviews, security reviews, and test reviews. Enable continuous improvement of CLAUDE.md, rules, and review prompts based on patterns.

## Details

### Problem Statement

During the development cycle, subagents produce valuable findings:
- Code quality issues
- Security vulnerabilities
- Missing test coverage
- Architecture concerns

Currently these findings are:
- Lost after the review session
- Not tracked for patterns
- Not used to improve our processes

### Solution

Build a phased system to:
1. Capture findings in structured format
2. Allow lead agent to consolidate and validate
3. Store for historical analysis
4. Periodically analyze for patterns
5. Update CLAUDE.md and rules based on learnings

### Use Cases

1. **Training Data** - Structured examples for future model improvement
2. **Pattern Detection** - "We keep finding eval usage" → add to CLAUDE.md
3. **Quality Metrics** - Track code quality over time
4. **Prompt Improvement** - Refine review prompts based on what's missed
5. **Rule Effectiveness** - Track which rules prevent which issues

---

## Phased Implementation

### Phase A: Schema & File Storage

**Goal:** Define the data format and store findings as JSON files.

**Deliverables:**
- JSON schema for findings (code, security, test reviews)
- JSON schema for consolidated findings
- Directory structure: `claude/logs/reviews/{WORK-ITEM}/`
- Documentation of schema

**Finding Schema (per subagent):**
```json
{
  "schema_version": "1.0",
  "work_item": "REQUEST-jordan-0065",
  "stage": "impl",
  "review_type": "code | security | test",
  "reviewer": {
    "subagent_id": "task-abc123",
    "model": "claude-sonnet-4-20250514",
    "prompt_hash": "sha256:..."
  },
  "timestamp": "2026-01-18T14:30:00Z",
  "findings": [
    {
      "id": "F001",
      "severity": "critical | high | medium | low | info",
      "category": "security | quality | architecture | testing | documentation",
      "file": "tools/myclaude",
      "line_start": 338,
      "line_end": 338,
      "issue": "eval usage allows command injection",
      "recommendation": "Use array-based execution",
      "code_snippet": "eval \"$CLAUDE_CMD\"",
      "cwe": "CWE-78",
      "owasp": "A03:2021"
    }
  ]
}
```

**Consolidated Schema (lead agent output):**
```json
{
  "schema_version": "1.0",
  "work_item": "REQUEST-jordan-0065",
  "stage": "impl",
  "consolidated_by": "captain",
  "timestamp": "2026-01-18T15:00:00Z",
  "source_reviews": ["review-1.json", "review-2.json", "security-1.json"],
  "findings": [
    {
      "id": "C001",
      "source_ids": ["F001", "F003"],
      "status": "valid | invalid | duplicate",
      "severity": "high",
      "issue": "eval usage allows command injection",
      "resolution": "Replaced with array-based execution",
      "commit": "abc123",
      "notes": "Merged F001 and F003 - same issue"
    }
  ],
  "stats": {
    "total_findings": 15,
    "valid": 10,
    "invalid": 2,
    "duplicate": 3
  }
}
```

### Phase B: Capture Tooling

**Goal:** Tools to capture and save findings during reviews.

**Deliverables:**
- `./tools/findings-save` - Save subagent findings to file
- `./tools/findings-consolidate` - Create consolidated findings file
- Updated review prompts that output structured JSON
- Integration with development cycle

**Usage:**
```bash
# Subagent outputs findings to stdout as JSON
# Lead agent captures and saves:
./tools/findings-save REQUEST-jordan-0065 impl code < findings.json

# After consolidation:
./tools/findings-consolidate REQUEST-jordan-0065 impl
```

### Phase C: Analysis Tooling

**Goal:** Tools to analyze findings for patterns.

**Deliverables:**
- `./tools/findings-analyze` - Aggregate and analyze findings
- Pattern detection (frequent issues, CWE clusters)
- Trend reporting (issues over time)
- Suggested CLAUDE.md updates

**Usage:**
```bash
# Analyze all findings from last 30 days
./tools/findings-analyze --since 30d

# Analyze specific category
./tools/findings-analyze --category security

# Output suggested rules
./tools/findings-analyze --suggest-rules
```

**Output example:**
```
Findings Analysis (2026-01-01 to 2026-01-18)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Total findings: 87
  Valid: 72 (83%)
  Invalid: 8 (9%)
  Duplicate: 7 (8%)

Top Issues by Frequency:
  1. eval usage (12 occurrences) - CWE-78
  2. Missing input validation (8 occurrences) - CWE-20
  3. Hardcoded paths (6 occurrences)

Suggested CLAUDE.md Rules:
  1. "Never use eval in shell scripts - use array-based execution"
  2. "Validate all external input before use"
```

### Phase D: Database Migration (Future)

**Goal:** Move from files to SQLite for better querying.

**Deliverables:**
- SQLite schema in agency-service
- Migration tool from JSON files
- Query API for findings
- Dashboard integration in agency-bench

**Deferred until:**
- Schema stabilizes
- Volume justifies database
- Query patterns are understood

---

## Acceptance Criteria

### Phase A: Schema & File Storage
- [x] JSON schema defined for subagent findings
- [x] JSON schema defined for consolidated findings
- [x] Directory structure documented
- [x] Example files created

### Phase B: Capture Tooling
- [ ] `./tools/findings-save` implemented
- [ ] `./tools/findings-consolidate` implemented
- [ ] Review prompts output structured JSON
- [ ] Integration documented in DEVELOPMENT-WORKFLOW.md

### Phase C: Analysis Tooling
- [ ] `./tools/findings-analyze` implemented
- [ ] Pattern detection working
- [ ] Suggested rules output working
- [ ] First analysis run completed

### Phase D: Database Migration (Future)
- [ ] Deferred - criteria TBD

---

## Development Cycle

### Phase A: Implementation
- [ ] Code complete
- [ ] Tests written
- [ ] Local tests passing (GREEN)
- [ ] Committed
- [ ] Tagged: `REQUEST-jordan-0066-phaseA-impl`

### Phase A: Code Review + Security Review
- [ ] 2+ code review subagents spawned
- [ ] 1+ security review subagent spawned
- [ ] Findings consolidated
- [ ] Changes applied
- [ ] Local tests passing (GREEN)
- [ ] Committed
- [ ] Tagged: `REQUEST-jordan-0066-phaseA-review`

### Phase A: Test Review
- [ ] 2+ test review subagents spawned
- [ ] Findings consolidated
- [ ] Test changes applied
- [ ] Local tests passing (GREEN)
- [ ] Committed
- [ ] Tagged: `REQUEST-jordan-0066-phaseA-tests`

*(Repeat for Phase B, C)*

### Complete
- [ ] Tagged: `REQUEST-jordan-0066-complete`

---

## Design Decisions

1. **No deferral** - Valid findings are implemented. Status is: valid, invalid, or duplicate.
2. **Retention policy** - Keep findings indefinitely until there's a reason to change.
3. **Secrets filtering** - Filter out any secrets/credentials found before storing findings.

## Open Questions

1. **Prompt versioning** - Should we track/hash the prompts used for reviews?

## Work Completed

### Phase A: Schema & File Storage
- Created `claude/schemas/finding.schema.json` - JSON schema for individual review findings
- Created `claude/schemas/consolidated-findings.schema.json` - JSON schema for consolidated findings
- Created `claude/schemas/README.md` - Documentation with examples and usage
- Created `claude/logs/reviews/` directory structure
- Created example files from REQUEST-jordan-0072 review:
  - `claude/logs/reviews/REQUEST-jordan-0072/code-review-1.json`
  - `claude/logs/reviews/REQUEST-jordan-0072/security-review-1.json`
  - `claude/logs/reviews/REQUEST-jordan-0072/consolidated.json`

---

## Activity Log

### 2026-01-20 - Phase A Complete
- Implemented JSON schemas for findings capture
- Created directory structure for review logs
- Added example files from actual REQUEST-0072 reviews
- Documented schema in README.md

### 2026-01-18 - Created
- Request created by jordan
