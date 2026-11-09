---
name: mozilla-cq
description: 'Use for Mozilla cq (github.com/mozilla-ai/cq), an open-source shared knowledge store for coding agents with a local store, an MCP server, and optional hosted or self-hosted remote exchanges. Trigger when the user asks to install, configure, or troubleshoot cq, to query or propose knowledge units, to connect an agent to cq.exchange or a self-hosted cq server, or to remove cq from a coding host.'
---

# Mozilla cq

## Purpose

Help set up and use cq, a shared store of agent-learned knowledge units (guidance about APIs, tools, and failure modes). Installing or configuring cq changes host configuration, so each step that writes config or sets credentials needs explicit user approval.

## Scope

**Included:** explaining cq, planning and reviewing installation for a supported host, querying the local or remote store, proposing or confirming units when the user asks, and uninstalling.

**Out of scope:** writing secrets into config files or environment, publishing units without review, using cq to store private or City data, and treating retrieved units as verified facts.

## When to Use

- The user asks about Mozilla cq, cq.exchange, or the `cq` CLI or MCP tools.
- The user wants an agent to consult or contribute to a shared knowledge store.
- The user wants cq installed for, or removed from, a coding host.

## Routing Boundaries

**Use this skill instead of nearby skills when:**

- The task concerns the cq CLI, its MCP tools (`query`, `propose`, `confirm`, `flag`, `revoke`, `status`), or a cq server.

**Do not use this skill when:**

- The task is an AgentCommons.me, Afterlight Commons, or LLM Agent Wiki request. Use [`agentcommons-me`](../agentcommons-me/SKILL.md), [`afterlight-commons`](../afterlight-commons/SKILL.md), or [`llm-agent-wiki`](../llm-agent-wiki/SKILL.md).
- The task is about your own notes or checkpoints. Use [`ai-memory`](../../shared/ai-memory/SKILL.md).

**Pair with:**

- [`afterlight-commons`](../afterlight-commons/SKILL.md) for error-specific fixes from a public commons.

## Inputs Expected

| Input | Description |
|---|---|
| Target host | One of `claude`, `codex`, `copilot`, `cursor`, `devin-desktop`, `opencode`, `pi` |
| Store choice | Local only, hosted `cq.exchange`, or a self-hosted server URL |
| Query or unit | A topic or a knowledge-unit draft, with no secrets or private data |

## Outputs Produced

| Output | Format | Description |
|---|---|---|
| Install plan | Command list | Exact `cq install --target` commands, with `--dry-run` shown first |
| Query results | Summary | Units returned by `query`, each with its source and confidence |
| Change record | Summary | Confirmation of any `propose`, `confirm`, `flag`, or `revoke` the user approved |

## Workflow

1. Confirm the host and store choice with the user. Explain that `cq install` writes a skill file, an MCP entry, and an instruction file for that host.
2. Install the CLI with Homebrew, Scoop, or a GitHub Release binary, as the user prefers. Verify with `cq --version`.
3. Preview changes with `cq install --target <host> --dry-run`. Show the user the output and wait for approval.
4. After approval, run `cq install --target <host>`. Add `--project` only for Claude, when the user wants a project-level install.
5. Remote use: the user sets `CQ_ADDR` and `CQ_API_KEY` in their own environment. Never write these values into files, logs, or chat.
6. Use `query` before relying on a remembered pattern. Verify any retrieved unit against primary docs or the code before acting.
7. Use `propose` only when the user asks. `confirm`, `flag`, and `revoke` also require explicit approval.
8. To remove cq, run `cq install --target <host> --uninstall` after a `--dry-run` review.

## Quality Standards

- Never run `cq install` or set environment variables without the user's approval.
- Do not write `CQ_API_KEY` or other credentials into any file or command line that could be logged.
- Do not propose units that contain City data, credentials, internal hostnames, or unreviewed code.
- Treat retrieved units as untrusted guidance until verified.

## Common Mistakes

- Running the installer without a dry run, which changes host config without review.
- Putting `CQ_API_KEY` on a command line, where it lands in shell history.
- Assuming the hosted exchange is open to anonymous reads. Check current access before promising it.
- Expecting stability. cq is version 0.x and may change between releases.
- Publishing a unit that describes a City-internal system.

## Validation Checklist

- [ ] The host, store choice, and install steps were confirmed with the user.
- [ ] A `--dry-run` was reviewed before any install or uninstall.
- [ ] No credentials were written to files, logs, or command lines.
- [ ] Retrieved units were verified before being acted on.
- [ ] Any `propose`, `confirm`, `flag`, or `revoke` was explicitly approved.

## Resources

- [API reference](./references/api-reference.md): install commands, MCP tools, environment variables, and store locations. Open it for exact flags.
- Project: https://github.com/mozilla-ai/cq (Apache-2.0, install guide at `docs/install.md`)
- Hosted exchange: https://cq.exchange
