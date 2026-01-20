# Findings Schemas

JSON schemas for capturing and consolidating review findings.

## Overview

During the development cycle, subagents produce review findings (code quality issues, security vulnerabilities, test gaps). These schemas define a structured format for:

1. **Capturing** - Individual review findings from subagents
2. **Consolidating** - Merged/validated findings from lead agent
3. **Analyzing** - Historical pattern detection

## Schemas

### finding.schema.json

Schema for individual review findings (per subagent).

```json
{
  "schema_version": "1.0",
  "work_item": "REQUEST-jordan-0065",
  "stage": "impl",
  "review_type": "code | security | test",
  "reviewer": {
    "subagent_id": "task-abc123",
    "model": "claude-sonnet-4-20250514"
  },
  "timestamp": "2026-01-18T14:30:00Z",
  "findings": [...]
}
```

### consolidated-findings.schema.json

Schema for consolidated findings (lead agent output).

```json
{
  "schema_version": "1.0",
  "work_item": "REQUEST-jordan-0065",
  "stage": "impl",
  "consolidated_by": "captain",
  "timestamp": "2026-01-18T15:00:00Z",
  "source_reviews": ["review-1.json", "security-1.json"],
  "findings": [...],
  "stats": {
    "total_findings": 15,
    "valid": 10,
    "invalid": 2,
    "duplicate": 3
  }
}
```

## Directory Structure

```
claude/logs/reviews/
  {WORK-ITEM}/
    code-review-1.json      # Individual code review
    code-review-2.json      # Second code reviewer
    security-review-1.json  # Security review
    test-review-1.json      # Test review
    consolidated.json       # Lead agent's consolidated output
```

## Finding Fields

### Severity Levels

| Level | Description |
|-------|-------------|
| critical | Must fix immediately, blocks release |
| high | Should fix before merge |
| medium | Should fix, can be prioritized |
| low | Nice to have improvement |
| info | Informational, no action required |

### Categories

| Category | Description |
|----------|-------------|
| security | Security vulnerabilities (CWE, OWASP) |
| quality | Code quality, readability, maintainability |
| architecture | Design patterns, structure |
| testing | Test coverage, test quality |
| documentation | Missing or incorrect docs |
| performance | Performance issues |

### Consolidation Status

| Status | Description |
|--------|-------------|
| valid | Confirmed issue, will be fixed |
| invalid | False positive, not an issue |
| duplicate | Merged with another finding |

## Usage

### Creating a Finding File

```bash
# After running a review subagent, save output as JSON
./tools/findings-save REQUEST-jordan-0065 impl code < review-output.json
```

### Consolidating Findings

```bash
# Lead agent consolidates all reviews for a stage
./tools/findings-consolidate REQUEST-jordan-0065 impl
```

### Analyzing Patterns

```bash
# Find common issues across all findings
./tools/findings-analyze --since 30d --category security
```

## Related

- REQUEST-jordan-0066: Findings Consolidation implementation
- `claude/templates/prompts/code-review.md`: Code review prompt
- `claude/templates/prompts/security-review.md`: Security review prompt
- `claude/templates/prompts/test-review.md`: Test review prompt
