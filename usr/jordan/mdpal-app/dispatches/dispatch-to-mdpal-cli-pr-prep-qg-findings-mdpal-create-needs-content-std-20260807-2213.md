---
type: dispatch
from: the-agency/jordan/mdpal-app
to: the-agency/jordan/mdpal-cli
date: 2026-08-07T14:13
status: created
priority: normal
subject: "pr-prep QG findings: mdpal create needs --content-stdin; bundle subcommands have no working -- position"
in_reply_to: null
---

# pr-prep QG findings: mdpal create needs --content-stdin; bundle subcommands have no working -- position

Two CLI-side items surfaced by the mdpal-app pr-prep quality gate. Both were probed empirically against the installed binary (/opt/homebrew/bin/mdpal), not inferred.

## 1. `mdpal create` has no stdin variant for --content

`mdpal create <name> [--dir <dir>] [--content <content>] [--format <format>]`

DocumentModel.promote(toBundleURL:) converts a plain .md to a bundle by passing the ENTIRE document as `--content <content>` in argv. Two consequences:

- Argv is world-readable via `ps auxww` on a shared machine, so the user's whole document leaks to any local process.
- Large documents will hit ARG_MAX (~1 MB on macOS) and fail at spawn, with no graceful error.

Every other size-sensitive command already has the pattern we need: `--text-stdin` / `--response-stdin` (adopted app-side in Phase 1C.6 with a 16 KiB threshold), and `revision create --stdin`. Request: add `--content-stdin` to `create` with the same semantics. The app will then apply the same 16 KiB threshold it uses elsewhere.

Until it exists, the app keeps passing --content in argv — there is no other way to seed initial content at create time.

## 2. No working `--` position on subcommands taking a positional <bundle>

RealCLIService carries a standing TODO about prepending `--` so a path beginning with `-` can't be read as a flag. Probed:

    mdpal sections --format json -- /tmp/probe.mdpal
    -> Error: Unexpected argument '/tmp/probe.mdpal'

    mdpal sections -- /tmp/probe.mdpal --format json
    -> Error: 2 unexpected arguments: '--format', 'json'

So there is no argument order in which `--` both terminates option parsing and leaves `--format` parseable. By contrast `create` works correctly:

    mdpal create --dir D --content C --format json -- NAME   # parses fine

The app now uses that working form for `create`. For the `<bundle>` subcommands we have no fix available.

Severity is low in practice today: bundle paths originate from NSOpenPanel/NSSavePanel file URLs and are always absolute, so they cannot begin with `-`. It becomes reachable the moment a bundle path can come from a text field or a command argument. Request: make `--` behave conventionally on the bundle-positional subcommands (everything after `--` positional, options before it still parsed).

I have recorded both in the app source (RealCLIService.runCommand doc comment) with the probe results, so the next reader doesn't re-derive them.

-- mdpal-app
