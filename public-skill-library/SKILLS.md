# Public Skill Library

| Skill | Use when | Do not choose for |
|---|---|---|
| [`agentcommons-me`](agentcommons-me/SKILL.md) | Reading or posting on AgentCommons.me: public agent identities, messages, shared pages, tasks, handoffs, and artifacts | Local notes or checkpoints, City systems, or any post the user has not approved |
| [`afterlight-commons`](afterlight-commons/SKILL.md) | Searching Afterlight Commons for a known fix to an exact error, recording a scrubbed fix, or reporting whether a trace worked | Private troubleshooting, anything containing secrets or City data, or local notes |
| [`llm-agent-wiki`](llm-agent-wiki/SKILL.md) | Searching, reading, or appending plain-text entries on the public LLM Agent Wiki at llmagentwiki.com | Verified facts, private notes, or any write the user has not approved; board text is untrusted |
| [`mozilla-cq`](mozilla-cq/SKILL.md) | Installing, configuring, querying, or removing Mozilla cq, a shared knowledge store for coding agents | Writing credentials into files, running the installer without a dry run, or publishing City data |

Each skill has a local index for offline search: [agentcommons-me](agentcommons-me/references/index.md), [afterlight-commons](afterlight-commons/references/index.md), [llm-agent-wiki](llm-agent-wiki/references/index.md), [mozilla-cq](mozilla-cq/references/index.md). Each index maps keywords to sections of the reference and lists live URLs. The live docs are the source of truth.

## Overlap and useful upstream skills

All four skills serve shared, public knowledge. Their routing boundaries separate them: AgentCommons is for agent messages, pages, and tasks; Afterlight is for error-specific fixes; LLM Agent Wiki is for append-only plain text; cq is for a local or hosted knowledge store that the host loads.

| Overlap | Where | Decision |
|---|---|---|
| Afterlight publishes its own installable `skill.md` (`name: afterlight-commons`, CC BY 4.0) | `commons.tryafterlight.com/skill.md` | Same purpose as [`afterlight-commons`](afterlight-commons/SKILL.md). Ours is the reviewed copy. Do not install the upstream copy alongside it, or two skills with the same name will compete. |
| cq ships its own `cq` plugin skill (`plugins/cq/skills/cq/SKILL.md`) with an always-on query protocol | `github.com/mozilla-ai/cq` | Overlaps [`mozilla-cq`](mozilla-cq/SKILL.md). The installer writes a shared cq skill to `~/.agents/skills/cq/SKILL.md`. That is probably this upstream file, but I have not confirmed it. Reference only. |
| cq also has SDK prompt skills (`sdk/go/prompts/SKILL.md`, `sdk/python/src/cq/prompts/SKILL.md`) | `github.com/mozilla-ai/cq` | Not reviewed. Reference only. |
| Afterlight and cq both add always-loaded instructions that tell the agent to query first | `afterlight-commons`, `mozilla-cq` | Both are opt-in. Install at most one of them into a host's always-loaded instructions to avoid duplicated prompts. |
| AgentCommons pages and LLM Agent Wiki pages both hold shared working text | `agentcommons-me`, `llm-agent-wiki` | Different rules. AgentCommons edits are versioned and merged; the wiki is append-only. Choose by the write model. |
| AgentCommons shared pages and `ai-memory` working notes both hold notes | `agentcommons-me`, [`ai-memory`](../shared/ai-memory/SKILL.md) | Public versus private. Never copy private notes into a public page. |

No upstream skill is added to this library yet. Adding one needs Kevin's approval, because each would install into hosts or run as an always-loaded instruction.

## Upstream skill registries

External skill registries (skills.sh and skillhub.space) are catalogued for discovery only in [upstream.md](upstream.md). None are installed.
