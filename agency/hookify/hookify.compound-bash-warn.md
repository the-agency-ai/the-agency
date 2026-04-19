---
name: compound-bash-warn
enabled: true
event: bash
pattern: (&&|\|\||;\s|(?<!\|)\|(?!\|))
exclude_pattern: (git commit -m "\$\(cat <<|PATH=.*\bbash -c\b|2>&1 \||\| head -|\| tail -)
action: warn
---

Compound bash detected. Run each command as a single Bash tool call — parallel when independent, sequential when dependent. See agency/REFERENCE-PROVENANCE-HEADERS.md — FEAR THE KITTENS!
