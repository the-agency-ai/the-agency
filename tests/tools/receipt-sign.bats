#!/usr/bin/env bats
#
# receipt-sign tests
#

REPO_ROOT="$(cd "$(dirname "${BATS_TEST_DIRNAME}")/.." && pwd)"
RECEIPT_SIGN="${REPO_ROOT}/claude/tools/receipt-sign"

setup() {
    RECEIPTS_DIR=$(mktemp -d)
    # Override receipts dir by patching — tests write to temp
    export TEST_RECEIPTS_DIR="$RECEIPTS_DIR"
}

teardown() {
    rm -rf "$RECEIPTS_DIR"
}

COMMON_ARGS="--type qgr --boundary pr-prep --org test-org --principal jordan --agent captain --workstream agency --project test-proj --hash-a aaaa --hash-b bbbb --hash-c cccc --hash-d dddd --hash-e eeee"

@test "receipt-sign: missing required args fails" {
    run bash "$RECEIPT_SIGN" --type qgr
    [ "$status" -eq 1 ]
    [[ "$output" == *"missing required"* ]]
}

@test "receipt-sign: invalid type fails" {
    run bash "$RECEIPT_SIGN" $COMMON_ARGS --type invalid
    # Will fail on type validation since we override
    [ "$status" -eq 1 ] || [[ "$output" == *"must be"* ]]
}

@test "receipt-sign: valid args produces receipt" {
    run bash "$RECEIPT_SIGN" $COMMON_ARGS
    [ "$status" -eq 0 ]
    [[ "$output" == *"Receipt written"* ]]
}

@test "receipt-sign: receipt contains version 1 — D42-R3 per-workstream path" {
    bash "$RECEIPT_SIGN" $COMMON_ARGS
    local receipt
    # D42-R3: receipts now write to claude/workstreams/{W}/qgr/ or rgr/
    receipt=$(ls "${REPO_ROOT}/claude/workstreams/agency/qgr/"*test-proj* 2>/dev/null | head -1)
    [ -n "$receipt" ]
    grep -q "receipt_version: 1" "$receipt"
    # Cleanup
    rm -f "$receipt"
}

@test "receipt-sign: auto-approve when hash-d equals hash-c — D42-R3 per-workstream path" {
    bash "$RECEIPT_SIGN" --type qgr --boundary iteration-complete --org test-org --principal jordan --agent devex --workstream devex --project test-auto --hash-a aaaa --hash-b bbbb --hash-c cccc --hash-d cccc --hash-e eeee
    local receipt
    # D42-R3: receipts write to per-workstream path
    receipt=$(ls "${REPO_ROOT}/claude/workstreams/devex/qgr/"*test-auto* 2>/dev/null | head -1)
    [ -n "$receipt" ]
    grep -q "auto-approved" "$receipt"
    rm -f "$receipt"
}

@test "receipt-sign: --help shows usage" {
    run bash "$RECEIPT_SIGN" --help
    [ "$status" -eq 0 ]
    [[ "$output" == *"Usage"* ]]
}
