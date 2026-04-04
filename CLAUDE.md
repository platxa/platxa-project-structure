# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Is

A Claude Code **plugin** that auto-generates project structure (`.claude/rules/`, `.claude/skills/`, `CLAUDE.md`) for any codebase. The user runs `/platxa-project-structure:setup` on their project, and the plugin analyzes the codebase, detects the tech stack, identifies sharp edges, and scaffolds path-scoped rules + skills.

## Plugin Architecture

The plugin has three layers that execute in sequence:

1. **Agent** (`agents/project-analyzer.md`) — Dispatched first. Runs bash commands to detect language, framework, test runner, linter, databases, module structure, and dangerous patterns. Returns a structured JSON report.
2. **Templates** (`templates/`) — Parameterized markdown files with `{{TOKEN}}` placeholders. The setup skill selects the right template based on detected language and substitutes tokens from the analyzer report.
3. **Skill** (`skills/setup/SKILL.md`) — The main orchestrator. Dispatches the analyzer agent, iterates modules, generates files from templates, calculates a structure score (0-100), and prints the final report.

### Template Token System

All templates use `{{DOUBLE_BRACE}}` tokens. Common tokens: `{{MODULE_NAME}}`, `{{MODULE_PATH}}`, `{{TEST_COMMAND}}`, `{{LINT_COMMAND}}`, `{{SHARP_EDGES}}`, `{{DATABASE_RULES}}`. Templates must never have un-substituted tokens in output.

### Key Design Constraints

- **Non-destructive**: The plugin NEVER overwrites existing files. If a target file exists, it skips and reports. Re-running is always safe.
- **Path-scoped rules**: Every generated rule file MUST have YAML frontmatter with `paths:` targeting the specific module (e.g., `paths: ["src/auth/**/*.py"]`).
- **Rule files under 50 lines**: Generated rules should be concise.
- **CLAUDE.md under 200 lines**: Generated CLAUDE.md files flag bloat above this threshold.

## File Map

| Path | Purpose |
|------|---------|
| `.claude-plugin/plugin.json` | Plugin manifest (name, version, metadata) |
| `agents/project-analyzer.md` | Analysis agent — detects stack, modules, sharp edges |
| `skills/setup/SKILL.md` | Main orchestrator skill (`/platxa-project-structure:setup`) |
| `templates/rules/{lang}.md` | Rule templates per language (python, typescript, go, rust, generic) |
| `templates/skills/*.md` | Skill templates (run-tests, lint) |
| `templates/claude-md/{lang}.md` | CLAUDE.md starter templates per language |
| `.claude/generated_features.json` | Feature spec tracking (21 features, used for development) |

## Supported Languages

Python, TypeScript/JavaScript, Go, Rust, and a generic fallback. Each has a dedicated rule template and CLAUDE.md template. The analyzer detects the stack from manifest files (`pyproject.toml`, `package.json`, `go.mod`, `Cargo.toml`).

## Structure Score Rubric

The plugin scores projects 0-100:

| Component | Points |
|-----------|--------|
| CLAUDE.md exists and <200 lines | 20 |
| .claude/rules/ coverage (rules / modules * 30) | 30 |
| At least 1 project-specific skill | 20 |
| Sharp edges documented in rules | 15 |
| Test framework detectable | 15 |
