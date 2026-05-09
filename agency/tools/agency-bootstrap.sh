#!/bin/bash
#
# agency-bootstrap.sh — One-liner bootstrap for bare repos.
#
# What Problem: `agency init` requires `./agency/tools/agency` to already
# exist in the target repo (chicken-and-egg). A truly bare repo can't run
# `agency init --from-github` because the tool itself isn't present yet.
# Adopters had to do a two-step dance: `git clone --depth 1 the-agency /tmp/...`
# then `AGENCY_SOURCE=/tmp/... /tmp/.../agency/tools/agency init`. Brittle,
# easy to get wrong, and not copy-pasteable in a chat or doc.
#
# How & Why: This script is meant to be fetched via curl and piped to bash.
# It shallow-clones the-agency to a temp dir, then execs `agency init
# --from-github` from that temp dir. Any args passed through to the final
# agency invocation. Temp dir is cleaned up on exit (success or failure).
#
# Written: 2026-04-15 during D41-R24 — principal directive "it can be a curl".
#
# Usage:
#   # From anywhere (curl one-liner):
#   curl -sL https://raw.githubusercontent.com/the-agency-ai/the-agency/main/agency/tools/agency-bootstrap.sh | bash
#
#   # With args (pass extras after --):
#   #   Replace YOUR_NAME and YOUR_PROJECT with your own values — these are
#   #   placeholders, not real examples to copy-paste (issue #286).
#   curl -sL https://.../agency-bootstrap.sh | bash -s -- --principal YOUR_NAME --project YOUR_PROJECT
#
#   # Local (from a cloned copy of the-agency):
#   ./agency/tools/agency-bootstrap.sh

set -euo pipefail

TOOL_VERSION="1.0.0"
GITHUB_REPO_URL="${GITHUB_REPO_URL:-https://github.com/the-agency-ai/the-agency.git}"

# Handle --help / --version before cloning
for arg in "$@"; do
    case "$arg" in
        --help|-h)
            cat <<'USAGE'
agency-bootstrap.sh — One-liner bootstrap for bare repos

Usage:
  curl -sL https://raw.githubusercontent.com/the-agency-ai/the-agency/main/agency/tools/agency-bootstrap.sh | bash
  curl -sL .../agency-bootstrap.sh | bash -s -- --principal YOUR_NAME --project YOUR_PROJECT
  ./agency/tools/agency-bootstrap.sh [agency init args...]

  (YOUR_NAME and YOUR_PROJECT are placeholders — substitute your own values.)

Accepts all flags that `agency init --from-github` accepts. The --from-github
flag is added automatically (you don't need to pass it).
USAGE
            exit 0
            ;;
        --version)
            echo "agency-bootstrap.sh $TOOL_VERSION"
            exit 0
            ;;
    esac
done

# Must be inside a git repo (agency init requires .git/)
if ! git rev-parse --git-dir >/dev/null 2>&1; then
    echo "Error: agency-bootstrap.sh must be run inside a git repo." >&2
    echo "Run 'git init' first, then re-run this bootstrap." >&2
    exit 1
fi

# Shallow-clone the-agency to a temp dir
TMP=$(mktemp -d -t agency-bootstrap-XXXXXX)
trap 'rm -rf "$TMP"' EXIT

echo "Fetching the-agency (shallow clone)..."
if ! git clone --depth 1 "$GITHUB_REPO_URL" "$TMP" >/dev/null 2>&1; then
    echo "Error: git clone failed for $GITHUB_REPO_URL" >&2
    exit 1
fi

# Exec agency init --from-github. We pass --from-github so the freshly-cloned
# temp dir is used as the authoritative source (consistent with how adopters
# run agency init thereafter).
echo "Running agency init --from-github in $(pwd) ..."
exec "$TMP/agency/tools/agency" init --from-github "$@"
