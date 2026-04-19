---
title: Claude Code GitHub Actions
created: 2026-01-21T12:50:00
author: captain
version: 1.0.0
source: https://code.claude.com/docs/en/github-actions
---

# Claude Code GitHub Actions

Integrate Claude Code into GitHub workflows for automated code review, issue triage, and PR assistance.

## Overview

Claude Code provides GitHub Actions that enable AI-powered automation in your CI/CD pipelines. Claude can review PRs, respond to issues, and automate routine tasks.

## Key Features

### Available Actions

| Action | Purpose |
|--------|---------|
| `anthropic/claude-code-action` | General Claude Code integration |
| `anthropic/claude-pr-review` | Automated PR reviews |
| `anthropic/claude-issue-triage` | Issue categorization |

### Trigger Methods

| Trigger | Description |
|---------|-------------|
| `@claude` mention | Mention Claude in PR/issue comments |
| Workflow dispatch | Manual trigger |
| PR events | Automatic on PR open/update |
| Issue events | Automatic on issue creation |

## Configuration

### Basic Workflow

```yaml
# .github/workflows/claude-review.yml
name: Claude Code Review

on:
  pull_request:
    types: [opened, synchronize]

jobs:
  review:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - uses: anthropic/claude-code-action@v1
        with:
          anthropic-api-key: ${{ secrets.ANTHROPIC_API_KEY }}
          task: |
            Review this PR for:
            - Security vulnerabilities
            - Performance issues
            - Code style violations

            Provide actionable feedback as PR comments.
```

### @claude Mentions

```yaml
# .github/workflows/claude-mention.yml
name: Claude Mention Response

on:
  issue_comment:
    types: [created]
  pull_request_review_comment:
    types: [created]

jobs:
  respond:
    if: contains(github.event.comment.body, '@claude')
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - uses: anthropic/claude-code-action@v1
        with:
          anthropic-api-key: ${{ secrets.ANTHROPIC_API_KEY }}
          github-token: ${{ secrets.GITHUB_TOKEN }}
          context: comment
```

### Skill Invocation

```yaml
# Invoke a skill in CI
- uses: anthropic/claude-code-action@v1
  with:
    anthropic-api-key: ${{ secrets.ANTHROPIC_API_KEY }}
    skill: code-review
    skill-args: "--focus security"
```

## Examples

### Automated PR Review

```yaml
name: Automated Review

on:
  pull_request:
    types: [opened, synchronize]

jobs:
  review:
    runs-on: ubuntu-latest
    permissions:
      contents: read
      pull-requests: write

    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0

      - uses: anthropic/claude-pr-review@v1
        with:
          anthropic-api-key: ${{ secrets.ANTHROPIC_API_KEY }}
          github-token: ${{ secrets.GITHUB_TOKEN }}
          review-type: detailed
          focus-areas: |
            - security
            - performance
            - test-coverage
```

### Issue Triage

```yaml
name: Issue Triage

on:
  issues:
    types: [opened]

jobs:
  triage:
    runs-on: ubuntu-latest
    permissions:
      issues: write

    steps:
      - uses: anthropic/claude-issue-triage@v1
        with:
          anthropic-api-key: ${{ secrets.ANTHROPIC_API_KEY }}
          github-token: ${{ secrets.GITHUB_TOKEN }}
          labels: |
            bug
            feature
            documentation
            question
          assign-based-on: codeowners
```

### Interactive @claude

Users can interact with Claude in comments:

```markdown
<!-- In PR comment -->
@claude Can you explain what this function does?

@claude /review-security

@claude Suggest a better name for this variable
```

### Custom CI Task

```yaml
name: Custom Claude Task

on:
  workflow_dispatch:
    inputs:
      task:
        description: 'Task for Claude'
        required: true

jobs:
  execute:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - uses: anthropic/claude-code-action@v1
        with:
          anthropic-api-key: ${{ secrets.ANTHROPIC_API_KEY }}
          task: ${{ github.event.inputs.task }}
          permissions: read-only
```

## Security Considerations

### API Key Management

```yaml
# Store API key as repository secret
# Settings → Secrets → Actions → New repository secret
# Name: ANTHROPIC_API_KEY
```

### Permission Scoping

```yaml
permissions:
  contents: read      # Read repository
  pull-requests: write # Comment on PRs
  issues: write       # Comment on issues
```

### Read-Only Mode

```yaml
- uses: anthropic/claude-code-action@v1
  with:
    permissions: read-only  # Claude cannot modify files
```

## Agency Relevance

**High** - GitHub Actions extend Agency to CI/CD:

| Current Agency | GitHub Actions Equivalent |
|----------------|--------------------------|
| Manual code review | Automated PR review |
| `./tools/review-spawn` | Claude PR review action |
| Issue management | Automated triage |
| Manual collaboration | @claude mentions |

### Benefits
1. **Automation** - Reviews without manual intervention
2. **Consistency** - Same review standards for all PRs
3. **Speed** - Immediate feedback on PR creation
4. **Integration** - Native GitHub experience

### Implementation Ideas

#### Agency PR Review Action

```yaml
name: Agency Review

on:
  pull_request:
    types: [opened, synchronize]

jobs:
  review:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - uses: anthropic/claude-code-action@v1
        with:
          anthropic-api-key: ${{ secrets.ANTHROPIC_API_KEY }}
          task: |
            You are an Agency code reviewer.

            Review using Agency standards from CLAUDE.md:
            - Red-Green model compliance
            - Work item documentation
            - Test coverage
            - Security review items

            Format findings as Agency review format.
```

#### Release Verification

```yaml
name: Release Check

on:
  push:
    tags:
      - 'v*'

jobs:
  verify:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - uses: anthropic/claude-code-action@v1
        with:
          anthropic-api-key: ${{ secrets.ANTHROPIC_API_KEY }}
          task: |
            Verify this release:
            1. Check all tests pass
            2. Verify CHANGELOG updated
            3. Confirm version numbers match
            4. Check for uncommitted changes
```

## Links/Sources

- [GitHub Actions Documentation](https://code.claude.com/docs/en/github-actions)
- [Claude PR Review Action](https://github.com/marketplace/actions/claude-pr-review)
- [CI/CD Integration Guide](https://code.claude.com/docs/en/ci-cd)
