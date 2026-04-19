#!/usr/bin/env python3
"""
Stop hook prototype - evaluates whether Claude should be allowed to stop.

Input (stdin): JSON with session_id, transcript_path, stop_hook_active, etc.
Output (stdout): JSON with decision and reason
Exit codes:
  0 - Success (stdout parsed as JSON)
  2 - Block (stderr shown to Claude)
  Other - Non-blocking error
"""

import json
import os
import subprocess
import sys
from pathlib import Path

# Files that change every session and shouldn't block stopping
# Patterns support exact matches and glob-style wildcards
EXCLUDE_PATTERNS = [
    "agency/data/messages.db",      # Tool run logs database
    "agency/data/*.db",             # Any database in data dir
    "history/push-log.md",          # Push accountability log
    "*.pyc",                        # Python bytecode
    "__pycache__/*",                # Python cache
]

# File categorization patterns — used to distinguish impl files from docs/handoffs
# Categories drive different stop-check behavior:
#   impl     — BLOCK stopping (real work uncommitted)
#   handoff  — SILENT (the agent just wrote the handoff)
#   doc      — WARN, allow stopping
#   config   — WARN, allow stopping (yaml/json/toml — usually deliberate)
#   other    — WARN, allow stopping
FILE_CATEGORIES = {
    'handoff': [
        'usr/*/*-handoff.md',
        'usr/*/*/handoff.md',
        'usr/*/*/dispatches/*',
        'usr/*/*/history/*',
    ],
    'impl': [
        '*.ts', '*.tsx', '*.js', '*.jsx',
        '*.py', '*.rs', '*.go',
        '*.java', '*.swift', '*.kt',
        '*.sh', '*.bash',
        '*.bats',
        'tests/**/*.test.*', 'tests/**/*.spec.*',
        'agency/tools/*',           # bash tools (no extension)
        'agency/tools/lib/*',       # tool libraries
        '.claude/hooks/*.py',       # python hooks
        '.claude/hooks/*.sh',       # shell hooks
    ],
    'config': [
        '*.yaml', '*.yml', '*.toml', '*.json',
        'agency/config/*',
        '.claude/settings*.json',
    ],
    'doc': [
        '*.md', '*.txt', '*.rst',
    ],
}


def should_exclude(filepath: str) -> bool:
    """Check if a file should be excluded from uncommitted changes check."""
    import fnmatch
    clean_path = _strip_status_prefix(filepath)

    for pattern in EXCLUDE_PATTERNS:
        if fnmatch.fnmatch(clean_path, pattern):
            return True
    return False


def _strip_status_prefix(filepath: str) -> str:
    """Strip git status prefix (e.g., ' M ', '?? ', etc.) and return clean path."""
    clean_path = filepath.strip()
    if len(clean_path) >= 3 and clean_path[1] == ' ':
        clean_path = clean_path[2:].strip()
    elif len(clean_path) >= 2 and clean_path[0] in 'MADRCU?' and clean_path[1] == ' ':
        clean_path = clean_path[2:].strip()
    return clean_path


def categorize_file(filepath: str) -> str:
    """Categorize a file as impl/handoff/config/doc/other.

    Categories are checked in priority order: handoff first (most specific),
    then impl, config, doc. Anything unmatched is 'other'.
    """
    import fnmatch
    clean_path = _strip_status_prefix(filepath)

    # Check categories in priority order
    for category in ['handoff', 'impl', 'config', 'doc']:
        for pattern in FILE_CATEGORIES[category]:
            # fnmatch doesn't handle ** so we substitute with simple glob behavior
            if '**' in pattern:
                # Treat ** as 'any path segment(s)'
                regex_pattern = pattern.replace('**', '*')
                if fnmatch.fnmatch(clean_path, regex_pattern):
                    return category
            elif fnmatch.fnmatch(clean_path, pattern):
                return category

    return 'other'


def get_git_status() -> dict:
    """Check for uncommitted changes, categorized by file type."""
    try:
        # Check for any changes (staged or unstaged)
        result = subprocess.run(
            ["git", "status", "--porcelain"],
            capture_output=True,
            text=True,
            timeout=5
        )
        changes = result.stdout.strip().split('\n') if result.stdout.strip() else []

        # Filter out things we don't care about
        significant_changes = [
            c for c in changes
            if c and not c.strip().startswith('??')  # Ignore untracked
            and not should_exclude(c)  # Ignore excluded patterns
        ]

        # Categorize by file type
        categorized = {'impl': [], 'handoff': [], 'config': [], 'doc': [], 'other': []}
        for change in significant_changes:
            category = categorize_file(change)
            categorized[category].append(_strip_status_prefix(change))

        return {
            "has_changes": len(significant_changes) > 0,
            "change_count": len(significant_changes),
            "changes": significant_changes[:5],
            "categorized": categorized,
            "impl_count": len(categorized['impl']),
            "non_impl_count": len(significant_changes) - len(categorized['impl']),
        }
    except Exception as e:
        return {"has_changes": False, "error": str(e)}


