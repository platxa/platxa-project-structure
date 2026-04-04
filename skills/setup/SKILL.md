---
description: Analyze any codebase and auto-generate Claude Code project structure (.claude/rules, skills, CLAUDE.md). Run this on any project to get path-scoped rules, project-specific skills, and an optimized CLAUDE.md.
---

# Project Structure Setup

Analyze the current project and generate a complete Claude Code project structure.

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

For each module detected by the analyzer:

**Monorepo handling**: If `monorepo.detected` is true, each workspace package is a module. Use the full relative path from the repo root (e.g., `packages/frontend`) as `{{MODULE_PATH}}`. For monorepos with mixed languages (e.g., TypeScript frontend + Python API), select the template matching **each package's language**, not the project-wide primary language.

1. Select the template matching the module's language:
   - Python → `templates/rules/python.md`
   - TypeScript/JavaScript → `templates/rules/typescript.md`
   - Go → `templates/rules/go.md`
   - Rust → `templates/rules/rust.md`
   - Other → `templates/rules/generic.md`

2. Substitute all template tokens:
   - `{{MODULE_NAME}}` → module name (capitalized)
   - `{{MODULE_PATH}}` → relative path to module (for monorepos: full path from repo root, e.g., `packages/api`)
   - `{{FILE_COUNT}}` → number of files
   - `{{LINE_COUNT}}` → lines of code
   - `{{COMPLEXITY}}` → S/M/L/XL
   - `{{TEST_COMMAND}}` → detected test command
   - `{{LINT_COMMAND}}` → detected lint command
   - `{{LINTER}}` → linter name
   - `{{TYPE_CHECKER}}` → type checker name
   - `{{FORMATTER}}` → formatter name
   - `{{TEST_FRAMEWORK}}` → test framework name
   - `{{DATABASE_RULES}}` → database-specific rules (if databases detected)
   - `{{SHARP_EDGES}}` → formatted sharp edge findings for this module

3. Format sharp edges as:
   ```markdown
   ## Sharp Edges
   - **shell=True** at `ssh_tunnel.py:42` — potential command injection risk
   - **hardcoded password** at `settings.py:29` — use environment variables instead
   ```

4. Write to `.claude/rules/{module_name}.md`
   - **NEVER overwrite** existing files — skip with a message

5. Also generate a language-wide rule file (e.g., `.claude/rules/python.md` for all *.py files)

### Step 4: Generate .claude/skills/ Files

For each applicable skill template:

1. **run-tests** (always, if test framework detected):
   - Substitute `{{TEST_FRAMEWORK}}` and `{{TEST_COMMAND}}`
   - Write to `.claude/skills/run-tests/SKILL.md`

2. **lint** (if linter detected):
   - Substitute `{{LINT_COMMAND}}` and `{{LINT_FIX_COMMAND}}`
   - Write to `.claude/skills/lint/SKILL.md`

Skip existing files — never overwrite.

### Step 5: Audit or Generate CLAUDE.md

**If CLAUDE.md exists:**
- Count lines
- If >200 lines: report as bloated with suggestions to trim
- If well-structured: report as good, no changes needed
- **NEVER modify** an existing CLAUDE.md — only report

**If CLAUDE.md does NOT exist:**
- Select template matching the project's language
- Substitute tokens from analysis
- For `{{ARCHITECTURE_SUMMARY}}`, generate a brief description of the project's module structure
- Write to `CLAUDE.md`

### Step 6: Generate Hook Suggestions

Analyze the sharp edges from the analysis report and generate concrete hook suggestions. Reference `templates/hooks/sharp-edge-hooks.md` for the pattern-to-hook mapping.

**For each sharp edge**, match the pattern to a hook type:

| Sharp Edge Pattern | Hook Type | Event |
|--------------------|-----------|-------|
| `shell=True`, `exec(`, `eval(` | Warn on edit | `on_file_edit` |
| Hardcoded credentials | Block on commit | `pre_commit` |
| f-string SQL (`f"...SELECT`) | Warn on edit | `on_file_edit` |
| `dangerouslySetInnerHTML` | Warn on edit | `on_file_edit` |

**Always suggest these baseline hooks** (regardless of sharp edges):

1. **Lint on edit** — if linter detected, suggest running `{{LINT_COMMAND}}` on file edit for source files
2. **Block sensitive dirs** — if migrations/, secrets/, or .env files exist, suggest blocking writes

**Output format**: Generate a JSON array of hook configs that the user can copy into `.claude/settings.json`:

```json
{
  "hooks": {
    "on_file_edit": [
      {
        "pattern": "**/*.py",
        "command": "{{LINT_COMMAND}}"
      }
    ],
    "pre_commit": [
      {
        "command": "grep -rn 'password.*=[\"'\\''']' --include='*.py' . && echo 'BLOCKED: Hardcoded credentials' >&2 && exit 1 || true"
      }
    ]
  }
}
```

**Do NOT write to `.claude/settings.json`** — only suggest in the report. The user must review and apply hooks manually.

### Step 7: Calculate After Score & Report

Calculate the new score using the same rubric.

Print a structured report:

```
+======================================================================+
|  PROJECT STRUCTURE SETUP COMPLETE                                    |
+======================================================================+

Project: {{project_name}}
Stack:   {{language}} + {{framework}} | {{test_framework}} | {{linter}}

Score:   {{before_score}}% → {{after_score}}% (+{{delta}}%)

Files created:
  ✓ .claude/rules/retrieval.md        (paths: src/retrieval/**)
  ✓ .claude/rules/graph.md            (paths: src/graph/**)
  ✓ .claude/rules/python.md           (paths: **/*.py)
  ✓ .claude/skills/run-tests/SKILL.md (pytest -v)
  ✓ .claude/skills/lint/SKILL.md      (ruff check --fix)
  ⊘ CLAUDE.md                         (already exists, 160 lines — OK)

Skipped (already exist):
  ⊘ .claude/rules/config.md

Sharp edges documented:
  ⚠ connectors/ssh_tunnel.py:42 — shell=True
  ⚠ config/settings.py:29 — hardcoded password

Suggested hooks (add to .claude/settings.json):
  🔧 on_file_edit: Run ruff check on **/*.py edits
  🔧 on_file_edit: Warn on shell=True in connectors/**
  🔧 pre_commit: Block hardcoded credentials
  🔧 on_file_edit: Block writes to **/migrations/**

  Copy-paste config:
  {
    "hooks": { ... }
  }

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
5. **Path-scoped**: Every rule file MUST have YAML frontmatter with `paths:` targeting the specific module.
