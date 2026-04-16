# PROP-0013: Open Webpage Tool

**Status:** draft
**Priority:** medium
**Created:** 2026-01-06
**Author:** jordan + housekeeping
**Project:** agency

## Origin Story

During a session, the housekeeping agent discovered it could open web pages for the principal using the `open` command on macOS. When Jordan needed to review a Vercel deployment, the agent opened it automatically in the browser.

Jordan: "That was a great trick! We should capture that and turn it into a tool."

This proposal formalizes that discovery into a proper tool with cross-platform support and principal awareness.

## Problem

Agents often need to show principals web resources:
- Deployment previews
- Documentation pages
- GitHub PRs/issues
- External references
- Dashboard URLs

Currently, agents output URLs and principals must copy/paste. The agent discovered it could just open them directly.

## Proposal

Create `./tools/open-webpage` that opens URLs in the principal's default browser.

### Usage

```bash
./tools/open-webpage "https://example.com"
./tools/open-webpage --title "Vercel Preview" "https://preview.vercel.app/..."
```

### Features

| Feature | Description |
|---------|-------------|
| **Cross-platform** | Works on macOS (`open`), Linux (`xdg-open`), Windows (`start`) |
| **Title logging** | Optional `--title` for activity logging |
| **URL validation** | Basic validation before opening |
| **Principal context** | Logs which agent opened what for whom |

### Implementation

```bash
#!/bin/bash
# Tool: open-webpage
# Purpose: Open a URL in the principal's browser
# Usage: ./tools/open-webpage [--title "description"] <url>

set -e

TITLE=""
URL=""

# Parse arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --title)
      TITLE="$2"
      shift 2
      ;;
    *)
      URL="$1"
      shift
      ;;
  esac
done

if [[ -z "$URL" ]]; then
  echo "Usage: ./tools/open-webpage [--title \"description\"] <url>"
  exit 1
fi

# Validate URL (basic check)
if [[ ! "$URL" =~ ^https?:// ]]; then
  echo "Error: URL must start with http:// or https://"
  exit 1
fi

# Log the action
AGENT=$(./tools/agentname 2>/dev/null || echo "unknown")
PRINCIPAL=$(./tools/whoami 2>/dev/null || echo "unknown")
TIMESTAMP=$(./tools/now 2>/dev/null || date)

if [[ -n "$TITLE" ]]; then
  echo "[$TIMESTAMP] $AGENT opening for $PRINCIPAL: $TITLE"
  echo "  URL: $URL"
else
  echo "[$TIMESTAMP] $AGENT opening for $PRINCIPAL: $URL"
fi

# Open based on platform
case "$(uname -s)" in
  Darwin)
    open "$URL"
    ;;
  Linux)
    xdg-open "$URL" &>/dev/null &
    ;;
  MINGW*|CYGWIN*|MSYS*)
    start "$URL"
    ;;
  *)
    echo "Unsupported platform. Please open manually: $URL"
    exit 1
    ;;
esac

echo "Opened in browser."
```

## Use Cases

### Deployment Review

```bash
./tools/open-webpage --title "Preview Deploy" "https://ordinaryfolk-nextgen-abc123.vercel.app"
```

### Documentation Reference

```bash
./tools/open-webpage --title "Claude Code Docs" "https://code.claude.com/docs/en/overview"
```

### GitHub PR

```bash
./tools/open-webpage --title "PR #123: Add dark mode" "https://github.com/org/repo/pull/123"
```

### Dashboard

```bash
./tools/open-webpage --title "Vercel Dashboard" "https://vercel.com/team/project"
```

## Security Considerations

- Only opens URLs, cannot execute arbitrary commands
- URL validation prevents command injection
- Logs all opens for audit trail
- Principal sees what's being opened

## Open Questions

- [ ] Should we have a blocklist for certain domains?
- [ ] Rate limiting to prevent browser spam?
- [ ] Integration with browser profiles (work vs personal)?

## Dependencies

- None (uses built-in OS commands)

## When Approved

- Becomes: INSTR-XXXX
- Assigned to: housekeeping
- Implementation: Immediate (simple tool)

---

## Discussion Log

### 2026-01-06 - Origin

During a session, housekeeping discovered it could open URLs for the principal using `open` on macOS. Jordan recognized this as a useful pattern and requested it be formalized as a tool.

> Jordan: "That was a great trick! We should capture that and turn it into a tool."
