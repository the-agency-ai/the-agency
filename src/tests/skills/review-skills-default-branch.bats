#!/usr/bin/env bats
#
# What Problem: the review skills hardcoded the default branch — quality-gate
# and REFERENCE-QUALITY-GATE said origin/main, pr-prep and code-review said
# origin/master. Each is wrong in some repo: an adopter on master got a QG
# diffed against a ref that doesn't exist, and code-review here (default
# branch main) diffed against origin/master (flag #41). Separately, the QG
# skill forced the reviewer-scorer onto haiku while its registration and
# class disagreed (haiku vs sonnet) — the scorer decides which findings get
# fixed, so a weak or inconsistent scorer silently drops real ones.
#
# How & Why: the skills must resolve the default branch at runtime via
# agency/tools/resolve-default-branch, and must not override the scorer's
# model; the registration and class definition must agree on it.
#

load '../tools/test_helper'

REVIEW_DOCS=(
    ".claude/skills/quality-gate/SKILL.md"
    ".claude/skills/pr-prep/SKILL.md"
    ".claude/skills/code-review/SKILL.md"
    "agency/REFERENCE/REFERENCE-QUALITY-GATE.md"
    "src/claude/skills/quality-gate/SKILL.md"
    "src/claude/skills/pr-prep/SKILL.md"
    "src/claude/skills/code-review/SKILL.md"
    "src/agency/REFERENCE/REFERENCE-QUALITY-GATE.md"
)

model_of() {
    awk '/^---$/{n++; next} n==1 && /^model:/{print $2; exit}' "$1"
}

@test "review skills: no hardcoded origin/main or origin/master" {
    local hits=""
    for f in "${REVIEW_DOCS[@]}"; do
        assert_file_exists "${REPO_ROOT}/${f}"
        local h
        h="$(grep -n -E 'origin/(main|master)\b' "${REPO_ROOT}/${f}" || true)"
        [[ -n "$h" ]] && hits+="${f}:"$'\n'"${h}"$'\n'
    done
    if [[ -n "$hits" ]]; then
        echo "Hardcoded default branch — use origin/<default> via resolve-default-branch:"
        echo "$hits"
        return 1
    fi
}

@test "review skills: quality-gate resolves the default branch at runtime" {
    grep -q 'resolve-default-branch' "${REPO_ROOT}/.claude/skills/quality-gate/SKILL.md"
    grep -q 'resolve-default-branch' "${REPO_ROOT}/.claude/skills/code-review/SKILL.md"
}

@test "review skills: QG and code-review do not override the scorer's model" {
    for f in .claude/skills/quality-gate/SKILL.md .claude/skills/code-review/SKILL.md; do
        if grep -n -E 'reviewer-scorer[^.]*model: *(haiku|sonnet|opus)' "${REPO_ROOT}/${f}"; then
            echo "${f} overrides the reviewer-scorer model"
            return 1
        fi
    done
}

@test "reviewer-scorer: registration and class agree on the model, and it is not haiku" {
    local reg cls
    reg="$(model_of "${REPO_ROOT}/.claude/agents/jordan/reviewer-scorer.md")"
    cls="$(model_of "${REPO_ROOT}/agency/agents/reviewer-scorer/agent.md")"
    [[ -n "$reg" && -n "$cls" ]] || { echo "missing model: reg=[$reg] class=[$cls]"; return 1; }
    [[ "$reg" == "$cls" ]] || { echo "registration=$reg class=$cls"; return 1; }
    [[ "$reg" != "haiku" ]] || { echo "scorer is on haiku"; return 1; }
}
