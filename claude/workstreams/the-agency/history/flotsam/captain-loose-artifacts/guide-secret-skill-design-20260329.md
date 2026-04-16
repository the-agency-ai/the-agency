---
allowed-tools: Bash(doppler *), Read, Glob, Grep
description: Manage secrets via the project's configured provider (Doppler, vault, env)
---

# Secret

Manage secrets through the project's configured provider. In monofolk, the provider is Doppler.

## Arguments

- $ARGUMENTS: verb and optional args (e.g., `set API_KEY`, `get DATABASE_URL`, `list`, `delete OLD_KEY`, `rotate SECRET`, `scan`)

## Verbs

| Verb     | What                                                          |
| -------- | ------------------------------------------------------------- |
| `set`    | Set a secret value in Doppler                                 |
| `get`    | Retrieve a secret value from Doppler                          |
| `list`   | List all secrets for a project/config                         |
| `delete` | Delete a secret from Doppler (requires confirmation)          |
| `rotate` | Rotate a secret: get current, set new, verify                 |
| `scan`   | Scan files for leaked secrets (no Doppler needed)             |

## Instructions

### Parse verb

Split `$ARGUMENTS` into the first word (verb) and the rest (args).

If `$ARGUMENTS` is empty, show the verb table above and ask which one to run.

### Provider detection

The provider for monofolk is always Doppler. Read `doppler.yaml` at the repo root to map working directories to Doppler projects and configs.

Known Doppler projects:

| Project        | Config       | Path                    |
| -------------- | ------------ | ----------------------- |
| backend        | sg_dev_noah  | apps/backend/           |
| folio-web      | dev          | apps/folio-web/         |
| folio-content  | dev          | apps/folio-content/     |
| playground-be  | dev          | apps/playground-be/     |
| playground-fe  | dev          | apps/playground-fe/     |
| prototype-fe   | dev          | apps/prototype-fe/      |
| dashboards     | (ask)        | apps/dashboards/        |
| infra          | (ask)        | (cross-cutting)         |
| mycroft-infra  | (ask)        | (cross-cutting)         |

### Project and config resolution

For every verb except `scan`:

1. **Auto-detect from doppler.yaml.** Read `doppler.yaml` at the repo root. If the principal's current working context maps to one of the setup entries, suggest that project and config.
2. **If ambiguous or cross-cutting, ask.** Present the known projects table and ask which one.
3. **Always confirm project and config with the principal before running any Doppler command.** State what you will run and get a yes.
4. **Default config is `dev`** for local work unless doppler.yaml specifies otherwise (e.g., backend uses `sg_dev_noah`).

### Verb: `set`

Set a secret in Doppler.

1. Parse the key name from args. If missing, ask for it.
2. Resolve project and config (see resolution rules above). Confirm with principal.
3. Ask the principal for the secret value.
4. Confirm the full command before running: `doppler secrets set <KEY> <VALUE> --project <P> --config <C>`
5. Run the command.
6. Report success or failure.

### Verb: `get`

Retrieve a secret value from Doppler.

1. Parse the key name from args. If missing, ask for it.
2. Resolve project and config. Confirm with principal.
3. Run: `doppler secrets get <KEY> --project <P> --config <C> --plain`
4. Display the value.

**Security note:** The value will appear in the conversation. Warn the principal before displaying if the key name suggests it is highly sensitive (e.g., contains `PASSWORD`, `PRIVATE_KEY`, `TOKEN`).

### Verb: `list`

List secrets for a project/config.

1. Resolve project and config. Confirm with principal.
2. Run: `doppler secrets --project <P> --config <C>`
3. Display the listing.

### Verb: `delete`

Delete a secret from Doppler. Destructive operation — requires explicit confirmation.

1. Parse the key name from args. If missing, ask for it.
2. Resolve project and config. Confirm with principal.
3. **Confirm deletion explicitly.** State: "This will delete `<KEY>` from project `<P>`, config `<C>`. Type 'yes' to confirm."
4. Only proceed if the principal confirms.
5. Run: `doppler secrets delete <KEY> --project <P> --config <C> --yes`
6. Report success or failure.

### Verb: `rotate`

Rotate a secret: retrieve current value, set new value, verify.

1. Parse the key name from args. If missing, ask for it.
2. Resolve project and config. Confirm with principal.
3. Retrieve the current value: `doppler secrets get <KEY> --project <P> --config <C> --plain`
4. Show the current value to the principal (with the sensitivity warning from `get`).
5. Ask the principal for the new value.
6. **Confirm rotation:** "This will replace the current value of `<KEY>` in project `<P>`, config `<C>`. Confirm?"
7. Set the new value: `doppler secrets set <KEY> <NEW_VALUE> --project <P> --config <C>`
8. Verify by reading it back: `doppler secrets get <KEY> --project <P> --config <C> --plain`
9. Confirm the read-back matches the new value.
10. Report rotation complete or failure.

### Verb: `scan`

Scan files for leaked secrets. This verb does NOT use Doppler — it inspects the codebase.

#### What to scan for

- **API key patterns:** `AIza` (Google), `sk-` (OpenAI/Stripe), `ghp_` (GitHub PAT), `ghs_` (GitHub App), `xoxb-` (Slack bot), `xoxp-` (Slack user), `AKIA` (AWS access key), `doppler_` (Doppler token)
- **High-entropy strings** in assignments, printf, echo, or env-like contexts (40+ character hex or base64 strings that look like secrets)
- **Inline credentials** in URLs: `https://user:password@host`
- **.env files** that should not exist in the repo
- **settings*.json** files with sensitive-looking values

#### Scan modes

Parse the args after `scan` for mode flags:

| Mode        | Scope                                         | When to use           |
| ----------- | --------------------------------------------- | --------------------- |
| (default)   | Staged files + settings*.json                 | Iteration scope       |
| `--project` | All files in `usr/jordan/<project>/` + `apps/<project>/` | Phase scope |
| `--full`    | Entire repo (excluding node_modules, .git, dist, build) | PR prep scope |

#### Scan procedure

1. Determine mode from args.
2. Identify the file set:
   - **Default:** Use `git diff --cached --name-only` for staged files, plus Glob for `**/settings*.json`.
   - **--project:** Glob for all files in the project areas.
   - **--full:** Glob for all files in the repo, excluding binary and build directories.
3. For each file in the set, use Grep to search for the patterns listed above.
4. For `.env*` files found anywhere (except `.env.example`), flag them regardless of content.
5. Report findings as a table:

```
| # | File | Line | Pattern | Snippet |
|---|------|------|---------|---------|
| 1 | path/to/file.ts | 42 | sk- prefix | `const key = "sk-..."` |
```

6. If no findings: "Scan clean. No leaked secrets detected."
7. If findings exist: "Found N potential secret(s). Review each finding — false positives are possible for high-entropy strings."

### Error handling

- If `doppler` CLI is not installed or not in PATH, report: "Doppler CLI not found. Install with `brew install dopplerhq/cli/doppler` and run `doppler login`."
- If Doppler auth fails, report: "Doppler auth failed. Run `doppler login` to authenticate."
- If the project or config does not exist, report the error and show the known projects table.
- If the verb is not recognized, show the verb table and ask which one to run.
