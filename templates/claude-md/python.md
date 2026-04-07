# CLAUDE.md

See @README for project overview. See @pyproject.toml for dependencies and tooling.

## Development

### Commands
- `{{TEST_COMMAND}}` — Run tests
- `{{LINT_COMMAND}}` — Run linter
- `{{LINT_FIX_COMMAND}}` — Auto-fix lint issues
- `{{TYPE_CHECK_COMMAND}}` — Type checking
- `{{FORMAT_COMMAND}}` — Format code

### Rules
- Type hints required on all functions
- Run tests before committing
- No workarounds — fix root cause
- Never commit secrets or credentials

## Architecture
{{ARCHITECTURE_SUMMARY}}

<!-- Auto memory runs alongside this file: Claude writes learnings to
     ~/.claude/projects/<repo>/memory/ which is machine-local and never
     committed. Team-shared guidance belongs here; personal learnings
     stay in auto memory. See https://code.claude.com/docs/en/memory#auto-memory -->

