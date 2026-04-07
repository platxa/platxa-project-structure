---
description: Analyze any codebase and auto-generate Claude Code project structure (.claude/rules, skills, CLAUDE.md). Run this on any project to get path-scoped rules, project-specific skills, and an optimized CLAUDE.md.
---

# Project Structure Setup

Analyze the current project and generate a complete Claude Code project structure: path-scoped rules in `.claude/rules/`, project-specific skills in `.claude/skills/`, domain-matched subagents in `.claude/agents/`, an optimized `CLAUDE.md`, and copy-paste-ready hook suggestions.

## Flags

| Flag | Effect |
|------|--------|
| `--audit` | Analyze existing rules for staleness — see @references/audit.md |
| `--dry-run` | Show what would be created without writing any files — see @references/dry-run.md |

## Execution Protocol

### Step 1: Analyze the Project

Dispatch the **project-analyzer** agent to deeply analyze the codebase:

```
Agent tool:
  subagent_type: "platxa-project-structure:project-analyzer"
  description: "Analyze project structure"
  prompt: "Analyze the current project at [CWD]. Detect tech stack, modules, complexity, sharp edges, and existing Claude Code structure. Return the full JSON report."
```

Wait for the analysis report. Save it as the `analysis` variable.

### Step 2: Calculate Before Score

Score the project 0-100 based on existing structure:

| Component | Points | Criteria |
|-----------|--------|----------|
| CLAUDE.md | 20 | Exists and under 200 lines |
| .claude/rules/ | 30 | Prorated by module coverage (rules / total modules * 30) |
| .claude/skills/ | 20 | Has at least 1 project-specific skill |
| Sharp edge docs | 15 | Sharp edges are documented in rules |
| Test framework | 15 | Test framework is detectable |

### Step 3: Generate .claude/rules/ Files

For each module detected by the analyzer, generate a path-scoped rule file. See @references/templates.md for the language template selection table, framework append rules, database substitution map, and the full token reference.

**Activation mode selection** — choose path-scoped vs always-on based on project size:

| Condition | Mode | Frontmatter |
|-----------|------|-------------|
| Total modules < 3 | Always-on | No `paths:` frontmatter — rule loads every session |
| Total modules >= 3 | Path-scoped | Include `paths:` frontmatter targeting the module's files |
| Monorepo (any size) | Path-scoped | Always path-scoped — monorepos have too many files for always-on |

Log the activation mode decision in the final report:

```
Activation mode: path-scoped (5 modules detected)
```

When generating in **always-on mode**, strip the `paths:` YAML frontmatter from the template output. The rule content stays the same; only the scoping changes.

**Monorepo handling**: If `monorepo.detected` is true, each workspace package is a module. Use the full relative path from the repo root (e.g., `packages/frontend`) as `{{MODULE_PATH}}`. For monorepos with mixed languages (e.g., TypeScript frontend + Python API), select the template matching **each package's language**, not the project-wide primary language.

For each module:

1. Select the language template per the table in @references/templates.md
2. Substitute all template tokens per the token map in @references/templates.md
3. Format sharp edges as a markdown list under a `## Sharp Edges` heading
4. Write to `.claude/rules/{module_name}.md` — **NEVER overwrite** existing files (skip with a message)
5. Also generate a language-wide rule file (e.g., `.claude/rules/python.md` for all `*.py`)
6. **Framework append**: if a framework is detected, append the matching framework template content to the language-wide rule file (do not replace)

### Step 4: Generate .claude/skills/ Files

For each applicable skill template:

**Progressive disclosure**: If a generated skill would exceed 30 lines, split it:

