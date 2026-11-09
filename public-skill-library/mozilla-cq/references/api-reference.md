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
```

- Hosts: `claude`, `codex`, `copilot`, `cursor`, `devin-desktop`, `opencode`, `pi`.
- `--project` applies to Claude only.
- A normal install writes:
  - a skill at `~/.agents/skills/cq/SKILL.md`,
  - an MCP entry that runs `cq mcp`,
  - an `AGENTS.md`-style instruction block.
- Pi uses a CLI mapping instead of an MCP entry.
- The installer does not write `CQ_ADDR` or `CQ_API_KEY`. The user sets those.

## MCP tools

| Tool | Purpose | Needs `CQ_API_KEY` |
|---|---|---|
| `query` | Search knowledge units | No |
| `propose` | Submit a new unit | Yes |
| `confirm` | Confirm an existing unit | Yes |
| `flag` | Flag a unit as wrong or stale | Yes |
| `revoke` | Withdraw a unit you proposed | Yes |
| `status` | Show store and connection state | No |

## Environment

- `CQ_ADDR`: remote server URL (hosted `https://cq.exchange`, or a self-hosted server).
- `CQ_API_KEY`: credential for write operations. The user sets it in their own environment. Never place it in files, logs, or command lines.

## Stores

- Local store (default): `~/.local/share/cq/local.db`.
- Hosted: `https://cq.exchange`, with GitHub or Google sign-in. Each user gets a private namespace plus access to a Global Commons. Confirm current read access before relying on it.
- Self-hosted: container image `ghcr.io/mozilla-ai/cq/server`.

## Safety

- Use `--dry-run` before any install or uninstall, and show the output to the user.
- Keep proposed units free of City data, credentials, and internal hostnames.
- Retrieved units are guidance, not verified fact.
