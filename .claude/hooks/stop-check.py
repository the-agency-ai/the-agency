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
    "claude/data/messages.db",      # Tool run logs database
    "claude/data/*.db",             # Any database in data dir
    "history/push-log.md",          # Push accountability log
    "*.pyc",                        # Python bytecode
    "__pycache__/*",                # Python cache
]


def should_exclude(filepath: str) -> bool:
    """Check if a file should be excluded from uncommitted changes check."""
    import fnmatch
    # Strip git status prefix (e.g., " M ", "?? ", etc.)
    clean_path = filepath.strip()
    if len(clean_path) >= 3 and clean_path[1] == ' ':
        clean_path = clean_path[2:].strip()
    elif len(clean_path) >= 2 and clean_path[0] in 'MADRCU?' and clean_path[1] == ' ':
        clean_path = clean_path[2:].strip()

    for pattern in EXCLUDE_PATTERNS:
        if fnmatch.fnmatch(clean_path, pattern):
            return True
    return False


def get_git_status() -> dict:
    """Check for uncommitted changes."""
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

        return {
            "has_changes": len(significant_changes) > 0,
            "change_count": len(significant_changes),
            "changes": significant_changes[:5]  # First 5 for context
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

    # Collect checks
    issues = []

    # Check 1: Uncommitted changes
    git_status = get_git_status()
    if git_status.get("has_changes"):
        changes = git_status.get("changes", [])
        issues.append(f"Uncommitted changes ({git_status['change_count']} files): {', '.join(changes[:3])}")

    # Check 2: Incomplete TODOs (if transcript available)
    if transcript_path and os.path.exists(transcript_path):
        todo_status = parse_transcript_for_todos(transcript_path)
        if todo_status.get("incomplete_count", 0) > 0:
            incomplete = todo_status.get("incomplete", [])
            names = [t.get("content", "?")[:40] for t in incomplete]
            issues.append(f"Incomplete TODOs ({todo_status['incomplete_count']}): {', '.join(names)}")

    # Check 3: Context saved (optional - comment out if too aggressive)
    # context_status = check_context_saved(project_dir)
    # if not context_status.get("saved"):
    #     issues.append("Session context not saved recently")

    # Decision
    if issues:
        output = {
            "decision": "block",
            "reason": "Before stopping, please address:\n- " + "\n- ".join(issues)
        }
        print(json.dumps(output))
        sys.exit(0)

    # All checks passed - allow stop
    sys.exit(0)


if __name__ == "__main__":
    main()
