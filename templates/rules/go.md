---
paths:
  - "{{MODULE_PATH}}/**/*.go"
---

# {{MODULE_NAME}} — Go Rules

## Code Quality
- Run `go vet ./...` before marking complete
- Run `staticcheck ./...` if available
- Run `{{LINTER}}` for linting
- Use `gofmt` or `goimports` for formatting

## Error Handling
- Always check and handle errors — never use `_` for error returns
- Wrap errors with context: `fmt.Errorf("doing X: %w", err)`
- No `panic()` in library code — return errors instead

## Testing
- Run tests: `go test ./... -v`
- Use table-driven tests for multiple cases
- Use `t.Helper()` in test helper functions

## Conventions
- Follow Go naming conventions (exported = capitalized)
- Keep interfaces small (1-3 methods)
- No init() functions unless absolutely necessary

{{SHARP_EDGES}}
