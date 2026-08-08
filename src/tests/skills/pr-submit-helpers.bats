#!/usr/bin/env bats
#
# pr-submit helper tests — regression cover for the three defects that blocked
# /pr-submit for every agent in a repo whose default branch is named `main`.
#
#   F1  The receipt-matching diff hash was computed against a literal
#       origin/master. In a `main` repo diff-hash exits non-zero, the hash
#       comes back empty, and the agent is told only "could not compute diff
#       hash" — nothing points at the ref name as the cause.
#   F2  A remote of the form https://<token>@github.com/org/repo.git did not
#       match the ORG parser, AND the failure path echoed the raw remote,
#       leaking the credential into the terminal, logs, and transcripts.
#   F3  The https branch used "([^/.]+?)(\.git)?/?$". Bash uses POSIX ERE,
#       which has no lazy quantifier, so "+?" never meant what it looks like
#       and the branch matched no .git-suffixed https remote at all.
#
# The helpers are sourced with PR_SUBMIT_LIB_ONLY=1, which returns before any
# precondition runs — so these are true unit tests: no git repo, no pushed
# branch, no signed receipt required.

REPO_ROOT="$(cd "$(dirname "${BATS_TEST_DIRNAME}")/../.." && pwd)"
PR_SUBMIT="${REPO_ROOT}/.claude/skills/pr-submit/scripts/pr-submit"

setup() {
    PR_SUBMIT_LIB_ONLY=1 source "$PR_SUBMIT"
}

# ─────────────────────────────────────────────────────────────────────────────
# Script shape
# ─────────────────────────────────────────────────────────────────────────────

@test "pr-submit: script exists and is executable" {
    [ -x "$PR_SUBMIT" ]
}

@test "pr-submit: script is syntactically valid" {
    bash -n "$PR_SUBMIT"
}

@test "pr-submit: lib-only source defines the helpers and runs nothing else" {
    run bash -c "PR_SUBMIT_LIB_ONLY=1 source '$PR_SUBMIT' && declare -F parse_org_from_remote resolve_default_branch redact_remote_url"
    [ "$status" -eq 0 ]
}

# ─────────────────────────────────────────────────────────────────────────────
# F2 — credential redaction
# ─────────────────────────────────────────────────────────────────────────────

@test "redact_remote_url: strips a PAT from an https remote" {
    result="$(redact_remote_url 'https://ghp_SECRETTOKEN@github.com/the-agency-ai/the-agency.git')"
    [ "$result" = "https://github.com/the-agency-ai/the-agency.git" ]
}

@test "redact_remote_url: strips user:password userinfo" {
    result="$(redact_remote_url 'https://user:hunter2@github.com/org/repo.git')"
    [ "$result" = "https://github.com/org/repo.git" ]
}

@test "redact_remote_url: leaves a credential-free https remote alone" {
    result="$(redact_remote_url 'https://github.com/org/repo.git')"
    [ "$result" = "https://github.com/org/repo.git" ]
}

@test "redact_remote_url: leaves an scp-style remote alone" {
    result="$(redact_remote_url 'git@github.com:org/repo.git')"
    [ "$result" = "git@github.com:org/repo.git" ]
}

@test "redact_remote_url: output never contains the token" {
    result="$(redact_remote_url 'https://ghp_SECRETTOKEN@github.com/org/repo.git')"
    [[ "$result" != *"ghp_SECRETTOKEN"* ]]
}

# QG finding: the first version of this function anchored on a literal
# "https://" prefix, so every other scheme went through completely
# unredacted and still leaked via the parse-failure message.

@test "redact_remote_url: strips credentials from an ssh:// remote" {
    result="$(redact_remote_url 'ssh://x-access-token:ghs_SECRET@git.example.com/org/repo.git')"
    [[ "$result" != *"ghs_SECRET"* ]]
    [ "$result" = "ssh://git.example.com/org/repo.git" ]
}

@test "redact_remote_url: strips credentials from an http:// remote" {
    result="$(redact_remote_url 'http://ghp_SECRETTOKEN@gitea.internal/org/repo.git')"
    [[ "$result" != *"ghp_SECRETTOKEN"* ]]
    [ "$result" = "http://gitea.internal/org/repo.git" ]
}

@test "redact_remote_url: strips credentials from a git:// remote" {
    result="$(redact_remote_url 'git://tok@host/org/repo.git')"
    [[ "$result" != *"tok"* ]]
}

@test "redact_remote_url: an @ in the path does not over-strip the host" {
    # The old prefix-glob was greedy and matched through the LAST @, which
    # ate the host. Userinfo matching must stop at the first @.
    result="$(redact_remote_url 'https://token@github.com/org/repo@weird')"
    [ "$result" = "https://github.com/org/repo@weird" ]
}

# ─────────────────────────────────────────────────────────────────────────────
# F2 + F3 — org parsing across every remote form
# ─────────────────────────────────────────────────────────────────────────────

@test "parse_org_from_remote: token-bearing https remote (F2 regression)" {
    result="$(parse_org_from_remote 'https://ghp_SECRETTOKEN@github.com/the-agency-ai/the-agency.git')"
    [ "$result" = "the-agency-ai" ]
}

