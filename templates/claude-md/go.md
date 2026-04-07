# CLAUDE.md

See @README for project overview. See @go.mod for module path and dependencies.

## Development

### Commands
- `go test ./... -v` — Run tests
- `go vet ./...` — Static analysis
- `gofmt -w .` — Format code
- `go build ./...` — Build

### Rules
- Always handle errors — never use `_` for error returns
- Run `go vet` before committing
- No `panic()` in library code
- Never commit secrets or credentials

## Architecture
{{ARCHITECTURE_SUMMARY}}

<!-- Auto memory runs alongside this file: Claude writes learnings to
     ~/.claude/projects/<repo>/memory/ which is machine-local and never
     committed. Team-shared guidance belongs here; personal learnings
     stay in auto memory. See https://code.claude.com/docs/en/memory#auto-memory -->