- **SKILL.md** (core): Keep the description, main command, and essential instructions (under 30 lines)
- **references/**: Move detailed documentation, examples, and edge cases into separate files
- Link from SKILL.md using `@references/FILENAME.md` imports

Example split structure:

```
.claude/skills/run-tests/
├── SKILL.md              ← Core instructions (under 30 lines)
└── references/
    └── test-patterns.md  ← Detailed test patterns, fixtures, edge cases
```

Generate these skills when the corresponding tool is detected:

| Skill | Trigger | Tokens |
|---|---|---|
| `run-tests` | Test framework detected | `{{TEST_FRAMEWORK}}`, `{{TEST_COMMAND}}` |
| `lint` | Linter detected | `{{LINT_COMMAND}}`, `{{LINT_FIX_COMMAND}}` |
| `format-check` | Formatter detected | `{{FORMATTER}}`, `{{FORMAT_CHECK_COMMAND}}`, `{{FORMAT_FIX_COMMAND}}` |
| `typecheck` | Type checker detected | `{{TYPE_CHECKER}}`, `{{TYPE_CHECK_COMMAND}}` |

See @references/templates.md for common command values per language.

Skip existing files — never overwrite.

### Step 5: Generate .claude/agents/ Files

Generate domain-matched subagents based on detected modules and databases. The full pattern → template mapping is in @references/templates.md.

For each matched agent:

1. Select the template from `templates/agents/`
2. Substitute `{{MODULE_NAME}}` and `{{MODULE_PATH}}` with the matching module
3. Write to `.claude/agents/{agent-name}.md`
4. **NEVER overwrite** existing files — skip with a message

If no modules match any domain pattern and `databases[]` is empty, skip this step entirely.

### Step 6: Audit or Generate CLAUDE.md

**If CLAUDE.md exists:**

- Count lines
- If >200 lines: report as bloated with suggestions to trim
- If well-structured: report as good, no changes needed
- **NEVER modify** an existing CLAUDE.md — only report

**If CLAUDE.md does NOT exist:**

- Select the template matching the project's primary language from `templates/claude-md/`
- Substitute tokens from analysis
- For `{{ARCHITECTURE_SUMMARY}}`, generate a brief description of the project's module structure
- **@import handling**: The templates include `@README`, `@package.json`, `@pyproject.toml`, or `@go.mod` imports. Before writing, verify the referenced file exists. If it does NOT exist, remove that `@import` line from the output. Never generate imports pointing to non-existent files.
- Write to `CLAUDE.md`

### Step 7: Generate Hook Suggestions

Analyze the sharp edges from the analysis report and generate concrete hook suggestions. Reference `templates/hooks/sharp-edge-hooks.md` for the canonical pattern-to-hook mapping (uses real Claude Code event names: `PreToolUse`, `PostToolUse`, `InstructionsLoaded`).

**For each sharp edge**, match the pattern to a hook config from the template:

| Sharp Edge Pattern | Event |
|--------------------|-------|
| `shell=True`, `exec(`, `eval(` | `PostToolUse` (warn) |
| Hardcoded credentials | `PreToolUse` on `Bash(git commit*)` (block) |
| f-string SQL | `PostToolUse` (warn) |
| `dangerouslySetInnerHTML` | `PostToolUse` (warn) |

**Always suggest these baseline hooks** (regardless of sharp edges):

1. **Lint on edit** — if linter detected, suggest a `PostToolUse` hook running `{{LINT_COMMAND}}` on source-file edits
2. **Block sensitive dirs** — if migrations/, secrets/, or .env files exist, suggest a `PreToolUse` hook blocking edits
3. **InstructionsLoaded debug hook** — always suggest the diagnostic hook from `templates/hooks/sharp-edge-hooks.md` so users can debug which path-scoped rules are firing for which file reads (this is the canonical debug path per the Claude Code memory docs)

**Output format**: Print each hook config as a JSON snippet the user can copy into `.claude/settings.json`. Use the canonical Claude Code shape:

```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Edit|Write|MultiEdit",
        "hooks": [
          {
            "type": "command",
            "if": "Edit(**/*.py)",
            "command": "{{LINT_COMMAND}}"
          }
        ]
      }
    ]
  }
}
```

**Do NOT write to `.claude/settings.json`** — only suggest in the report. The user must review and apply hooks manually.

### Step 8: Calculate After Score & Report

Calculate the new score using the same rubric. Print a structured report:

```
+======================================================================+
|  PROJECT STRUCTURE SETUP COMPLETE                                    |
+======================================================================+

Project: {{project_name}}
Stack:   {{language}} + {{framework}} | {{test_framework}} | {{linter}}

Score:   {{before_score}}% → {{after_score}}% (+{{delta}}%)

Files created:
  ✓ .claude/rules/retrieval.md        (paths: src/retrieval/**)
  ✓ .claude/rules/python.md           (paths: **/*.py)
  ✓ .claude/skills/run-tests/SKILL.md (pytest -v)
  ⊘ CLAUDE.md                         (already exists, 160 lines — OK)

Skipped (already exist):
  ⊘ .claude/rules/config.md

Sharp edges documented:
  ⚠ connectors/ssh_tunnel.py:42 — shell=True
  ⚠ config/settings.py:29 — hardcoded password

Suggested hooks (add to .claude/settings.json):
  🔧 PostToolUse: Run ruff check on **/*.py edits
  🔧 PostToolUse: Warn on shell=True in connectors/**
  🔧 PreToolUse: Block hardcoded credentials on git commit
  🔧 PreToolUse: Block writes to **/migrations/**
  🔧 InstructionsLoaded: Log loaded rule files for debugging

  Copy-paste config: see templates/hooks/sharp-edge-hooks.md

Next steps:
  1. Review generated files and customize as needed
  2. Review suggested hooks and add to .claude/settings.json
  3. Commit .claude/ directory to version control
  4. Run /platxa-project-structure:setup again after major refactors
```

## Important Rules

1. **Non-destructive**: NEVER overwrite existing files. Skip and report.
2. **Accurate**: Use exact numbers from analysis, never estimate.
3. **Practical**: Generated rules should reference actual tools in the project.
4. **Concise**: Each rule file should be under 50 lines.
5. **Path-scoped**: Every rule file MUST have YAML frontmatter with `paths:` targeting the specific module (unless project has <3 modules — see Step 3).
6. **Canonical hook events**: Generated hook suggestions MUST use real Claude Code event names (`PreToolUse`, `PostToolUse`, `InstructionsLoaded`) — never invent event names.

## Reference Material

- @references/dry-run.md — `--dry-run` mode behavior and output format
- @references/audit.md — `--audit` mode health checks and output format
- @references/templates.md — template selection tables, token reference, common command values
