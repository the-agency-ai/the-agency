---
name: no-push-master
enabled: true
event: bash
pattern: 'git push origin.*master|git push -u origin.*master|git push --force.*master'
action: block
---

Do not push to origin/master. All changes reach remote master through PRs on GitHub.
