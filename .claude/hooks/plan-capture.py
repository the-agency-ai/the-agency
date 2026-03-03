#!/usr/bin/env python3
"""
TaskCompleted hook - captures plan artifacts when a planning session completes.

When permission_mode is "plan", this hook:
1. Reads the plan file from the transcript
2. Creates a PLAN-XXXX artifact in claude/plans/
3. Feeds back the plan ID to Claude

Input (stdin): JSON with session_id, transcript_path, permission_mode, task_subject, etc.
Exit codes:
  0 - Success (stdout shown to Claude as feedback)
  2 - Block (stderr shown to Claude as error)
"""

import json
import os
import re
import sys
from pathlib import Path


def get_next_plan_number(plans_dir: Path) -> int:
    """Get next sequential plan number."""
    existing = list(plans_dir.glob("PLAN-*.md"))
    if not existing:
        return 1
    numbers = []
    for f in existing:
        match = re.match(r"PLAN-(\d+)", f.name)
        if match:
            numbers.append(int(match.group(1)))
    return max(numbers) + 1 if numbers else 1


def slugify(text: str) -> str:
    """Convert text to a URL-friendly slug."""
    text = text.lower().strip()
    text = re.sub(r'[^\w\s-]', '', text)
    text = re.sub(r'[-\s]+', '-', text)
    return text[:50].rstrip('-')


def extract_plan_from_transcript(transcript_path: str) -> tuple[str, str]:
    """
    Extract the plan content and prompt context from the transcript.
    Returns (plan_content, prompt_context).
    """
    plan_content = ""
    prompt_context = ""

    try:
        with open(transcript_path, 'r') as f:
            lines = f.readlines()

        # Parse JSONL - look for the plan file content and user prompts
        user_prompts = []
        plan_file_path = None
        plan_file_content = None

        for line in lines:
            line = line.strip()
            if not line:
                continue
            try:
                entry = json.loads(line)
            except json.JSONDecodeError:
                continue

            # Collect user messages as prompt context
            if entry.get("role") == "user":
                content = entry.get("content", "")
                if isinstance(content, str) and content.strip():
                    # Skip system reminders
                    if not content.startswith("<system-reminder>"):
                        user_prompts.append(content.strip())
                elif isinstance(content, list):
                    for block in content:
                        if isinstance(block, dict) and block.get("type") == "text":
                            text = block.get("text", "").strip()
                            if text and not text.startswith("<system-reminder>"):
                                user_prompts.append(text)

            # Look for Write tool calls that wrote to a plan file
            if entry.get("role") == "assistant":
                content = entry.get("content", [])
                if isinstance(content, list):
                    for block in content:
                        if isinstance(block, dict) and block.get("type") == "tool_use":
                            tool_input = block.get("input", {})
                            if block.get("name") == "Write":
                                file_path = tool_input.get("file_path", "")
                                if "/plans/" in file_path or "plan" in file_path.lower():
                                    plan_file_path = file_path
                                    plan_file_content = tool_input.get("content", "")

        # Use the first few user prompts as context
        if user_prompts:
            prompt_context = user_prompts[0]
            if len(user_prompts) > 1:
                # Include follow-up prompts that shaped the plan
                for p in user_prompts[1:4]:
                    if len(p) < 500:  # Skip very long messages
                        prompt_context += f"\n> {p}"

        # If a plan file was already written, use that content
        if plan_file_content:
            plan_content = plan_file_content

    except Exception as e:
        sys.stderr.write(f"Warning: Could not parse transcript: {e}\n")

    return plan_content, prompt_context


def main():
    # Read hook input from stdin
    try:
        hook_input = json.loads(sys.stdin.read())
    except json.JSONDecodeError:
        sys.exit(0)  # Non-blocking: can't parse input

    permission_mode = hook_input.get("permission_mode", "")
    task_subject = hook_input.get("task_subject", "")
    transcript_path = hook_input.get("transcript_path", "")
    cwd = hook_input.get("cwd", os.getcwd())

    # Only act on plan mode completions
    if permission_mode != "plan":
        sys.exit(0)

    # Find project root
    project_dir = os.environ.get("CLAUDE_PROJECT_DIR", cwd)
    plans_dir = Path(project_dir) / "claude" / "plans"
    plans_dir.mkdir(parents=True, exist_ok=True)

    # Check if a plan was already captured (agent may have done it manually)
    # by looking for a plan file written in the last minute
    import time
    recent_plans = []
    for f in plans_dir.glob("PLAN-*.md"):
        if time.time() - f.stat().st_mtime < 120:  # Within last 2 minutes
            recent_plans.append(f.name)

    if recent_plans:
        # Plan already captured by the agent - no action needed
        plan_id = recent_plans[-1].replace('.md', '')
        print(f"Plan already captured as {plan_id}")
        sys.exit(0)

    # Extract plan from transcript
    plan_content, prompt_context = extract_plan_from_transcript(transcript_path)

    if not plan_content and not task_subject:
        # Nothing to capture
        sys.exit(0)

    # Generate plan artifact
    plan_num = get_next_plan_number(plans_dir)
    plan_id = f"PLAN-{plan_num:04d}"
    slug = slugify(task_subject) if task_subject else "untitled"
    filename = f"{plan_id}-{slug}.md"

    from datetime import date
    today = date.today().isoformat()

    # Build the plan file
    if plan_content and plan_content.startswith("# Plan:"):
        # Plan was already formatted - just ensure metadata is present
        artifact_content = plan_content
    else:
        # Build from scratch
        prompt_section = f"> {prompt_context}" if prompt_context else "> (captured from plan mode session)"

        artifact_content = f"""# Plan: {task_subject or 'Untitled Plan'}

**Plan ID:** {plan_id}
**Date:** {today}
**Agent:** captain
**Principal:** jordan
**Status:** Draft
**Related:** N/A

## Prompt Context
{prompt_section}

## Plan
{plan_content or '(Plan content not captured - check transcript)'}

## Outcome
(pending implementation)
"""

    plan_path = plans_dir / filename
    plan_path.write_text(artifact_content)

    # Feed back to Claude
    print(f"plan-capture: saved {plan_id} → claude/plans/{filename}")
    sys.exit(0)


if __name__ == "__main__":
    main()
