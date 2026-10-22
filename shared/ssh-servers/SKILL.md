---
name: ssh-servers
description: 'Read-only SSH access to City of Milwaukee web servers from PowerShell using a dedicated key loaded in ssh-agent. Use for checking httpd/PHP versions, vhosts, configs, and package state on dpwweb1, mpw, webapps, and dpwapps. Host facts live in ai-memory projects/server-inventory.'
---

# SSH to servers

## Purpose

Run read-only diagnostic commands on City web servers over SSH from the user's
Windows workstation, using a dedicated key. The user unlocks the key once; the
assistant never handles passwords or passphrases.

## Scope

- Included: read-only inspection (config files, `rpm -q`, `httpd -M`, `php -v`,
  `systemctl status`, `dnf check-update`, log tails with bounded line counts),
  and copying read-only config files to `working\...\tasks\inputs\`.
- Excluded: any write, restart, reload, package install, or config edit on a
  server. Those change live systems and require explicit user confirmation for
  each change, plus a test window.
- Excluded: password-based login, storing passwords in files, or pasting
  secrets, keys, or AJP/proxy secrets into chat or memory.

## When to Use

- Verifying a fact that ai-memory marks as unverified (host OS, PHP version,
  vhosts, docroot, which host serves which site).
- Collecting config for a review, such as `httpd.conf`, `conf.d\*.conf`,
  `php-fpm` pool files.

## Routing Boundaries

**Use this skill instead of nearby skills when:** the task needs a live command
on a named server.

**Do not use this skill when:** the task is about local source code, the
database (use `sql` or `migration-operations`), or the mailbox.

**Pair with:**

- `ai-memory`: read `projects/server-inventory/architecture.md` first, then record
  verified facts there.
- `accela` or `kwat-services` when a server finding needs an application fix.

## Inputs Expected

| Input | Description |
|---|---|
| Host alias | A name from `~\.ssh\config` (for example `dpwweb1`). Never a raw IP or password. |
| Command | A read-only command. Bounded output (`| head`, `tail -n`). |

## Outputs Produced

| Output | Format | Description |
|---|---|---|
| Command results | Text in chat | Short extracts. Do not dump whole files. |
| Saved config copies | Files under `working\<project>\tasks\inputs\` | Only when the user asks. Redact secrets before saving. |
| Inventory updates | ai-memory `architecture.md` | Mark each fact verified with the date and command source. |

## Workflow

1. Confirm the host alias exists in `~\.ssh\config`. If not, stop and ask the user to add it.
2. Check that the key is loaded: `ssh-add -l`. If it's missing, ask the user to run
   `ssh-add ~\.ssh\id_ed25519_ai` and enter the passphrase themselves.
3. Run the command with `-o BatchMode=yes` so an unexpected password prompt fails
   instead of hanging:
   `ssh -o BatchMode=yes -o ConnectTimeout=10 <alias> "<read-only command>"`
4. Keep the output bounded. Report the exact command and the result.
5. Record verified facts in ai-memory with the date. Note the command used as the source.

## Quality Standards

- Read-only commands only. If a command could change state, do not run it.
- Output limits are required: `head`, `tail -n`, `grep -c`, or `sed -n` ranges.
- Never print private keys, passphrases, `authorized_keys` contents beyond the
  key comment, or config secrets such as AJP secrets or DB credentials. Redact
  them before saving anything.
- Verify facts against the live host. Do not promote a user report to verified.

## Common Mistakes

- Using `ssh` without `BatchMode=yes`. It can hang on a password prompt.
- Saving a password, passphrase, or secret in a script, `.conf`, or memory file.
- Running `dnf update`, `systemctl restart`, or `apachectl graceful` as a "check".
- Treating `dnf updateinfo` returning nothing as proof that no fix exists.

## Validation Checklist

- [ ] `ssh-add -l` shows the dedicated key before running commands.
- [ ] Every command was read-only and output-bounded.
- [ ] No secrets appear in the reply, memory, or saved files.
- [ ] Each fact recorded in ai-memory has a verification date and command source.

## Resources

- Host list and roles: [server inventory](C:/Users/kbaas/git/ai-memory/projects/server-inventory/architecture.md).
  Open when you need a host's role or unverified status.
- One-time setup (the user performs it; the assistant doesn't handle the passphrase):
  1. `ssh-keygen -t ed25519 -f ~\.ssh\id_ed25519_ai -C "ai-assistant-readonly"`
     Enter a passphrase when prompted. Keep it private.
  2. `Start-Service ssh-agent` (as admin, once), then `ssh-add ~\.ssh\id_ed25519_ai`.
  3. Send only the `.pub` file to the server administrator. They add it to a
     read-only account's `authorized_keys`, ideally with `command=` or a
     restricted shell.
  4. Add a host block to `~\.ssh\config`, for example:
     ```
     Host dpwweb1
         HostName dpwweb1.milwaukee.gov
         User <readonly-account>
         IdentityFile ~/.ssh/id_ed25519_ai
         IdentitiesOnly yes
     ```
