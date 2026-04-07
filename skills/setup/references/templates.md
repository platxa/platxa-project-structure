# Template Selection & Token Reference

Detailed template selection logic and token substitution map used by Steps 3-6 of the setup pipeline.

## Language Rule Template Selection

| Module language | Template |
|---|---|
| Python | `templates/rules/python.md` |
| TypeScript / JavaScript | `templates/rules/typescript.md` |
| Go | `templates/rules/go.md` |
| Rust | `templates/rules/rust.md` |
| Other | `templates/rules/generic.md` |

## Framework Rule Append

If a framework is detected, **append** the framework template content to the language-wide rule file (do not replace):

| Framework | Template |
|---|---|
| Next.js (App Router) | `templates/rules/framework-nextjs-approuter.md` |
| FastAPI | `templates/rules/framework-fastapi.md` |
| Django | `templates/rules/framework-django.md` |
| Express / NestJS | `templates/rules/framework-express.md` |

If no framework is detected, skip the framework append step.

## Database Rule Substitution

Database rules are substituted into the `{{DATABASE_RULES}}` token of the language template:

| Database | Template |
|---|---|
| PostgreSQL | `templates/rules/database-postgresql.md` |
| MongoDB | `templates/rules/database-mongodb.md` |
| Redis | `templates/rules/database-redis.md` |

If multiple databases are detected, concatenate all matching templates. If none are detected, substitute with an empty string.

## Token Substitution Map

All templates use `{{DOUBLE_BRACE}}` tokens. The setup skill substitutes them from the analyzer report:

| Token | Source field | Example value |
|---|---|---|
| `{{MODULE_NAME}}` | `modules[].name` (capitalized) | `Auth` |
| `{{MODULE_PATH}}` | `modules[].path` (full from repo root for monorepos) | `packages/api` |
| `{{FILE_COUNT}}` | `modules[].files` | `37` |
| `{{LINE_COUNT}}` | `modules[].lines` | `16150` |
| `{{COMPLEXITY}}` | `modules[].complexity` | `XL` |
| `{{TEST_COMMAND}}` | derived from `stack.testFramework` | `pytest -v` |
| `{{LINT_COMMAND}}` | derived from `stack.linter` | `ruff check` |
| `{{LINT_FIX_COMMAND}}` | derived from `stack.linter` | `ruff check --fix` |
| `{{LINTER}}` | `stack.linter` | `ruff` |
| `{{TYPE_CHECKER}}` | `stack.typeChecker` | `pyright` |
| `{{TYPE_CHECK_COMMAND}}` | derived from `stack.typeChecker` | `pyright .` |
| `{{FORMATTER}}` | `stack.formatter` | `ruff format` |
| `{{FORMAT_CHECK_COMMAND}}` | derived from `stack.formatter` | `ruff format --check .` |
| `{{FORMAT_FIX_COMMAND}}` | derived from `stack.formatter` | `ruff format .` |
| `{{TEST_FRAMEWORK}}` | `stack.testFramework` | `pytest` |
| `{{DEV_COMMAND}}` | derived from `stack.framework` / package.json | `npm run dev` |
| `{{FORMAT_COMMAND}}` | alias for `{{FORMAT_FIX_COMMAND}}` (used in CLAUDE.md templates) | `ruff format .` |
| `{{SOURCE_GLOB}}` | derived from `stack.language` | `**/*.py` |
| `{{TEST_GLOB}}` | derived from `stack.testFramework` | `tests/**/*.py` |
| `{{ARCHITECTURE_SUMMARY}}` | computed narrative from `modules[]` by setup skill | (multi-line) |
| `{{DATABASE_RULES}}` | concatenated database templates | (multi-line) |
| `{{SHARP_EDGES}}` | formatted from `sharpEdges[]` per module | (multi-line) |

## Common Skill Command Values

Used when Step 4 generates skill templates:

| Skill | Common values |
|---|---|
| `run-tests` | `pytest -v`, `npm test`, `go test ./...`, `cargo test` |
| `lint` | `ruff check` / `ruff check --fix`, `eslint .` / `eslint . --fix`, `golangci-lint run`, `cargo clippy` |
| `format-check` | `ruff format --check .` / `ruff format .`, `prettier --check .` / `prettier --write .`, `gofmt -l .` / `gofmt -w .`, `cargo fmt --check` / `cargo fmt` |
| `typecheck` | `pyright .`, `tsc --noEmit`, `go vet ./...` |

## Sharp Edge Formatting

Sharp edges are rendered into rule files as a markdown list under a `## Sharp Edges` heading:

```markdown
## Sharp Edges
- **shell=True** at `ssh_tunnel.py:42` — potential command injection risk
- **hardcoded password** at `settings.py:29` — use environment variables instead
```

## Subagent Generation Matrix

Step 5 generates domain-matched subagents based on module names/paths:

| Module pattern | Agent template | Output file |
|---|---|---|
| `auth`, `security`, `login`, `oauth` | `templates/agents/security-reviewer.md` | `.claude/agents/security-reviewer.md` |
| `api`, `routes`, `endpoints`, `controllers` | `templates/agents/api-tester.md` | `.claude/agents/api-tester.md` |
| `db`, `database`, `models`, `migrations`, `orm` | `templates/agents/db-reviewer.md` | `.claude/agents/db-reviewer.md` |

Also: if `databases[]` is non-empty in the analyzer report, generate the `db-reviewer` agent regardless of module name match.

If no modules match any domain pattern, skip Step 5 entirely.
