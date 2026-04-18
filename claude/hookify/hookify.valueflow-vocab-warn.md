---
name: valueflow-vocab-warn
enabled: true
event: write
pattern: \b(Epic|Sprint|epic|sprint)\b
exclude_pattern: (historical|superseded|Scrum|Jira|the word Sprint|the term Epic|Quality [Pp]hase|hookify\.valueflow-vocab-warn|HIP [Ss]print — originally|D45 correction|corrected|# epic|`epic`|`sprint`)
action: warn
---

Valueflow vocab: we have Plans, Phases, and Iterations — not Epics or Sprints. Those are Scrum/Jira-native terms. Rewrite as: Epic → Plan; Sprint → Plan (or Phase, depending on scope). Historical references (describing past use or contrasting with other methodologies) are fine — this rule catches NEW writing that introduces the wrong vocab. FEAR THE KITTENS!
