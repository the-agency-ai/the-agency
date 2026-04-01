---
name: warn-compound-bash
enabled: true
event: bash
pattern: (&&|\|\||;\s|(?<!\|)\|(?!\|))
exclude_pattern: (git commit -m "\$\(cat <<|PATH=.*\bbash -c\b|2>&1 \||\| head -|\| tail -)
action: warn
---

**Compound bash command detected.** Use the built-in alternatives:

- **`cd <dir> && <cmd>`** → Use the Bash tool's `cwd` parameter instead of chaining with `cd`
- **`<cmd> | grep <pattern>`** → Run the command first, then use the Grep tool on the output file, or accept full output
- **`<cmd> || true` / `|| echo`** → Run the command in its own Bash call; handle the error in your next step
- **`<cmd>; echo $?`** → The Bash tool already returns exit codes in the error response

Allowed patterns (not flagged):
- `git commit -m "$(cat <<'EOF'..."` — heredoc is the approved commit format
- `PATH=... bash -c` — test isolation pattern
- `2>&1 |` — stderr redirection to pipe
- `| head -N` / `| tail -N` — output limiting

Run each shell command as a **single, simple command**. If you need to chain steps, use separate Bash tool calls (parallel when independent, sequential when dependent).

*OFFENDERS WILL BE FED TO THE — CUTE — ATTACK KITTENS!*
