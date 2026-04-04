# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Is

A Claude Code **plugin** that auto-generates project structure (`.claude/rules/`, `.claude/skills/`, `.claude/agents/`, `CLAUDE.md`, hook suggestions) for any codebase. The user runs `/platxa-project-structure:setup` on their project, and the plugin analyzes the codebase through an 8-step pipeline to scaffold everything Claude Code needs to work effectively.

## Plugin Architecture

Three layers execute in sequence:

1. **Agent** (`agents/project-analyzer.md`) — Dispatched first. Runs bash commands to detect language, framework (including variants like Next.js App Router vs Pages Router), test runner, linter, databases, monorepo patterns, module structure, sharp edges, and sensitive paths. Returns a structured JSON report with `stack`, `monorepo`, `modules`, `sharpEdges`, `sensitivePaths`, and `existingStructure` fields.

2. **Templates** (`templates/`) — Parameterized markdown files with `{{TOKEN}}` placeholders. The setup skill selects templates based on detected language, framework, and database, then substitutes tokens from the analyzer report.

3. **Skill** (`skills/setup/SKILL.md`) — The main orchestrator with an 8-step pipeline:
   1. Analyze project (dispatch agent)
   2. Calculate before score
   3. Generate `.claude/rules/` (with smart activation mode)
   4. Generate `.claude/skills/` (with progressive disclosure)
   5. Generate `.claude/agents/` (domain-matched)
   6. Audit or generate `CLAUDE.md` (with `@import` references)
   7. Generate hook suggestions
   8. Calculate after score and print report

   Also supports `--dry-run` (preview without writing) and `--audit` (health check existing rules).

### Template Token System

All templates use `{{DOUBLE_BRACE}}` tokens. Common tokens: `{{MODULE_NAME}}`, `{{MODULE_PATH}}`, `{{TEST_COMMAND}}`, `{{LINT_COMMAND}}`, `{{SHARP_EDGES}}`, `{{DATABASE_RULES}}`, `{{FORMATTER}}`, `{{TYPE_CHECKER}}`. Templates must never have un-substituted tokens in output.

### Key Design Constraints

- **Non-destructive**: NEVER overwrites existing files. Skips and reports.
- **Path-scoped rules**: Rule files have YAML frontmatter with `paths:` targeting specific modules (unless project has <3 modules, then always-on).
- **Progressive disclosure**: Skills over 30 lines split into `SKILL.md` + `references/` directory.
- **Rule files under 50 lines**: Generated rules should be concise.
- **CLAUDE.md under 200 lines**: Flags bloat above this threshold.
- **Hooks are suggestions only**: Never auto-writes to `.claude/settings.json`.

## File Map

| Path | Purpose |
|------|---------|
| `.claude-plugin/plugin.json` | Plugin manifest (name, version, metadata) |
| `agents/project-analyzer.md` | Analysis agent — 6 detection steps returning JSON |
| `skills/setup/SKILL.md` | Main orchestrator — 8-step pipeline + audit + dry-run |
| `templates/rules/{lang}.md` | Language rule templates (python, typescript, go, rust, generic) |
| `templates/rules/database-{type}.md` | Database rule templates (postgresql, mongodb, redis) |
| `templates/rules/framework-{name}.md` | Framework rule templates (fastapi, django, express, nextjs-approuter) |
| `templates/skills/*.md` | Skill templates (run-tests, lint, format-check, typecheck) |
| `templates/hooks/sharp-edge-hooks.md` | Sharp edge pattern → hook config mapping |
| `templates/agents/*.md` | Subagent templates (security-reviewer, api-tester, db-reviewer) |
| `templates/claude-md/{lang}.md` | CLAUDE.md starter templates per language |

## Supported Stacks

**Languages**: Python, TypeScript/JavaScript, Go, Rust, generic fallback.

**Frameworks**: FastAPI, Django, Express, Next.js App Router. Framework rules are appended to language-wide rule files.

**Databases**: PostgreSQL, MongoDB, Redis. Database rules substitute into `{{DATABASE_RULES}}` token.

**Monorepos**: pnpm, npm/yarn workspaces, Lerna, Go workspaces, Cargo workspaces, Nx. Each package becomes a separate module with per-language rules.

## Structure Score Rubric

The plugin scores projects 0-100:

| Component | Points |
|-----------|--------|
| CLAUDE.md exists and <200 lines | 20 |
| .claude/rules/ coverage (rules / modules * 30) | 30 |
| At least 1 project-specific skill | 20 |
| Sharp edges documented in rules | 15 |
| Test framework detectable | 15 |
