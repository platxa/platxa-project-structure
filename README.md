# platxa-project-structure

Claude Code plugin that auto-generates the optimal project structure for any codebase.

## What It Does

Run one command on any project:

```
/platxa-project-structure:setup
```

The plugin:

1. **Preflights** — warns about ancestor and managed-policy `CLAUDE.md` files that will load alongside what it generates
2. **Detects** your tech stack (language, framework, test runner, linter, databases, infrastructure-as-code, CI/CD)
3. **Detects** monorepo patterns (pnpm, npm, yarn workspaces, Go workspaces, Cargo, Lerna, Nx)
4. **Analyzes** every module (file count, LOC, complexity score)
5. **Finds** sharp edges (dangerous patterns, security risks, high TODO density)
6. **Generates** `.claude/rules/` with path-scoped rules per module, plus `infra.md` and `ci.md` when applicable
7. **Generates** `.claude/skills/` for run-tests, lint, format-check, typecheck, and audit — with `allowed-tools`, `paths:` scoping, and `disable-model-invocation` on mutating skills
8. **Generates** `.claude/agents/` with domain-matched subagents (security, API, database) and a complexity-triggered `refactor-reviewer` for L/XL modules
9. **Audits** existing CLAUDE.md (flags bloat >200 lines) or generates one with bare `@import` references
10. **Suggests** hooks using canonical Claude Code events (`PreToolUse`, `PostToolUse`, `InstructionsLoaded`) — never invented event names
11. **Reports** a before/after structure score (0-100%)

## Install

```bash
claude plugin add github:platxa/platxa-project-structure
```

## Usage

Navigate to any project and run:

```
/platxa-project-structure:setup
```

### Flags

| Flag | Description |
|------|-------------|
| *(none)* | Full setup — analyze and generate everything |
| `--dry-run` | Preview what would be created without writing any files |
| `--audit` | Health-check existing `.claude/` structure for stale rules, dead globs, and gaps |
| `--update` | Fill only missing slots; never touch present files (safer than re-run) |
| `--with-local` | Also generate a gitignored `CLAUDE.local.md` for personal preferences |
| `--seed-memory` | Print a starter `MEMORY.md` template for machine-local auto memory |

### Example Output

```
+======================================================================+
|  PROJECT STRUCTURE SETUP COMPLETE                                    |
+======================================================================+

Project: my-api
Stack:   Python + FastAPI | pytest | ruff

Activation mode: path-scoped (5 modules detected)

Score:   15% → 87% (+72%)

Files created:
  ✓ .claude/rules/api.md              (paths: src/api/**)
  ✓ .claude/rules/auth.md             (paths: src/auth/**)
  ✓ .claude/rules/python.md           (paths: **/*.py)
  ✓ .claude/skills/run-tests/SKILL.md (pytest -v)
  ✓ .claude/skills/lint/SKILL.md      (ruff check --fix)
  ✓ .claude/skills/format-check/SKILL.md (ruff format)
  ✓ .claude/skills/typecheck/SKILL.md (pyright)
  ✓ .claude/agents/security-reviewer.md
  ✓ .claude/agents/db-reviewer.md
  ⊘ CLAUDE.md                         (already exists, 85 lines — OK)

Skipped (already exist):
  ⊘ .claude/rules/config.md

Sharp edges documented:
  ⚠ connectors/ssh_tunnel.py:42 — shell=True
  ⚠ config/settings.py:29 — hardcoded password

Suggested hooks (add to .claude/settings.json):
  🔧 PostToolUse:          Run ruff check on **/*.py edits
  🔧 PostToolUse:          Warn on shell=True in connectors/**
  🔧 PreToolUse:           Block hardcoded credentials on git commit
  🔧 PreToolUse:           Block writes to **/migrations/**
  🔧 InstructionsLoaded:   Log loaded rule files for debugging

Next steps:
  1. Review generated files and customize as needed
  2. Review suggested hooks and add to .claude/settings.json
  3. Commit .claude/ directory to version control
  4. Run /platxa-project-structure:setup again after major refactors
```

## Supported Languages

| Language | Framework Detection | Rule Template | Database Rules | Agent Generation |
|----------|-------------------|---------------|----------------|-----------------|
| Python | FastAPI, Django, Flask | ✓ | PostgreSQL, MongoDB, Redis | ✓ |
| TypeScript | Next.js (App Router/Pages), Express, NestJS | ✓ | PostgreSQL, MongoDB, Redis | ✓ |
| Go | Gin, Echo, stdlib | ✓ | — | ✓ |
| Rust | Actix, Tokio, Axum | ✓ | — | ✓ |
| Other | Generic detection | ✓ | — | ✓ |

