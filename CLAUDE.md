# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Is

A Claude Code **plugin** that auto-generates project structure (`.claude/rules/`, `.claude/skills/`, `.claude/agents/`, `CLAUDE.md`, hook suggestions) for any codebase. The user runs `/platxa-project-structure:setup` on their project and the plugin analyzes the codebase through a multi-step pipeline to scaffold everything Claude Code needs to work effectively.

**Current version**: v1.2.0 — hook-compliance release using canonical Claude Code events (`PreToolUse`, `PostToolUse`, `InstructionsLoaded`).

## Plugin Architecture

Three layers execute in sequence:

1. **Agent** (`agents/project-analyzer.md`) — Dispatched first. Runs bash commands to detect language, framework variants (e.g. Next.js App Router vs Pages Router), test runner, linter, databases, monorepo patterns, modules, sharp edges, infrastructure-as-code (Docker/k8s/Terraform), CI configs, and sensitive paths. Returns a structured JSON report.

2. **Templates** (`templates/`) — Parameterized markdown with `{{TOKEN}}` placeholders. The setup skill selects templates by detected language/framework/database and substitutes tokens. Every token used must be registered in `tests/validate-tokens.sh` and documented in `skills/setup/references/templates.md`.

3. **Skill** (`skills/setup/SKILL.md` + `references/`) — Main orchestrator, progressively disclosed per Anthropic's skill guidance. Core `SKILL.md` holds the pipeline; detailed modes live in `references/audit.md`, `references/dry-run.md`, `references/templates.md`.

### Pipeline

| Step | Purpose |
|---|---|
| 0 | Preflight — warn about ancestor/managed CLAUDE.md and suggest `claudeMdExcludes` in monorepos |
| 1 | Analyze project (dispatch `project-analyzer` agent) |
| 2 | Calculate before-score |
| 3 | Generate `.claude/rules/` (path-scoped, with infra.md and ci.md when applicable) |
| 4 | Generate `.claude/skills/` (with progressive disclosure) |
| 5 | Generate `.claude/agents/` (domain-matched + complexity-triggered) |
| 6 | Audit-or-generate `CLAUDE.md` (with `@import` references) |
| 7 | Generate hook suggestions (canonical `PreToolUse`/`PostToolUse`/`InstructionsLoaded`) |
| 8 | Calculate after-score and print report |

### Flags

| Flag | Effect |
|---|---|
| *(none)* | Full pipeline |
| `--dry-run` | Preview without writing any files |
| `--audit` | Health-check existing `.claude/` structure (non-destructive) |
| `--update` | Fill only missing slots — never touch present files |
| `--with-local` | Also generate a gitignored `CLAUDE.local.md` |
| `--seed-memory` | Print a starter `MEMORY.md` template for auto memory |

### Key Design Constraints

- **Non-destructive**: NEVER overwrite existing files. Skip and report.
- **Canonical hook events only**: Generated hook suggestions MUST use `PreToolUse`/`PostToolUse`/`InstructionsLoaded`. Never invent event names.
- **Path-scoped rules**: Rule files have YAML frontmatter with `paths:` targeting specific modules (unless project has <3 modules, then always-on).
- **Progressive disclosure**: Generated skills over 30 lines split into `SKILL.md` + `references/`. The setup skill itself follows this rule (core `SKILL.md` + 3 references files).
- **Rule files under 50 lines**; **CLAUDE.md under 200 lines** — flagged as bloat above the threshold.
- **Hooks are suggestions only**: Never auto-writes to `.claude/settings.json`.
- **No token drift**: Every `{{TOKEN}}` in templates must be registered in `tests/validate-tokens.sh` and documented in `skills/setup/references/templates.md`. Run the validator after any template edit.

## File Map

| Path | Purpose |
|---|---|
| `.claude-plugin/plugin.json` | Plugin manifest (name, version, metadata) |
| `agents/project-analyzer.md` | Deep codebase analysis agent — returns structured JSON |
| `skills/setup/SKILL.md` | Main orchestrator (pipeline, flags, rules) |
| `skills/setup/references/audit.md` | `--audit` mode health checks + output format |
| `skills/setup/references/dry-run.md` | `--dry-run` mode behavior + output format |
| `skills/setup/references/templates.md` | Template selection tables, token reference, command values |
| `tests/validate-tokens.sh` | Token substitution validator — run after template edits |
| `templates/rules/{python,typescript,go,rust,generic}.md` | Language rule templates |
| `templates/rules/database-{postgresql,mongodb,redis}.md` | Database rule templates |
| `templates/rules/framework-{fastapi,django,express,nextjs-approuter}.md` | Framework rule templates |
| `templates/rules/infra.md` | Dockerfile/k8s/Helm/Terraform rules |
| `templates/rules/ci.md` | GitHub Actions/GitLab/CircleCI/Jenkins rules |
| `templates/skills/{run-tests,lint,format-check,typecheck,audit}.md` | Skill templates |
| `templates/agents/{security-reviewer,api-tester,db-reviewer,refactor-reviewer}.md` | Subagent templates |
| `templates/claude-md/{python,typescript,go,generic}.md` | CLAUDE.md starter templates |
| `templates/hooks/sharp-edge-hooks.md` | Canonical `PreToolUse`/`PostToolUse`/`InstructionsLoaded` hook configs |

## Supported Stacks

**Languages**: Python, TypeScript/JavaScript, Go, Rust, generic fallback.
**Frameworks**: FastAPI, Django, Express, Next.js App Router. Framework rules append to language-wide rule files.
**Databases**: PostgreSQL, MongoDB, Redis. Substituted into `{{DATABASE_RULES}}`.
**Infrastructure**: Dockerfile, docker-compose, Kubernetes, Helm, Terraform — `infra.md` path-scoped rule.
**CI/CD**: GitHub Actions, GitLab CI, CircleCI, Azure Pipelines, Jenkins — `ci.md` path-scoped rule.
**Monorepos**: pnpm, npm/yarn workspaces, Lerna, Go workspaces, Cargo workspaces, Nx. Each package becomes a module with per-language rules.

## Structure Score Rubric

The plugin scores projects 0-100:

| Component | Points |
|---|---|
| CLAUDE.md exists and <200 lines | 20 |
| `.claude/rules/` coverage (rules / modules × 30) | 30 |
| At least 1 project-specific skill | 20 |
| Sharp edges documented in rules | 15 |
| Test framework detectable | 15 |

## Development Workflow for This Plugin

- **Template edits**: run `bash tests/validate-tokens.sh` afterward. Fails if any token is unknown, orphaned, or undocumented.
- **New tokens**: register in `tests/validate-tokens.sh` AND document in `skills/setup/references/templates.md`.
- **Hook template changes**: verify against <https://code.claude.com/docs/en/hooks>. Never use invented event names.
- **Commit style**: conventional commits (`feat(x):`, `fix(y):`, `docs(z):`, `test(w):`). Separate commits per spec-workflow feature so review and rollback stay clean.
- **Size budgets**: `skills/setup/SKILL.md` should stay under 500 lines per Anthropic's skill guidance. If growing past it, extract into `references/`.
