# platxa-project-structure

Claude Code plugin that auto-generates the optimal project structure for any codebase.

## What It Does

Run one command on any project:

```
/platxa-project-structure:setup
```

The plugin:

1. **Detects** your tech stack (language, framework, test runner, linter, databases)
2. **Analyzes** every module (file count, LOC, complexity score)
3. **Finds** sharp edges (dangerous patterns, security risks, high TODO density)
4. **Generates** `.claude/rules/` with path-scoped rules per module
5. **Creates** project-specific skills (`run-tests`, `lint`)
6. **Audits** existing CLAUDE.md (flags bloat >200 lines) or generates one
7. **Reports** a before/after structure score (0-100%)

## Install

```bash
claude plugin add github:platxa/platxa-project-structure
```

## Usage

Navigate to any project and run:

```
/platxa-project-structure:setup
```

Example output:

```
+======================================================================+
|  PROJECT STRUCTURE SETUP COMPLETE                                    |
+======================================================================+

Project: my-api
Stack:   Python + FastAPI | pytest | ruff

Score:   15% → 87% (+72%)

Files created:
  ✓ .claude/rules/api.md              (paths: src/api/**)
  ✓ .claude/rules/auth.md             (paths: src/auth/**)
  ✓ .claude/rules/python.md           (paths: **/*.py)
  ✓ .claude/skills/run-tests/SKILL.md (pytest -v)
  ✓ .claude/skills/lint/SKILL.md      (ruff check --fix)
  ✓ CLAUDE.md                         (generated — 45 lines)
```

## Supported Languages

| Language | Framework Detection | Rule Template | Linter/Formatter |
|----------|-------------------|---------------|-----------------|
| Python | FastAPI, Django, Flask | ruff, pyright, pytest | Yes |
| TypeScript | Next.js, Express, Nest | eslint, tsc, jest/vitest | Yes |
| Go | Gin, Echo, stdlib | go vet, staticcheck | Yes |
| Rust | Actix, Tokio, Axum | clippy, cargo test | Yes |
| Other | Generic detection | Generic rules | Best-effort |

## Non-Destructive Guarantee

The plugin **never overwrites** existing files. If `.claude/rules/api.md` already exists, it skips it and reports. Re-running is always safe.

## What Gets Created

```
your-project/
├── CLAUDE.md                    ← Generated if missing (audited if exists)
└── .claude/
    ├── rules/
    │   ├── api.md               ← paths: src/api/**/*.py
    │   ├── auth.md              ← paths: src/auth/**/*.py
    │   ├── database.md          ← paths: src/database/**/*.py
    │   └── python.md            ← paths: **/*.py (language-wide)
    └── skills/
        ├── run-tests/
        │   └── SKILL.md         ← pytest -v
        └── lint/
            └── SKILL.md         ← ruff check --fix .
```

## How Rules Work

Each rule file uses [path-scoped YAML frontmatter](https://code.claude.com/docs/en/memory#path-specific-rules) so it only loads when Claude touches files in that module:

```markdown
---
paths:
  - "src/auth/**/*.py"
---

# Auth Module Rules

- Never store passwords in plain text
- Always use bcrypt for hashing
- JWT tokens must have expiry < 1 hour

## Sharp Edges
- **hardcoded secret** at `config.py:42` — use environment variable
```

## Philosophy

> Prompting is temporary. Structure is permanent.

This plugin implements the [Claude Code Project Structure](https://code.claude.com/docs/en/memory) best practices:

- **CLAUDE.md** = Repo memory (under 200 lines)
- **.claude/rules/** = Path-scoped module guardrails
- **.claude/skills/** = Reusable project workflows
- **Non-destructive** = Safe to re-run anytime

## License

MIT

---
*Made with care by DJ Patel | [Platxa](https://github.com/platxa)*
