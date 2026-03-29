---
name: warn-compound-bash
enabled: true
event: bash
pattern: (&&|\|\||;\s|(?<!\|)\|(?!\|))
action: warn
---

**Compound bash command detected.** Use the built-in alternatives:

- **`cd <dir> && <cmd>`** → Use the Bash tool's `cwd` parameter instead of chaining with `cd`
- **`<cmd> | tail -N` / `| head -N`** → Use separate Bash call; the output is already captured. Or use Read with `limit`/`offset` for files
- **`git commit -m "$(cat <<'EOF'...`** → Use the `/git-commit` skill instead of raw git commit with heredoc
- **`<cmd> | grep <pattern>`** → Run the command first, then use the Grep tool on the output file, or accept full output
- **`<cmd> || true` / `|| echo`** → Run the command in its own Bash call; handle the error in your next step
- **`<cmd>; echo $?`** → The Bash tool already returns exit codes in the error response
- **`PATH=... <cmd>`** → Set env vars in the Bash tool's env parameter, or ensure PATH is configured in hooks

Run each shell command as a **single, simple command**. If you need to chain steps, use separate Bash tool calls (parallel when independent, sequential when dependent).
