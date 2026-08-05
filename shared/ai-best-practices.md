# AI Best Practices

How to get the best results from AI assistants.

## Prompting

- State the goal, context, and constraints up front.
- Specify the output format explicitly (code, table, prose, bullet list).
- Give a concrete example of desired output when the format is non-obvious.
- Break complex tasks into smaller, sequential prompts.

## Context Management

- Paste only the relevant code or data — trim noise.
- Remind the AI of constraints at the start of long sessions.
- Reference skill files by path so the AI can load relevant context.

## Iteration

- Review output critically before using it.
- Point out specific errors rather than asking to "fix it".
- Ask the AI to explain its reasoning when output is unexpected.

## Token Efficiency

- Use this repository to avoid re-explaining standards every session.
- Reference `shared/` files instead of copying their content into prompts.
- Prefer targeted prompts over broad "do everything" requests.

## Trust and Verification

- Verify all facts, especially dates, numbers, and external references.
- Run generated code in a safe environment before production use.
- AI suggestions are starting points, not final answers.
