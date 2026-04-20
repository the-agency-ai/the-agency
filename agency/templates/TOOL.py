#!/usr/bin/env python3
"""
What Problem: {{TOOL_DESCRIPTION}}

How & Why: [Explain the approach and rationale]

Usage:
    ./claude/tools/{{TOOL_NAME}} [options] <args>

Python: 3.13+ (framework floor per D45). Stdlib only for framework tools
(ZERO-PIP CONSTRAINT). Services may use pip deps.

Shebang convention: `#!/usr/bin/env python3` + runtime `sys.version_info`
guard (not `python3.13`) — brew default is `python3`, pyenv/nix/conda
install as `python3`, and hard-coding the exact minor name breaks any
install that doesn't create the per-minor symlink. See
usr/jordan/captain/briefings/python-shebang-investigation-20260418.md.

Written: {{TOOL_DATE}} by {{TOOL_AUTHOR}}
"""

import sys

# ── Runtime floor guard (D45 — Python 3.13+) ─────────────────────────────────
if sys.version_info < (3, 13):
    sys.exit(
        f"Python 3.13+ required (got {sys.version_info.major}.{sys.version_info.minor}). "
        "See claude/config/dependencies.yaml."
    )

import argparse
import json
import os
import time
import uuid
from datetime import datetime, timezone
from pathlib import Path

# ── Tool metadata ────────────────────────────────────────────────────────────
TOOL_VERSION = "1.0.0-{{BUILD_NUMBER}}"
TOOL_NAME = "{{TOOL_NAME}}"

# ── Path resolution ──────────────────────────────────────────────────────────
SCRIPT_DIR = Path(__file__).resolve().parent
PROJECT_ROOT = SCRIPT_DIR.parent.parent
LOG_DIR = PROJECT_ROOT / ".claude" / "logs"
LOG_FILE = LOG_DIR / "tool-runs.jsonl"


# ── Telemetry ────────────────────────────────────────────────────────────────
# Structured JSONL logging to .claude/logs/tool-runs.jsonl.
# Same format as the bash _log-helper — interoperable.

def _uuid7() -> str:
    """Generate a UUID7 (time-ordered, globally unique)."""
    import struct
    t = int(time.time() * 1000)
    r = os.urandom(10)
    b = struct.pack(">Q", t)[-6:]
    b += bytes([0x70 | (r[0] & 0x0F)]) + r[1:2]
    b += bytes([0x80 | (r[2] & 0x3F)]) + r[3:10]
    h = b.hex()
    return f"{h[:8]}-{h[8:12]}-{h[12:16]}-{h[16:20]}-{h[20:32]}"


def _log_append(record: dict) -> None:
    """Append a JSON record to the telemetry log."""
    try:
        LOG_DIR.mkdir(parents=True, exist_ok=True)
        with open(LOG_FILE, "a") as f:
            f.write(json.dumps(record, separators=(",", ":")) + "\n")
    except OSError:
        pass  # Telemetry failure never blocks tool execution


def _get_branch() -> str:
    """Get current git branch (best-effort)."""
    try:
        import subprocess
        result = subprocess.run(
            ["git", "branch", "--show-current"],
            capture_output=True, text=True, timeout=5
        )
        return result.stdout.strip()
    except Exception:
        return ""


def log_start(tool_name: str, args: list[str]) -> str:
    """Start a telemetry run. Returns run_id."""
    run_id = _uuid7()
    ts = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")

    agency_name = PROJECT_ROOT.name
    agent_name = os.environ.get("CLAUDE_SESSION_NAME",
                                os.environ.get("AGENTNAME", "unknown"))
    principal = os.environ.get("AGENCY_PRINCIPAL",
                               os.environ.get("USER", "unknown"))

    _log_append({
        "run": run_id,
        "tool": tool_name,
        "event": "start",
        "ts": ts,
        "agency": agency_name,
        "principal": principal,
        "agent": agent_name,
        "session": os.environ.get("CLAUDE_SESSION_ID", ""),
        "branch": _get_branch(),
        "args": " ".join(args)[:200],
    })
    return run_id


