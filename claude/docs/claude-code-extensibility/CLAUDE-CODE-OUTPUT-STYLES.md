---
title: Claude Code Output Styles
created: 2026-01-21T12:50:00
author: captain
version: 1.0.0
source: https://code.claude.com/docs/en/output-styles
---

# Claude Code Output Styles

Output styles customize Claude's response behavior through system prompt modifications.

## Overview

Output styles allow you to define custom personas, response formats, or behavioral modifications that Claude adopts. They modify the system prompt to change how Claude communicates.

## Key Features

### Style File Format

```yaml
# ~/.claude/output-styles/concise.md
---
name: concise
description: Brief, to-the-point responses
---
Be extremely concise. Use bullet points. No pleasantries.
Respond in as few words as possible while being complete.
```

### Style Locations

| Location | Path | Scope |
|----------|------|-------|
| Personal | `~/.claude/output-styles/<name>.md` | All projects |
| Project | `.claude/output-styles/<name>.md` | This project |

### Activating Styles

```bash
# Via CLI flag
claude --style concise

# Via settings
{
  "outputStyle": "concise"
}

# Via /style command
/style concise
```

## Configuration

### Style Frontmatter

| Field | Description | Default |
|-------|-------------|---------|
| `name` | Style identifier | Filename |
| `description` | What the style does | First paragraph |

### Style Content

The body of the style file is injected into Claude's system prompt. It can contain:

- Persona instructions
- Response format requirements
- Tone and voice guidelines
- Domain-specific conventions

## Examples

### Concise Style

```yaml
---
name: concise
description: Minimal responses
---
Respond briefly. No filler words. Use lists when possible.
Skip confirmations and pleasantries.
```

### Verbose Style

```yaml
---
name: verbose
description: Detailed explanations
---
Provide thorough explanations. Include context and reasoning.
Explain your thought process. Suggest alternatives.
```

### Code-Only Style

```yaml
---
name: code-only
description: Just code, no explanations
---
Only output code. No explanations unless explicitly asked.
Use comments in code for any necessary clarification.
```

### Teacher Style

```yaml
---
name: teacher
description: Educational responses
---
Explain concepts clearly. Use examples liberally.
Ask clarifying questions. Suggest learning resources.
Break complex topics into digestible parts.
```

### Security Reviewer Style

```yaml
---
name: security-reviewer
description: Security-focused analysis
---
Analyze all code for security implications.
Flag potential vulnerabilities explicitly.
Reference OWASP guidelines where applicable.
Suggest secure alternatives for risky patterns.
```

## Agency Relevance

**Medium** - Could enhance agent personalities:

| Current Agency | Output Style Equivalent |
|----------------|------------------------|
| Agent personality in agent.md | Output style file |
| Per-agent response patterns | Style per agent |
| Review agent conciseness | Concise style |

### Benefits
1. **Persona separation** - Agent identity in agent.md, style in output-style
2. **Reusable styles** - Same style across multiple agents
3. **Runtime switching** - Change style without agent restart
4. **Composable** - Combine with agent instructions

### Implementation Ideas

```
.claude/output-styles/
├── agent-captain.md      # Captain's communication style
├── agent-reviewer.md     # Reviewer's terse style
├── code-only.md          # For implementation-focused work
└── verbose.md            # For explanatory responses
```

### Agent with Style

```yaml
# .claude/agents/code-reviewer.md
---
name: code-reviewer
description: Reviews code for quality
outputStyle: code-only
---
```

Or dynamically switch:
```
/style verbose
# Now get detailed explanations
```

## Links/Sources

- [Output Styles Documentation](https://code.claude.com/docs/en/output-styles)
- [Customization Guide](https://code.claude.com/docs/en/customization)
