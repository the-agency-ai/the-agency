# Running The Agency on Ubuntu and WSL

The framework was written on macOS. This page covers what differs on Ubuntu
(22.04 and 24.04) and on Ubuntu under WSL 2, and how the tools handle it.

## Setup

```bash
./agency/tools/agency deps install     # apt packages + the two version floors below
./agency/tools/agency deps             # verify; exit code = missing + too old
```

`agency deps` prints the platform it detected (`linux` or `wsl`). On Linux,
`ghostty` is reported as "not needed" rather than missing.

`./agency/tools/platform-setup` does the same floor handling for the small
essential set (jq, gh, tree, sqlite3, Python).

## Version floors Ubuntu does not meet

| Tool | Framework floor | Ubuntu 22.04 | Ubuntu 24.04 | What the installer does |
|---|---|---|---|---|
| `sqlite3` | 3.38 (ISCP) | 3.37.2 — too old | 3.45 | Builds the current official release into `~/.local/bin/sqlite3` |
| Python | 3.13 | 3.10 — too old | 3.12 — too old | Installs `python3.13` beside the system `python3` |

**sqlite3.** With the distro 3.37, `dispatch`, `flag`, `iscp-check` and
`session-pickup` stop with `sqlite3 3.37.2 is too old`. The installer downloads
the amalgamation source from sqlite.org, checks it against the SHA3-256 that
sqlite.org publishes, compiles it (about a minute, needs `build-essential`,
`curl`, `unzip`) and installs it to `~/.local/bin`. The prebuilt binary from
sqlite.org is not used because it needs glibc 2.38; 22.04 has 2.35.
`~/.local/bin` must come before `/usr/bin` on `PATH` (Ubuntu's default
`~/.profile` does this once the directory exists — open a new shell).

**Python.** The installer uses `uv python install 3.13` when `uv` is present,
otherwise the deadsnakes PPA. Either way the result is a `python3.13` binary;
`python3` stays the distro version. Framework Python tools start with
`#!/usr/bin/env python3` and re-exec themselves under `python3.13` (or newer)
when the interpreter they were started with is too old. Set
`AGENCY_PY_NO_REEXEC=1` to turn that off.

Do not repoint `/usr/bin/python3` with `update-alternatives`. `apt` and other
system tools are built against the distro Python and break.

**bats.** Ubuntu 22.04's `bats` package is 1.2; the test suite is written
against 1.10+. Use `npm install -g bats` there.

## WSL specifics

**Where the repo lives.** A clone under your Linux home (`~/code/...`) behaves
like any Linux checkout. A clone on a Windows drive (`/mnt/c`, `/mnt/d`) works,
with these differences — `agency deps` prints a note when it detects one:

- Git and the test suite are several times slower.
- `chmod` is ignored unless the drive is mounted with the `metadata` option, so
  every file reads as executable and git is run with `core.fileMode=false`.
  To enable real permissions, add to `/etc/wsl.conf` and run `wsl --shutdown`:

  ```ini
  [automount]
  options = "metadata,umask=22,fmask=11"
  ```

- Keep line endings as LF. If Git for Windows also touches the checkout, set
  `git config core.autocrlf input` in it; CRLF in a tool script fails with
  `bad interpreter: /bin/bash^M`.

**ISCP database.** It lives at `~/.agency/<repo>/`, on the Linux filesystem,
regardless of where the repo is. That is deliberate: sqlite's WAL mode needs
locking that Windows-drive mounts do not provide. Do not point `ISCP_DB_PATH`
at `/mnt/<drive>/...`.

**Terminal integration.** Ghostty has no Windows build. Under WSL use
**Herdr** (https://herdr.dev), a terminal workspace manager for coding agents:

```bash
./agency/tools/terminal-setup        # inside Herdr: selects the herdr provider
herdr integration install claude     # Herdr's own hook: idle / working / blocked
```

`terminal-setup` registers `agency/hooks/herdr-status.sh` on SessionStart and
SessionEnd in `.claude/settings.json`. On session start the hook tells Herdr
which Agency agent is in the pane (display agent = agent name, title =
`repo/principal/agent`) and clears it at session end. It reports display
metadata only; agent state stays with Herdr's own Claude integration so the
two never conflict. Outside Herdr the hook exits immediately.

The Ghostty status hooks exit immediately unless `TERM_PROGRAM=ghostty`.
`ghostty-*` and `icloud-setup` are macOS tools; skip them. The Claude Code
status line (`agency/tools/statusline.sh`) works as is.

**Docker.** Use Docker Desktop with WSL integration enabled for the distro, or
Docker Engine inside WSL with `systemd=true` in `/etc/wsl.conf`.

## Running the dev-repo test suite as another user

Agent identity comes from the `principals:` map in `agency/config/agency.yaml`,
keyed by OS username. In the framework's own repo only the maintainer is
listed, so tests that need a resolved identity fail for anyone else. Adopter
repos do not have this problem: `agency init --principal <name>` writes the
entry.

## What was changed for this port

- `agency/tools/lib/_platform` — platform, WSL and Windows-mount detection;
  version comparison; `agency_find_python`.
- `agency/tools/lib/_linux-floors` — `linux_ensure_sqlite`, `linux_ensure_python`.
- `agency deps` — Linux/WSL install path, per-platform binary names
  (`bats`, `rg`, `fdfind`, `md5sum`), `min_version` enforcement.
- `dependencies-check` / `dependencies-install` — no longer abort on the first
  counter increment under `set -e`; yq bootstrap needs no sudo.
- `dispatch-monitor`, `templates/TOOL.py` — re-exec under `python3.13`.
- `hooks/herdr-status.sh`, `tools/terminal-setup-herdr` — Herdr terminal provider;
  `terminal-setup` selects it inside Herdr.
- `agent-create` — `sed -i ''` (BSD only) replaced with a portable form.
- `_path-resolve`, `config` — an OS user missing from `principals:` resolved
  to `"unknown "` with a trailing space, and `principal` printed a Python dict.
- `src/tests/tools/wsl-ubuntu-port.bats` — regression tests for all of the above.