## Monorepo Support

The plugin detects and handles monorepos automatically:

| Workspace Tool | Detection |
|---------------|-----------|
| pnpm | `pnpm-workspace.yaml` |
| npm/yarn | `workspaces` in `package.json` |
| Lerna | `lerna.json` |
| Go | `go.work` or multiple `go.mod` files |
| Cargo | `[workspace]` in `Cargo.toml` |
| Nx | `nx.json` |

Each workspace package becomes a separate module with its own rule file. Mixed-language monorepos (e.g., TypeScript frontend + Python API) get language-specific rules per package.

## Non-Destructive Guarantee

The plugin **never overwrites** existing files. If `.claude/rules/api.md` already exists, it skips it and reports. Re-running is always safe.

## What Gets Created

```
your-project/
├── CLAUDE.md                         ← Generated if missing (audited if exists)
├── CLAUDE.local.md                   ← Optional (--with-local), gitignored
└── .claude/
    ├── rules/
    │   ├── api.md                    ← paths: src/api/**/*.py
    │   ├── auth.md                   ← paths: src/auth/**/*.py
    │   ├── database.md               ← paths: src/database/**/*.py
    │   ├── python.md                 ← paths: **/*.py (language-wide + framework rules)
    │   ├── infra.md                  ← paths: Dockerfile, k8s/**, *.tf (if detected)
    │   └── ci.md                     ← paths: .github/workflows/**, etc (if detected)
    ├── skills/
    │   ├── run-tests/
    │   │   └── SKILL.md              ← pytest -v        (auto-invocable)
    │   ├── lint/
    │   │   └── SKILL.md              ← ruff check --fix (user-only — side effects)
    │   ├── format-check/
    │   │   └── SKILL.md              ← ruff format      (user-only — side effects)
    │   ├── typecheck/
    │   │   └── SKILL.md              ← pyright .        (auto-invocable)
    │   └── audit/
    │       └── SKILL.md              ← /audit shortcut for --audit mode
    └── agents/
        ├── security-reviewer.md      ← Generated if auth module detected
        ├── api-tester.md             ← Generated if API module detected
        ├── db-reviewer.md            ← Generated if database module detected
        └── refactor-reviewer.md      ← Generated if any module is L/XL complexity
```

Every generated skill has canonical Claude Code frontmatter: `name`, `description`, `allowed-tools`, `paths:` for language-scoped activation, and `disable-model-invocation: true` on the two mutating skills (`lint`, `format-check`) so Claude can't auto-trigger file rewrites.

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

For small projects (fewer than 3 modules), rules are generated without `paths:` frontmatter so they load every session.

## How Hooks Work

The plugin analyzes sharp edges and suggests hooks using **canonical Claude Code hook events** — `PreToolUse`, `PostToolUse`, `InstructionsLoaded` — per <https://code.claude.com/docs/en/hooks>. Hook configs are emitted in the correct `hooks.{Event}[].matcher + hooks[]` shape with `if:` permission rule syntax. Hooks are **suggested only**, never auto-written.

| Sharp Edge | Event | Semantics |
|---|---|---|
| `shell=True`, `eval()`, `exec()` | `PostToolUse` | Warn after edit (non-blocking) |
| Hardcoded credentials | `PreToolUse` on `Bash(git commit*)` | **Block** via exit code 2 |
| f-string SQL injection | `PostToolUse` | Warn after edit |
| `dangerouslySetInnerHTML` | `PostToolUse` | Warn after edit |
| Linter detected | `PostToolUse` | Run lint; pipes output back via `additionalContext` |
| Migrations/secrets directories | `PreToolUse` on `Edit\|Write` | **Block** via exit code 2 |
| *(debug)* Rule load tracing | `InstructionsLoaded` | Log which CLAUDE.md/rules loaded and why |

The baseline `InstructionsLoaded` diagnostic hook is always suggested — it's the canonical debug path for path-scoped rule troubleshooting per the Claude Code memory docs.

## Audit Mode

Run `--audit` to health-check existing rules:

```
/platxa-project-structure:setup --audit
```

Checks for:

