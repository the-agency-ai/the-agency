---
name: no-push-main
enabled: true
event: bash
pattern: 'git push origin.*(main|master)|git push -u origin.*(main|master)|git push --force.*(main|master)'
action: block
---

Do not push to origin/main or origin/master. All changes reach remote through PRs on GitHub.
