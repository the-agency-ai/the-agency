---
type: commit
from: the-agency/jordan/pr-submit-org-resolution
to: the-agency/jordan/captain
date: 2026-08-08T02:30
status: created
priority: normal
subject: "Committed 7d9fc73c on fix/pr-submit-org-resolution: fix(pr-submit): default-branch resolution, credential redaction, org parsing + 27 bats tests

NOT FOR PUSH — handed to captain for consolidation through the canonical
pr-submit worktree, per principal's split decision. Committed locally only so
the work and its review findings are not lost.

Three defects that block /pr-submit for every agent in a main-default repo:
  F1 receipt-matching diff hash computed against a literal origin/master
  F2 credential-bearing remote rejected by the ORG parser, and the failure
     path echoed the raw remote — leaking a PAT to terminal/logs/transcripts
  F3 https branch used ([^/.]+?)(\.git)?/? — POSIX ERE has no lazy
     quantifier, so it matched no .git-suffixed https remote at all

Extracted redact_remote_url / parse_org_from_remote / resolve_default_branch
as pure helpers behind a PR_SUBMIT_LIB_ONLY source guard so all three are
unit-testable without a repo, a pushed branch, or a signed receipt.

Two further defects found by QG review of my own first cut, both fixed:
  - redaction anchored on a literal https:// prefix, so ssh://, http:// and
    git:// remotes went through completely unredacted and still leaked. Now
    scheme-generic, and userinfo matching stops at the FIRST @ so a path
    containing @ no longer eats the host.
  - the source guard keyed only on the env var, so an inherited
    PR_SUBMIT_LIB_ONLY made a normal execution exit 0 having skipped every
    precondition and sent nothing — indistinguishable from success. Now also
    requires BASH_SOURCE != $0.

Test gaps found and closed: the clone-based fixtures always populate
origin/HEAD, so the fallback loop was never executed; and a hardcoded
'main' assertion was brittle under shallow CI checkout.

27/27 bats green. Full suite 1175 pass; the 22 failures are pre-existing in
agency init/update/verify and touch nothing here."
in_reply_to: null
---

# Committed 7d9fc73c on fix/pr-submit-org-resolution: fix(pr-submit): default-branch resolution, credential redaction, org parsing + 27 bats tests

NOT FOR PUSH — handed to captain for consolidation through the canonical
pr-submit worktree, per principal's split decision. Committed locally only so
the work and its review findings are not lost.

Three defects that block /pr-submit for every agent in a main-default repo:
  F1 receipt-matching diff hash computed against a literal origin/master
  F2 credential-bearing remote rejected by the ORG parser, and the failure
     path echoed the raw remote — leaking a PAT to terminal/logs/transcripts
  F3 https branch used ([^/.]+?)(\.git)?/? — POSIX ERE has no lazy
     quantifier, so it matched no .git-suffixed https remote at all

Extracted redact_remote_url / parse_org_from_remote / resolve_default_branch
as pure helpers behind a PR_SUBMIT_LIB_ONLY source guard so all three are
unit-testable without a repo, a pushed branch, or a signed receipt.

Two further defects found by QG review of my own first cut, both fixed:
  - redaction anchored on a literal https:// prefix, so ssh://, http:// and
    git:// remotes went through completely unredacted and still leaked. Now
    scheme-generic, and userinfo matching stops at the FIRST @ so a path
    containing @ no longer eats the host.
  - the source guard keyed only on the env var, so an inherited
    PR_SUBMIT_LIB_ONLY made a normal execution exit 0 having skipped every
    precondition and sent nothing — indistinguishable from success. Now also
    requires BASH_SOURCE != $0.

Test gaps found and closed: the clone-based fixtures always populate
origin/HEAD, so the fallback loop was never executed; and a hardcoded
'main' assertion was brittle under shallow CI checkout.

27/27 bats green. Full suite 1175 pass; the 22 failures are pre-existing in
agency init/update/verify and touch nothing here.

## Commit: 7d9fc73c

**Branch:** fix/pr-submit-org-resolution
**Agent:** the-agency/jordan/pr-submit-org-resolution
**Message:** fix/pr-submit-org: fix(pr-submit): default-branch resolution, credential redaction, org parsing + 27 bats tests

NOT FOR PUSH — handed to captain for consolidation through the canonical
pr-submit worktree, per principal's split decision. Committed locally only so
the work and its review findings are not lost.

Three defects that block /pr-submit for every agent in a main-default repo:
  F1 receipt-matching diff hash computed against a literal origin/master
  F2 credential-bearing remote rejected by the ORG parser, and the failure
     path echoed the raw remote — leaking a PAT to terminal/logs/transcripts
  F3 https branch used ([^/.]+?)(\.git)?/? — POSIX ERE has no lazy
     quantifier, so it matched no .git-suffixed https remote at all

Extracted redact_remote_url / parse_org_from_remote / resolve_default_branch
as pure helpers behind a PR_SUBMIT_LIB_ONLY source guard so all three are
unit-testable without a repo, a pushed branch, or a signed receipt.

Two further defects found by QG review of my own first cut, both fixed:
  - redaction anchored on a literal https:// prefix, so ssh://, http:// and
    git:// remotes went through completely unredacted and still leaked. Now
    scheme-generic, and userinfo matching stops at the FIRST @ so a path
    containing @ no longer eats the host.
  - the source guard keyed only on the env var, so an inherited
    PR_SUBMIT_LIB_ONLY made a normal execution exit 0 having skipped every
    precondition and sent nothing — indistinguishable from success. Now also
    requires BASH_SOURCE != $0.

Test gaps found and closed: the clone-based fixtures always populate
origin/HEAD, so the fallback loop was never executed; and a hardcoded
'main' assertion was brittle under shallow CI checkout.

27/27 bats green. Full suite 1175 pass; the 22 failures are pre-existing in
agency init/update/verify and touch nothing here.

### Metadata
- commit_hash: 7d9fc73c
- branch: fix/pr-submit-org-resolution
- files_changed: 3
- stage: none
- stage_hash: none
- work_item: none

### Files Changed
```
.claude/skills/pr-submit/scripts/pr-submit
agency/.agency/projects.json
src/tests/skills/pr-submit-helpers.bats
```