- Modules with no rule coverage
- Rules referencing deleted files or **dead globs** (zero-match — verified via the `Glob` tool)
- Bloated rule files (>50 lines) or CLAUDE.md (>200 lines)
- Skills referencing missing commands

Audit never modifies files — it only reports. You decide what to fix.

## Update Mode

Run `--update` for a non-destructive refresh after adding a new module or upgrading the plugin:

```
/platxa-project-structure:setup --update
```

Fills only the missing slots. Every existing file is left untouched. Safer than delete-and-rerun, sharper than the default (which also skips existing files but runs the full generation plan).

## Testing

A Bash-based token validator guards against template drift:

```bash
bash tests/validate-tokens.sh
```

It enumerates every `{{TOKEN}}` used in `templates/`, `skills/`, and `agents/`, then asserts:

1. Every used token is in the `ALLOWED_TOKENS` registry
2. Every allowed token is actually used (no orphans)
3. Every used token is documented in `skills/setup/references/templates.md`
4. Direct-mapped tokens have their source field in `agents/project-analyzer.md`'s output schema

Run it after any template edit. Exits non-zero on any mismatch.

## Mapping to Claude Code Primitives

This plugin exclusively emits official [Claude Code](https://code.claude.com/docs/en/memory) primitives — nothing invented, nothing proprietary. Use this table to understand what each generated file is and how Claude consumes it:

| Plugin output | Claude Code primitive | Docs | Loading behavior |
|---|---|---|---|
| `CLAUDE.md` (generated if missing) | [Project memory](https://code.claude.com/docs/en/memory#claude-md-files) | `/en/memory` | Loaded in full, every session, walking up the directory tree |
| `.claude/rules/{module}.md` with `paths:` frontmatter | [Path-scoped rules](https://code.claude.com/docs/en/memory#path-specific-rules) | `/en/memory` | Just-in-time: triggers when Claude reads a matching file |
| `.claude/rules/{module}.md` without `paths:` (small projects) | [Unconditional rules](https://code.claude.com/docs/en/memory#organize-rules-with-claude-rules) | `/en/memory` | Loaded every session, same priority as `.claude/CLAUDE.md` |
| `.claude/skills/{name}/SKILL.md` with `description` + `paths` + `allowed-tools` | [Agent Skills](https://code.claude.com/docs/en/skills) | `/en/skills` | Description in context; body loads on invoke or when relevant |
| `.claude/skills/{name}/` with `disable-model-invocation: true` | User-only skill | `/en/skills#control-who-invokes-a-skill` | Hidden from Claude; must be invoked via `/skill-name` |
| `.claude/agents/{domain}.md` | [Subagent](https://code.claude.com/docs/en/sub-agents) | `/en/sub-agents` | Isolated context window when delegated |
| Suggested `hooks.{PreToolUse,PostToolUse,InstructionsLoaded}` in settings.json | [Hooks](https://code.claude.com/docs/en/hooks) | `/en/hooks` | Fire on lifecycle events; `PreToolUse` exit 2 blocks tools |
| `@import` references inside generated CLAUDE.md | [Memory imports](https://code.claude.com/docs/en/memory#import-additional-files) | `/en/memory` | Expanded at launch, max 5-hop recursion |

What the plugin does **not** touch:

- **Auto memory** (`~/.claude/projects/<repo>/memory/MEMORY.md`) — machine-local, written by Claude itself across sessions. Coexists with the rules this plugin generates. See [`/en/memory#auto-memory`](https://code.claude.com/docs/en/memory#auto-memory).
- **User-level config** (`~/.claude/`) — personal preferences are yours to maintain.
- **Managed policy** (`/etc/claude-code/CLAUDE.md`) — organization-level settings deployed by IT.

## Philosophy

> Prompting is temporary. Structure is permanent.

This plugin implements the [Claude Code Project Structure](https://code.claude.com/docs/en/memory) best practices:

- **CLAUDE.md** = Repo memory (under 200 lines, with `@import` references)
- **.claude/rules/** = Path-scoped module guardrails
- **.claude/skills/** = Reusable project workflows (with progressive disclosure)
- **.claude/agents/** = Domain-specific subagents
- **Hooks** = Deterministic enforcement for critical patterns (canonical `PreToolUse`/`PostToolUse`/`InstructionsLoaded` events)
- **Non-destructive** = Safe to re-run anytime

## License

MIT

---
*Made with care by DJ Patel | [Platxa](https://github.com/platxa)*