def log_end(run_id: str, outcome: str, exit_code: int = 0,
            duration_ms: int = 0, summary: str = "") -> None:
    """End a telemetry run."""
    ts = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
    _log_append({
        "run": run_id,
        "event": "end",
        "ts": ts,
        "outcome": outcome,
        "exit": exit_code,
        "duration_ms": duration_ms,
        "summary": summary[:500],
    })


def log_detail(run_id: str, channel: str, content: str) -> None:
    """Log verbose detail (stdout capture, debug info, etc.)."""
    ts = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
    _log_append({
        "run": run_id,
        "event": "detail",
        "ts": ts,
        "channel": channel,
        "content": content[:5000],
    })


# ── Output helpers ───────────────────────────────────────────────────────────

class Output:
    """Context-efficient output. Details go to telemetry; stdout stays lean."""

    def __init__(self, run_id: str, verbose: bool = False):
        self.run_id = run_id
        self.verbose = verbose

    def info(self, msg: str) -> None:
        """Print to stderr when verbose; always log to telemetry."""
        if self.verbose:
            print(f"\033[0;32m[INFO]\033[0m {msg}", file=sys.stderr)
        if self.run_id:
            log_detail(self.run_id, "info", msg)

    def warn(self, msg: str) -> None:
        """Always print to stderr; log to telemetry."""
        print(f"\033[1;33m[WARN]\033[0m {msg}", file=sys.stderr)
        if self.run_id:
            log_detail(self.run_id, "warn", msg)

    def die(self, msg: str, code: int = 1) -> None:
        """Print error, log failure, exit."""
        print(f"\033[0;31mERROR:\033[0m {msg}", file=sys.stderr)
        if self.run_id:
            log_end(self.run_id, "failure", code, 0, msg)
        sys.exit(code)

    def result(self, tool_name: str, summary: str, icon: str = "done") -> None:
        """Print the standard 2-3 line tool output."""
        if self.run_id:
            run_short = self.run_id.split("-")[0]
            print(f"{tool_name} [run: {run_short}]")
        else:
            print(tool_name)
        if summary:
            print(summary)
        print(icon)


# ── Argument parsing ─────────────────────────────────────────────────────────

def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        prog=TOOL_NAME,
        description="{{TOOL_DESCRIPTION}}",
    )
    parser.add_argument(
        "--verbose", "-v",
        action="store_true",
        help="Show detailed output (default: log to telemetry DB)",
    )
    parser.add_argument(
        "--version",
        action="version",
        version=f"{TOOL_NAME} {TOOL_VERSION}",
    )
    # TODO: Add your arguments here
    # parser.add_argument("name", help="The name to process")
    # parser.add_argument("--output", "-o", help="Output path")

    return parser.parse_args()


# ── Main logic ───────────────────────────────────────────────────────────────

def main() -> None:
    args = parse_args()

    # Start telemetry
    run_id = log_start(TOOL_NAME, sys.argv[1:])
    out = Output(run_id, verbose=args.verbose)
    start_time = time.time()

    try:
        # --- Your tool logic here ---
        #
        # Use out.info/out.warn/out.die for output:
        #   out.info("Processing...")       # visible only with --verbose
        #   out.warn("File already exists") # always visible
        #   out.die("Cannot find config")   # prints error + exits
        #
        # Log details for post-mortem (always captured, never printed):
        #   log_detail(run_id, "stdout", captured_output)

        out.info(f"Starting {TOOL_NAME}")

        # TODO: Replace with your implementation

        out.info("Done")

        # --- End of tool logic ---

        # Success output
        duration_ms = int((time.time() - start_time) * 1000)
        log_end(run_id, "success", 0, duration_ms, f"{TOOL_NAME} completed")
        out.result(TOOL_NAME, f"{TOOL_NAME} completed")

    except SystemExit:
        raise  # Let die() exits propagate
    except Exception as exc:
        duration_ms = int((time.time() - start_time) * 1000)
        log_end(run_id, "failure", 1, duration_ms, str(exc))
        out.die(str(exc))


if __name__ == "__main__":
    main()
