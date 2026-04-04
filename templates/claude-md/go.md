# CLAUDE.md

## Project Overview
{{PROJECT_NAME}} — {{PROJECT_DESCRIPTION}}

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
