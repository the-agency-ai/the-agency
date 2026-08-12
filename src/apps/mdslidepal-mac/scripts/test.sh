#!/usr/bin/env bash
# What Problem: `swift test` runs zero tests in this package and exits 0.
# MdSlidepalTests is an .executableTarget with a hand-rolled runner (XCTest is
# unavailable on a CommandLineTools-only toolchain, and the package declares no
# .testTarget), so the standard command builds it, finds no test target, and
# reports success. Nothing in the repo invoked the real runner: every pass count
# this suite has ever produced was typed by hand.
#
# How & Why: One checked-in entry point that builds and runs the actual runner
# and propagates its exit code, so CI, a pre-push hook, or a human all get the
# same answer from the same command. DEVELOPER_DIR is set because the
# HighlightSwift dependency uses SwiftUI's @Entry macro, whose SwiftUIMacros
# plugin ships only in the full Xcode SDK — with CommandLineTools alone the build
# fails to compile rather than failing a test.
#
# Usage:
#   ./scripts/test.sh              # build + run the suite
#   DEVELOPER_DIR=... ./scripts/test.sh   # override the toolchain
#
# Written: 2026-08-12 — closes the "nothing ever ran the tests" gap.

set -euo pipefail

# Repo-relative, so the script works from any working directory.
PACKAGE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Respect an explicit DEVELOPER_DIR; otherwise point at the full Xcode SDK.
: "${DEVELOPER_DIR:=/Applications/Xcode.app/Contents/Developer}"
export DEVELOPER_DIR

if [ ! -d "$DEVELOPER_DIR" ]; then
    echo "error: DEVELOPER_DIR does not exist: $DEVELOPER_DIR" >&2
    echo "       A full Xcode install is required (SwiftUIMacros is not in CommandLineTools)." >&2
    exit 1
fi

cd "$PACKAGE_DIR"

echo "==> swift build  (DEVELOPER_DIR=$DEVELOPER_DIR)"
swift build

echo "==> swift run MdSlidepalTests"
# The runner exits non-zero when any test fails; `set -e` propagates it, and the
# explicit exit keeps that true if this script ever grows a trailing command.
swift run MdSlidepalTests
exit $?
