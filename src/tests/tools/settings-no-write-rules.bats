#!/usr/bin/env bats
#
# Guard: no Write(path) permission rules in shipped or live settings.
#
# Claude Code's file permission checks match only Edit(path) rules — they
# cover every file-editing tool, Write included. A Write(path) rule is dead
# config: Claude Code ignores it and warns on startup ("not matched by file
# permission checks — only Edit(path) rules are"). This test stops such
# rules creeping back into the settings we ship or the docs that show
# adopters what to paste.
#

load 'test_helper'

# Settings files whose permissions arrays must contain no Write(...) rules.
SETTINGS_FILES=(
    ".claude/settings.json"
    "agency/config/settings-template.json"
    "src/claude/settings.json"
    "src/agency/config/settings-template.json"
)

# Docs that show adopters settings snippets.
DOC_FILES=(
    "agency/README-GETTINGSTARTED.md"
    "agency/README/README-ENFORCEMENT.md"
    "src/agency/README-GETTINGSTARTED.md"
    "src/agency/README/README-ENFORCEMENT.md"
)

# Print every Write(...) entry in a settings file's permissions arrays.
write_rules_in() {
    python3 - "$1" <<'PY'
import json, sys
with open(sys.argv[1]) as f:
    data = json.load(f)
perms = data.get("permissions", {})
for key in ("allow", "deny", "ask"):
    for rule in perms.get(key, []) or []:
        if isinstance(rule, str) and rule.startswith("Write("):
            print(f"{key}: {rule}")
PY
}

@test "settings: no Write(path) permission rules in settings files" {
    local offenders=""
    for f in "${SETTINGS_FILES[@]}"; do
        assert_file_exists "${REPO_ROOT}/${f}"
        local hits
        hits="$(write_rules_in "${REPO_ROOT}/${f}")"
        [[ -n "$hits" ]] && offenders+="${f}:"$'\n'"${hits}"$'\n'
    done
    if [[ -n "$offenders" ]]; then
        echo "Write(path) rules are ignored by Claude Code — use Edit(path):"
        echo "$offenders"
        return 1
    fi
}

@test "settings: no Write(path) rules in adopter-facing docs" {
    local offenders=""
    for f in "${DOC_FILES[@]}"; do
        assert_file_exists "${REPO_ROOT}/${f}"
        local hits
        hits="$(grep -n '"Write(' "${REPO_ROOT}/${f}" || true)"
        [[ -n "$hits" ]] && offenders+="${f}:"$'\n'"${hits}"$'\n'
    done
    if [[ -n "$offenders" ]]; then
        echo "Docs show Write(path) rules — use Edit(path):"
        echo "$offenders"
        return 1
    fi
}

# src/ is the shipped payload and must mirror the live tree. A permission fix
# applied to one side only regresses through the other.
@test "settings: permissions match between live settings and src mirrors" {
    local pairs=(
        ".claude/settings.json:src/claude/settings.json"
        "agency/config/settings-template.json:src/agency/config/settings-template.json"
    )
    local drift=""
    for pair in "${pairs[@]}"; do
        local live="${pair%%:*}" mirror="${pair##*:}"
        local d
        d="$(python3 - "${REPO_ROOT}/${live}" "${REPO_ROOT}/${mirror}" <<'PY'
import json, sys
a = json.load(open(sys.argv[1])).get("permissions", {})
b = json.load(open(sys.argv[2])).get("permissions", {})
if a != b:
    for key in sorted(set(a) | set(b)):
        x, y = a.get(key), b.get(key)
        if x == y:
            continue
        if isinstance(x, list) and isinstance(y, list):
            for r in x:
                if r not in y: print(f"  {key}: live-only {r}")
            for r in y:
                if r not in x: print(f"  {key}: mirror-only {r}")
            if sorted(x) == sorted(y): print(f"  {key}: same rules, different order")
        else:
            print(f"  {key}: {x!r} != {y!r}")
PY
)"
        [[ -n "$d" ]] && drift+="${live} vs ${mirror}:"$'\n'"${d}"$'\n'
    done
    if [[ -n "$drift" ]]; then
        echo "Permission drift between live settings and src mirror:"
        echo "$drift"
        return 1
    fi
}

@test "settings: detector catches a Write(path) rule (self-check)" {
    local tmp
    tmp="$(mktemp -d)"
    printf '%s\n' '{"permissions":{"allow":["Edit(**)","Write(**)"],"deny":["Write(/tmp/**)"]}}' > "${tmp}/s.json"
    run write_rules_in "${tmp}/s.json"
    rm -rf "${tmp}"
    [[ "$status" -eq 0 ]]
    [[ "$output" == *"allow: Write(**)"* ]]
    [[ "$output" == *"deny: Write(/tmp/**)"* ]]
    [[ "$output" != *"Edit("* ]]
}
