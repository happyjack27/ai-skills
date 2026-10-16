# Coding Standards

Standards that apply across all programming skill folders.

## Evidence and Exactness

- Verify implementation-relevant facts against the authoritative source before
  coding: the actual database/schema and lookup rows, repository source, API
  contract, configuration, or observed runtime behavior, as appropriate.
- Never invent field names, casing, joins, status values, method signatures,
  response shapes, or business rules. Treat existing code and memory as leads
  to verify, not proof that an assumption is correct.
- Prefer direct inspection and reproducible checks over plausible explanations.
  Distinguish verified facts from hypotheses and report contradictions explicitly.
- Use authorized alternative sources or connections when evidence is unavailable.
  If required facts still cannot be verified, report the precise blocker and stop
  the dependent change rather than filling the gap with a guess.
- Validate the exact requirement and observable result, including types, output
  shape, encoding, edge cases, and measurable limits. Compilation alone, a proxy
  check, or a test built from the same unverified assumption does not prove correctness.
- Claim only what the evidence establishes. State validation not performed and
  remaining limitations. In code, "close enough" is not correct.

## Naming

- Variables and functions: descriptive, not abbreviated.
- Constants: `UPPER_SNAKE_CASE`.
- Files: `kebab-case`.

## Code Style

- Indent with spaces (4 for Python/Java/JS, 2 for JSON/YAML/HTML).
- Max line length: 120 characters.
- One blank line between logical blocks; two between top-level definitions.
- Remove trailing whitespace.

## Abstraction

- Keep one-use logic inline unless it hides substantial complexity or marks a meaningful boundary.
- Extract a helper when it has at least three real call sites or clearly isolates complex, reusable behavior.
- Do not create or lengthen methods just to satisfy an arbitrary line-count rule; optimize for clear control flow.

## Comments

- Comment *why*, not *what*.
- Every public function/method gets a docstring or JSDoc/Javadoc block.
- TODO comments include a ticket or date: `// TODO(2026-08): refactor after migration`.

## Error Handling

- Never swallow exceptions silently.
- Log errors with enough context to reproduce.
- Validate inputs at boundaries; fail fast.

## Testing

- Tests live alongside or adjacent to source code.
- Each test has one clear assertion.
- Use descriptive test names: `should_return_empty_list_when_input_is_null`.

## Security

- No secrets in source code.
- Sanitize all user input before use.
- Prefer allow-lists over deny-lists.

## Version Control

- Small, focused commits.
- Commit message format: `<scope>: <imperative sentence>`.
- Never force-push to shared branches.