def check_context_saved(project_dir: str) -> dict:
    """Check if context was saved recently (within this session)."""
    context_file = Path(project_dir) / "claude" / "agents" / "captain" / "backups" / "latest" / "context.jsonl"

    if not context_file.exists():
        return {"saved": False, "reason": "No context file found"}

    # Check if modified in last 30 minutes (rough heuristic)
    import time
    mtime = context_file.stat().st_mtime
    age_minutes = (time.time() - mtime) / 60

    return {
        "saved": age_minutes < 30,
        "age_minutes": round(age_minutes, 1),
        "path": str(context_file)
    }


def parse_transcript_for_todos(transcript_path: str) -> dict:
    """Parse transcript to find TODO state."""
    try:
        todos = []
        with open(transcript_path, 'r') as f:
            for line in f:
                try:
                    entry = json.loads(line)
                    # Look for TodoWrite tool calls in assistant messages
                    if entry.get("type") == "message":
                        message = entry.get("message", {})
                        content = message.get("content", [])
                        for block in content:
                            if block.get("type") == "tool_use" and block.get("name") == "TodoWrite":
                                input_data = block.get("input", {})
                                todos = input_data.get("todos", [])
                except json.JSONDecodeError:
                    continue

        # Return the last known TODO state
        incomplete = [t for t in todos if t.get("status") != "completed"]
        return {
            "has_todos": len(todos) > 0,
            "incomplete_count": len(incomplete),
            "incomplete": incomplete[:3]  # First 3 for context
        }
    except Exception as e:
        return {"has_todos": False, "error": str(e)}


def main():
    # Read input from stdin
    try:
        input_data = json.load(sys.stdin)
    except json.JSONDecodeError:
        # No input or invalid JSON - allow stop
        sys.exit(0)

    # CRITICAL: Check if we're already in a stop-hook continuation
    # This prevents infinite loops
    if input_data.get("stop_hook_active"):
        # Already blocked once, allow stop now
        sys.exit(0)

    project_dir = input_data.get("cwd", os.getcwd())
    transcript_path = input_data.get("transcript_path", "")

    # Collect blocking issues (impl files dirty) and warnings (non-impl dirty)
    blocking_issues = []
    warnings = []

    # Check 1: Uncommitted changes — categorized
    git_status = get_git_status()
    if git_status.get("has_changes"):
        impl_count = git_status.get("impl_count", 0)
        non_impl_count = git_status.get("non_impl_count", 0)
        categorized = git_status.get("categorized", {})

        if impl_count > 0:
            # Implementation files dirty — BLOCK
            impl_files = categorized.get('impl', [])[:5]
            blocking_issues.append(
                f"Uncommitted IMPLEMENTATION files ({impl_count}): {', '.join(impl_files)}"
            )

        # Handoff-only is silent (the agent just wrote it). All other non-impl is a warning.
        non_impl_non_handoff = (
            len(categorized.get('config', [])) +
            len(categorized.get('doc', [])) +
            len(categorized.get('other', []))
        )
        if non_impl_non_handoff > 0 and impl_count == 0:
            # Only docs/config dirty — warn but allow stop
            doc_files = (
                categorized.get('doc', []) +
                categorized.get('config', []) +
                categorized.get('other', [])
            )[:5]
            warnings.append(
                f"Uncommitted docs/config ({non_impl_non_handoff}): {', '.join(doc_files)}"
            )

    # Check 2: Incomplete TODOs (if transcript available) — these BLOCK
    if transcript_path and os.path.exists(transcript_path):
        todo_status = parse_transcript_for_todos(transcript_path)
        if todo_status.get("incomplete_count", 0) > 0:
            incomplete = todo_status.get("incomplete", [])
            names = [t.get("content", "?")[:40] for t in incomplete]
            blocking_issues.append(
                f"Incomplete TODOs ({todo_status['incomplete_count']}): {', '.join(names)}"
            )

    # Decision
    if blocking_issues:
        reason_parts = ["Before stopping, please address:"]
        reason_parts.extend(f"- {issue}" for issue in blocking_issues)
        if warnings:
            reason_parts.append("")
            reason_parts.append("Also noted (not blocking):")
            reason_parts.extend(f"- {w}" for w in warnings)
        output = {
            "decision": "block",
            "reason": "\n".join(reason_parts)
        }
        print(json.dumps(output))
        sys.exit(0)

    # No blocking issues — emit warnings to stderr (visible but not blocking)
    if warnings:
        for w in warnings:
            print(f"NOTE: {w}", file=sys.stderr)

    # Allow stop
    sys.exit(0)


if __name__ == "__main__":
    main()
