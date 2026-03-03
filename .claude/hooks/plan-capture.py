#!/usr/bin/env python3
"""
TaskCompleted hook - captures plan artifacts when a planning session completes.

When permission_mode is "plan", this hook:
1. Reads the plan content from the transcript
2. Detects any REQUEST-xxx references that drove the planning
3. Creates a PLAN-XXXX artifact in claude/plans/
4. Feeds back the plan ID to Claude

Input (stdin): JSON with session_id, transcript_path, permission_mode, task_subject, etc.
Exit codes:
  0 - Success (stdout shown to Claude as feedback)
  2 - Block (stderr shown to Claude as error)
"""

import json
import os
import re
import sys
import time
from datetime import date
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


def extract_request_ids(text: str) -> list[str]:
    """Extract REQUEST-xxx-NNNN identifiers from text."""
    return list(set(re.findall(r'REQUEST-\w+-\d{4}', text)))


def extract_from_transcript(transcript_path: str) -> dict:
    """
    Extract plan content, prompt context, and request references from transcript.
    Returns dict with keys: plan_content, prompt_context, request_ids.
    """
    result = {
        "plan_content": "",
        "prompt_context": "",
        "request_ids": [],
    }

    try:
        with open(transcript_path, 'r') as f:
            lines = f.readlines()

        user_prompts = []
        plan_file_content = None
        all_text = []  # Accumulate all text for REQUEST scanning

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
                    all_text.append(content)
                    if not content.startswith("<system-reminder>"):
                        user_prompts.append(content.strip())
                elif isinstance(content, list):
                    for block in content:
                        if isinstance(block, dict) and block.get("type") == "text":
                            text = block.get("text", "").strip()
                            all_text.append(text)
                            if text and not text.startswith("<system-reminder>"):
                                user_prompts.append(text)

            # Collect assistant text for REQUEST scanning + plan file detection
            if entry.get("role") == "assistant":
                content = entry.get("content", [])
                if isinstance(content, str):
                    all_text.append(content)
                elif isinstance(content, list):
                    for block in content:
                        if isinstance(block, dict):
                            if block.get("type") == "text":
                                all_text.append(block.get("text", ""))
                            elif block.get("type") == "tool_use":
                                tool_input = block.get("input", {})
                                # Check for Write to plan file
                                if block.get("name") == "Write":
                                    file_path = tool_input.get("file_path", "")
                                    if "/plans/" in file_path or "plan" in file_path.lower():
                                        plan_file_content = tool_input.get("content", "")

        # Build prompt context from first few user prompts
        if user_prompts:
            result["prompt_context"] = user_prompts[0]
            if len(user_prompts) > 1:
                for p in user_prompts[1:4]:
                    if len(p) < 500:
                        result["prompt_context"] += f"\n> {p}"

        # Use plan file if agent already wrote one
        if plan_file_content:
            result["plan_content"] = plan_file_content

        # Scan all text for REQUEST references
        combined = "\n".join(all_text)
        result["request_ids"] = extract_request_ids(combined)

    except Exception as e:
        sys.stderr.write(f"Warning: Could not parse transcript: {e}\n")

    return result


def find_active_request(project_dir: str) -> str | None:
    """
    Check for an active REQUEST in the current session context.
    Looks at context-save files and recent request status.
    """
    # Check session context for REQUEST references
    context_file = Path(project_dir) / "claude" / "data" / "session-context.md"
    if context_file.exists():
        content = context_file.read_text()
        ids = extract_request_ids(content)
        if ids:
            return ids[0]  # Most recent/prominent

    return None


def main():
    try:
        hook_input = json.loads(sys.stdin.read())
    except json.JSONDecodeError:
        sys.exit(0)

    permission_mode = hook_input.get("permission_mode", "")
    task_subject = hook_input.get("task_subject", "")
    task_description = hook_input.get("task_description", "")
    transcript_path = hook_input.get("transcript_path", "")
    cwd = hook_input.get("cwd", os.getcwd())

    # Only act on plan mode completions
    if permission_mode != "plan":
        sys.exit(0)

    project_dir = os.environ.get("CLAUDE_PROJECT_DIR", cwd)
    plans_dir = Path(project_dir) / "claude" / "plans"
    plans_dir.mkdir(parents=True, exist_ok=True)

    # Check if a plan was already captured recently (agent did it manually)
    recent_plans = []
    for f in plans_dir.glob("PLAN-*.md"):
        if time.time() - f.stat().st_mtime < 120:
            recent_plans.append(f.name)

    if recent_plans:
        plan_id = recent_plans[-1].replace('.md', '')
        print(f"Plan already captured as {plan_id}")
        sys.exit(0)

    # Extract from transcript
    extracted = extract_from_transcript(transcript_path)

    if not extracted["plan_content"] and not task_subject:
        sys.exit(0)

    # Collect REQUEST references from all sources
    request_ids = set(extracted["request_ids"])

    # Also check task subject/description for REQUEST references
    if task_subject:
        request_ids.update(extract_request_ids(task_subject))
    if task_description:
        request_ids.update(extract_request_ids(task_description))

    # Also check session context
    ctx_request = find_active_request(project_dir)
    if ctx_request:
        request_ids.add(ctx_request)

    # Format the Related field
    request_ids_sorted = sorted(request_ids)
    if request_ids_sorted:
        related_field = ", ".join(request_ids_sorted)
    else:
        related_field = "N/A"

    # Generate plan artifact
    plan_num = get_next_plan_number(plans_dir)
    plan_id = f"PLAN-{plan_num:04d}"
    slug = slugify(task_subject) if task_subject else "untitled"
    filename = f"{plan_id}-{slug}.md"
    today = date.today().isoformat()

    # Build the plan file
    if extracted["plan_content"] and extracted["plan_content"].startswith("# Plan:"):
        # Plan was already formatted — inject Related if missing
        artifact_content = extracted["plan_content"]
        if "**Related:**" in artifact_content and "N/A" in artifact_content and request_ids_sorted:
            artifact_content = artifact_content.replace(
                "**Related:** N/A",
                f"**Related:** {related_field}"
            )
    else:
        prompt_section = (
            f"> {extracted['prompt_context']}"
            if extracted["prompt_context"]
            else "> (captured from plan mode session)"
        )

        artifact_content = f"""# Plan: {task_subject or 'Untitled Plan'}

**Plan ID:** {plan_id}
**Date:** {today}
**Agent:** captain
**Principal:** jordan
**Status:** Draft
**Related:** {related_field}

## Prompt Context
{prompt_section}

## Plan
{extracted["plan_content"] or '(Plan content not captured — check transcript)'}

## Outcome
(pending implementation)
"""

    plan_path = plans_dir / filename
    plan_path.write_text(artifact_content)

    # Feed back to Claude
    related_msg = f" (related: {related_field})" if request_ids_sorted else ""
    print(f"plan-capture: saved {plan_id} → claude/plans/{filename}{related_msg}")
    sys.exit(0)


if __name__ == "__main__":
    main()
