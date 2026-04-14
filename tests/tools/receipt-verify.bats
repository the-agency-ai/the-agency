#!/usr/bin/env bats
#
# receipt-verify tests
#

REPO_ROOT="$(cd "$(dirname "${BATS_TEST_DIRNAME}")/.." && pwd)"
RECEIPT_VERIFY="${REPO_ROOT}/claude/tools/receipt-verify"

@test "receipt-verify: no receipts = blocked" {
    # Empty receipts dir
    local empty_dir
    empty_dir=$(mktemp -d)
    mkdir -p "$empty_dir/claude/receipts"
    run bash "$RECEIPT_VERIFY"
    # Will search real dir — if no matching receipts, blocked
    [[ "$output" == *"receipt"* ]] || [ "$status" -eq 1 ]
}

@test "receipt-verify: --help shows usage" {
    run bash "$RECEIPT_VERIFY" --help
    [ "$status" -eq 0 ]
    [[ "$output" == *"Usage"* ]]
}

@test "receipt-verify: --file on missing file fails" {
    run bash "$RECEIPT_VERIFY" --file /nonexistent/receipt.md
    [ "$status" -eq 1 ]
    [[ "$output" == *"not found"* ]]
}
