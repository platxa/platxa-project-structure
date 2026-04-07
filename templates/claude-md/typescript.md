# CLAUDE.md

See @README for project overview. See @package.json for available scripts and dependencies.

## Development

### Commands
- `{{TEST_COMMAND}}` — Run tests
- `{{LINT_COMMAND}}` — Run linter
- `{{TYPE_CHECK_COMMAND}}` — Type checking
- `{{FORMAT_COMMAND}}` — Format code
- `{{DEV_COMMAND}}` — Start dev server

### Rules
- Strict TypeScript — no `any` types
- Run type checking before committing
- No `console.log` in production code
- Never commit secrets or credentials

## Architecture
{{ARCHITECTURE_SUMMARY}}

<!-- Auto memory runs alongside this file: Claude writes learnings to
     ~/.claude/projects/<repo>/memory/ which is machine-local and never
     committed. Team-shared guidance belongs here; personal learnings
     stay in auto memory. See https://code.claude.com/docs/en/memory#auto-memory -->

