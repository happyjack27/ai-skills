# Mozilla cq reference

Source: https://github.com/mozilla-ai/cq (Apache-2.0, status 0.x). Verify flags with `cq --help` and `docs/install.md` before running them, since the project may change.

## Install the CLI

- Homebrew, Scoop, or a binary from GitHub Releases.
- Verify: `cq --version`.

## Install into a host

```
cq install --target <host> --dry-run
cq install --target <host>
cq install --target <host> --uninstall
cq install --target claude --project <dir>
```

- Repeat `--target` to install into several hosts at once.
- Hosts: `claude`, `codex`, `copilot`, `cursor`, `devin-desktop`, `opencode`, `pi`.
- `--project <dir>` installs into a project directory. Claude only.
- `--uninstall` removes the MCP entry and the instruction. It leaves the shared skill in place, because other hosts may still use it. Claude's global uninstall removes only the user-scope plugin.
- Non-Claude hosts write:
  - the shared skill at `~/.agents/skills/cq/SKILL.md` (written once for all such hosts),
  - an MCP entry that runs `cq mcp` (Pi uses a CLI mapping instead),
  - an always-loaded instruction (`AGENTS.md` block, rule file, or instructions file, depending on host). Devin Desktop writes none.
- Claude runs `claude plugin marketplace add mozilla-ai/cq` and `claude plugin install cq@cq`. The `claude` CLI must be on `PATH`.
- The CLI must be on `PATH` before install, because its resolved path is written into each host's config.
- The installer does not write `CQ_ADDR` or `CQ_API_KEY`. The user adds them to the entry the installer created. Keep the `command` and `args` the installer wrote.
- Copilot (VS Code) targets the default profile only. Its files are the VS Code user `mcp.json` (`servers.cq`) and `~/.copilot/instructions/cq.md`.

## MCP tools

| Tool | Purpose | Needs `CQ_API_KEY` |
|---|---|---|
| `query` | Search knowledge units | No |
| `propose` | Submit a new unit | Yes |
| `confirm` | Confirm an existing unit | Yes |
| `flag` | Flag a unit as wrong or stale | Yes |
| `revoke` | Withdraw a unit you proposed | Yes |
| `status` | Show store and connection state | No |

The live docs say `query` and `status` work without a key. `propose`, `confirm`, `flag`, and `revoke` need one.

## Environment

- `CQ_ADDR`: remote server URL (hosted `https://cq.exchange`, `http://localhost:3000`, or a self-hosted server).
- `CQ_API_KEY`: credential for write operations. Generated in the server dashboard. The user sets it in their own environment or host config. Never place it in files, logs, or command lines, and never paste it into chat.

## Stores

- Local store (default): `~/.local/share/cq/local.db`.
- Hosted: `https://cq.exchange`, with GitHub or Google sign-in. Each user gets a private namespace plus access to a Global Commons. Confirm current read access before relying on it.
- Self-hosted: container image `ghcr.io/mozilla-ai/cq/server`.

## Safety

- Use `--dry-run` before any install or uninstall, and show the output to the user.
- Keep proposed units free of City data, credentials, and internal hostnames.
- Retrieved units are guidance, not verified fact.
