# {{AGENT_NAME}} Knowledge

## Imported Knowledge Bases

- [Documentation Patterns](../../../knowledge/documentation-patterns/INDEX.md) - Documentation best practices (when available)

## Documentation Principles

### Write for the Reader
- Know your audience (developer, user, operator)
- Use appropriate technical level
- Answer the questions they're asking
- Provide context before details

### Keep It Simple
- Use plain language
- Short sentences and paragraphs
- One idea per paragraph
- Active voice over passive

### Make It Scannable
- Clear headings and hierarchy
- Bullet points for lists
- Code examples stand out
- Tables for comparisons

### Keep It Current
- Update with code changes
- Remove outdated content
- Version when necessary
- Date significant documents

## Documentation Types

### README
```markdown
# Project Name

Brief description (1-2 sentences)

## Quick Start
Minimal steps to get running

## Installation
Detailed setup instructions

## Usage
Basic usage examples

## Configuration
Available options

## Contributing
How to contribute

## License
License information
```

### API Documentation
```markdown
## Endpoint Name

`POST /api/resource/create`

Brief description of what this endpoint does.

### Request

**Headers:**
| Header | Required | Description |
|--------|----------|-------------|
| Authorization | Yes | Bearer token |

**Body:**
```json
{
  "name": "string",
  "value": "number"
}
```

### Response

**Success (200):**
```json
{
  "id": "string",
  "created": "timestamp"
}
```

**Errors:**
| Code | Description |
|------|-------------|
| 400 | Invalid request body |
| 401 | Unauthorized |
```

### How-To Guide
```markdown
# How to [Accomplish Task]

## Overview
What you'll accomplish and why.

## Prerequisites
- Requirement 1
- Requirement 2

## Steps

### Step 1: [Action]
Explanation of what to do.

```bash
command to run
```

Expected result.

### Step 2: [Action]
...

## Verification
How to confirm success.

## Troubleshooting
Common issues and solutions.
```

### Architecture Decision Record (ADR)
```markdown
# ADR-001: [Decision Title]

**Status:** Proposed | Accepted | Deprecated | Superseded
**Date:** YYYY-MM-DD

## Context
What is the issue that we're seeing that is motivating this decision?

## Decision
What is the change that we're proposing and/or doing?

## Consequences
What becomes easier or more difficult because of this change?

## Alternatives Considered
What other options were evaluated?
```

## Writing Style Guide

### Headings
- Use sentence case (capitalize first word only)
- Be descriptive but concise
- Use hierarchy properly (don't skip levels)

### Code Examples
- Keep examples minimal but complete
- Use realistic values (not "foo", "bar")
- Include expected output when helpful
- Test all examples

### Links
- Use descriptive link text
- Check links regularly
- Prefer relative links within docs

### Lists
- Use bullets for unordered items
- Use numbers for sequential steps
- Keep items parallel in structure
- Don't overuse nested lists

## Common Patterns

### Command Documentation
```markdown
## command-name

Brief description.

### Usage

```bash
command-name [options] <required-arg>
```

### Arguments

| Argument | Description |
|----------|-------------|
| `<required-arg>` | What this argument is for |

### Options

| Option | Default | Description |
|--------|---------|-------------|
| `--flag` | false | What this flag does |
| `--value=<n>` | 10 | What this value controls |

### Examples

```bash
# Basic usage
command-name input.txt

# With options
command-name --flag --value=20 input.txt
```
```

### Configuration Documentation
```markdown
## Configuration

### Environment Variables

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `API_KEY` | Yes | - | API authentication key |
| `PORT` | No | 3000 | Server port |

### Config File

Location: `~/.config/app/config.json`

```json
{
  "setting": "value",
  "nested": {
    "option": true
  }
}
```

| Key | Type | Description |
|-----|------|-------------|
| `setting` | string | What this controls |
| `nested.option` | boolean | What this enables |
```

## Quality Checklist

- [ ] Accurate and up-to-date
- [ ] Appropriate for audience
- [ ] Clear and concise
- [ ] Well-organized
- [ ] Code examples tested
- [ ] Links working
- [ ] Spelling/grammar checked
- [ ] Consistent formatting