@test "parse_org_from_remote: plain https remote with .git suffix (F3 regression)" {
    result="$(parse_org_from_remote 'https://github.com/the-agency-ai/the-agency.git')"
    [ "$result" = "the-agency-ai" ]
}

@test "parse_org_from_remote: plain https remote without .git suffix" {
    result="$(parse_org_from_remote 'https://github.com/the-agency-ai/the-agency')"
    [ "$result" = "the-agency-ai" ]
}

@test "parse_org_from_remote: scp-style git@ remote" {
    result="$(parse_org_from_remote 'git@github.com:the-agency-ai/the-agency.git')"
    [ "$result" = "the-agency-ai" ]
}

@test "parse_org_from_remote: trailing slash is tolerated" {
    result="$(parse_org_from_remote 'https://user:tok@github.com/some-org/some-repo/')"
    [ "$result" = "some-org" ]
}

@test "parse_org_from_remote: an org containing a dot still parses" {
    result="$(parse_org_from_remote 'https://github.com/my.org/my.repo.git')"
    [ "$result" = "my.org" ]
}

@test "parse_org_from_remote: rejects a URL that is not a repo path" {
    run parse_org_from_remote 'https://github.com/'
    [ "$status" -ne 0 ]
}

@test "parse_org_from_remote: rejects an empty URL" {
    run parse_org_from_remote ''
    [ "$status" -ne 0 ]
}

@test "parse_org_from_remote: never echoes the token even on the reject path" {
    run parse_org_from_remote 'https://ghp_SECRETTOKEN@github.com/'
    [[ "$output" != *"ghp_SECRETTOKEN"* ]]
}

# ─────────────────────────────────────────────────────────────────────────────
# F1 — default branch resolution
# ─────────────────────────────────────────────────────────────────────────────

@test "resolve_default_branch: returns a non-empty branch name in this repo" {
    result="$(resolve_default_branch)"
    [ -n "$result" ]
}

@test "resolve_default_branch: agrees with git's own view of origin/HEAD" {
    # Asserting a hardcoded "main" against the live repo is brittle in a
    # shallow or single-branch CI checkout where the remote-tracking ref may
    # be absent. Compare against git's answer when it has one; otherwise just
    # require a sane fallback.
    expected="$(git symbolic-ref --quiet --short refs/remotes/origin/HEAD 2>/dev/null | sed 's|^origin/||' || true)"
    result="$(resolve_default_branch)"
    if [ -n "$expected" ]; then
        [ "$result" = "$expected" ]
    else
        [ "$result" = "main" ] || [ "$result" = "master" ]
    fi
}

@test "resolve_default_branch: fallback loop runs when origin/HEAD is absent" {
    # QG finding: the clone-based fixtures below always populate
    # refs/remotes/origin/HEAD, so the primary symbolic-ref path always won
    # and the for-loop fallback — the whole point of the function on a
    # shallow/single-branch checkout — was never executed by any test.
    tmp="$(mktemp -d)"
    git init --quiet --initial-branch=main "$tmp/upstream"
    git -C "$tmp/upstream" -c user.email=t@t -c user.name=t commit --quiet --allow-empty -m init
    git clone --quiet "$tmp/upstream" "$tmp/clone" 2>/dev/null
    git -C "$tmp/clone" symbolic-ref --delete refs/remotes/origin/HEAD
    run git -C "$tmp/clone" symbolic-ref --quiet --short refs/remotes/origin/HEAD
    [ "$status" -ne 0 ]   # precondition: origin/HEAD really is gone
    result="$(cd "$tmp/clone" && resolve_default_branch)"
    rm -rf "$tmp"
    [ "$result" = "main" ]
}

@test "resolve_default_branch: falls back to master in a main-less repo" {
    tmp="$(mktemp -d)"
    git init --quiet --initial-branch=master "$tmp/upstream"
    git -C "$tmp/upstream" -c user.email=t@t -c user.name=t commit --quiet --allow-empty -m init
    git clone --quiet "$tmp/upstream" "$tmp/clone" 2>/dev/null
    result="$(cd "$tmp/clone" && resolve_default_branch)"
    rm -rf "$tmp"
    [ "$result" = "master" ]
}

@test "resolve_default_branch: picks main in a main-default repo" {
    tmp="$(mktemp -d)"
    git init --quiet --initial-branch=main "$tmp/upstream"
    git -C "$tmp/upstream" -c user.email=t@t -c user.name=t commit --quiet --allow-empty -m init
    git clone --quiet "$tmp/upstream" "$tmp/clone" 2>/dev/null
    result="$(cd "$tmp/clone" && resolve_default_branch)"
    rm -rf "$tmp"
    [ "$result" = "main" ]
}

# ─────────────────────────────────────────────────────────────────────────────
# F1 — the hardcode must not come back
# ─────────────────────────────────────────────────────────────────────────────

@test "pr-submit: no literal origin/master remains outside comments" {
    run grep -n 'origin/master' "$PR_SUBMIT"
    # Any surviving hit must be prose in a comment, never live code.
    while IFS= read -r line; do
        [ -z "$line" ] && continue
        text="${line#*:}"
        [[ "$text" =~ ^[[:space:]]*# ]] || {
            echo "live origin/master reference: $line"
            false
        }
    done <<< "$output"
}
