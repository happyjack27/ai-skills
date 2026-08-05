# Coding Standards

Standards that apply across all programming skill folders.

## Naming

- Variables and functions: descriptive, not abbreviated.
- Constants: `UPPER_SNAKE_CASE`.
- Files: `kebab-case`.

## Code Style

- Indent with spaces (4 for Python/Java/JS, 2 for JSON/YAML/HTML).
- Max line length: 120 characters.
- One blank line between logical blocks; two between top-level definitions.
- Remove trailing whitespace.

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
