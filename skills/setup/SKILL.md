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
| `--update` | Re-run detection and fill ONLY missing slots; never modify present files — see [Update Mode](#update-mode) |
| `--with-local` | Also generate a personal `CLAUDE.local.md` (gitignored) — see [Local Memory](#local-memory) |

## Update Mode

Invoked with `--update`. Re-runs Steps 1-2 (analyze + score), then generates **only the files that do not already exist**. Every existing file is left untouched — this is the safe middle ground between blindly re-running the default setup (which skips existing files silently) and forcing a destructive rewrite (which the plugin never does).

### Behavior

- Steps 3-7 run as normal **except** the file-write policy: before every write, check whether the target path exists on disk. If it does, skip silently without comparing content.
- The final report separates outcomes into three groups: **newly created** (slot was empty), **preserved** (file already existed, left untouched), and **still missing** (would have been generated but a parent path is blocked).
- The score delta in Step 8 reflects only the newly-created files.

### When to use

- After adding a new module or workspace package, to scaffold its rule file without disturbing hand-edited rules for older modules.
- After upgrading the plugin, to pick up new baseline skills or agent templates without rewriting existing ones.
- As a periodic refresh during active development — safer than deleting `.claude/` and re-running.

### Difference from default mode

| Mode | Analyzes | Writes new files | Skips existing | Modifies existing | Shows dry report |
|---|---|---|---|---|---|
| Default | Yes | Yes | Yes (with message) | Never | No |
| `--update` | Yes | Yes (missing slots only) | Yes (silently) | Never | No |
| `--dry-run` | Yes | No | Reported | Never | Yes |
| `--audit` | Yes | No | N/A (audit reads existing) | Never | Yes (health report) |

### Output format

```
+======================================================================+
|  UPDATE MODE                                                         |
+======================================================================+

Project: my-api
Stack:   Python + FastAPI | pytest | ruff

Score:   62% → 78% (+16% from newly created files)

Newly created:
  ✓ .claude/rules/notifications.md    (new module detected)
  ✓ .claude/skills/typecheck/SKILL.md (new baseline skill)

Preserved (already exist — not touched):
  ⊘ .claude/rules/api.md
  ⊘ .claude/rules/auth.md
  ⊘ .claude/rules/python.md
  ⊘ CLAUDE.md (160 lines)

Still missing (reason):
  (none)

Run without --update to see the full generation plan.
```

## Execution Protocol

### Step 0: Preflight — Ancestor & Managed CLAUDE.md Check

Before analyzing the project, scan for **already-loaded** instruction files that could conflict with generation. Claude Code walks up the directory tree concatenating every `CLAUDE.md` and `CLAUDE.local.md`, and also loads managed-policy CLAUDE.md if one exists. The user may not be aware of these.

Run these checks in order:

1. **Managed policy CLAUDE.md**: check for a managed-policy file at the OS-specific location:
   - Linux / WSL: `/etc/claude-code/CLAUDE.md`
   - macOS: `/Library/Application Support/ClaudeCode/CLAUDE.md`
   - Windows: `C:\Program Files\ClaudeCode\CLAUDE.md`

   If found, **warn** the user that an organization-managed CLAUDE.md is active and cannot be excluded via `claudeMdExcludes`. Report its line count. Do not block generation.

2. **Ancestor CLAUDE.md files**: from `cwd`, walk up the directory tree to the filesystem root and collect every `CLAUDE.md` found in ancestor directories (not in `cwd` itself). Also collect `CLAUDE.local.md` at each level.

   If any ancestor files are found, warn the user with a list like:

   ```
   ⚠ Ancestor CLAUDE.md files detected (loaded before project CLAUDE.md):
     • /home/michael/workspace/CLAUDE.md            (120 lines)
     • /home/michael/workspace/platxa/CLAUDE.md     (85 lines)
   These will load alongside any project CLAUDE.md this plugin generates.
   ```

3. **`claudeMdExcludes` suggestion** — if the project is a monorepo AND ancestor files exceed a sensible threshold (total ancestor lines > 200, or more than 2 ancestor files), suggest a `claudeMdExcludes` stanza for `.claude/settings.local.json`:

   ```json
   {
     "claudeMdExcludes": [
       "/home/michael/workspace/CLAUDE.md",
       "/home/michael/workspace/platxa/CLAUDE.md"
     ]
   }
   ```

   This is a suggestion only — never write to `settings.local.json` automatically.

4. **User-scope CLAUDE.md** at `~/.claude/CLAUDE.md`: if present, note it in the preflight report (informational; user memory is intentional, not a warning).

Proceed to Step 1 regardless of findings. The preflight is informational and never blocks generation.

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
7. **Infrastructure rule**: if `infrastructure.docker`, `infrastructure.kubernetes`, or `infrastructure.terraform` is true in the analyzer report, also generate `.claude/rules/infra.md` from `templates/rules/infra.md`. The template has no tokens to substitute — write it verbatim. This rule is path-scoped to `**/Dockerfile`, `k8s/**/*.yml`, `**/*.tf`, etc., and only activates when Claude reads infra files. Skip if the target file already exists.
8. **CI rule**: if the analyzer report shows any of `.github/workflows/`, `.gitlab-ci.yml`, `.circleci/config.yml`, `azure-pipelines.yml`, or a `Jenkinsfile` exists, also generate `.claude/rules/ci.md` from `templates/rules/ci.md` (also verbatim). Path-scoped to CI pipeline files so it only activates when Claude reads them. Skip if the target file already exists.

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
| `run-tests` | Test framework detected | `{{TEST_FRAMEWORK}}`, `{{TEST_COMMAND}}`, `{{SOURCE_GLOB}}`, `{{TEST_GLOB}}` |
| `lint` | Linter detected | `{{LINT_COMMAND}}`, `{{LINT_FIX_COMMAND}}`, `{{SOURCE_GLOB}}` |
| `format-check` | Formatter detected | `{{FORMATTER}}`, `{{FORMAT_CHECK_COMMAND}}`, `{{FORMAT_FIX_COMMAND}}`, `{{SOURCE_GLOB}}` |
| `typecheck` | Type checker detected | `{{TYPE_CHECKER}}`, `{{TYPE_CHECK_COMMAND}}`, `{{SOURCE_GLOB}}` |

**Path-scoped activation**: Skill templates include a `paths:` frontmatter field with `{{SOURCE_GLOB}}` (and `{{TEST_GLOB}}` for run-tests). The setup skill substitutes these from the detected language so each generated skill only auto-activates when Claude is working with relevant files. Common values:

| Language | `{{SOURCE_GLOB}}` | `{{TEST_GLOB}}` |
|---|---|---|
| Python | `**/*.py` | `tests/**/*.py` |
| TypeScript | `**/*.{ts,tsx}` | `**/*.{test,spec}.{ts,tsx}` |
| Go | `**/*.go` | `**/*_test.go` |
| Rust | `**/*.rs` | `tests/**/*.rs` |

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

## Local Memory

Invoked via the opt-in `--with-local` flag. In addition to the team-shared `CLAUDE.md`, generate a personal `CLAUDE.local.md` at the repo root for preferences that should never be committed.

**Canonical location**: `./CLAUDE.local.md` — per the Claude Code memory docs, this file is loaded at the same level as `CLAUDE.md` and appended after it, so local preferences win on conflict. See <https://code.claude.com/docs/en/memory#choose-where-to-put-claude-md-files>.

### Behavior

1. Generate a minimal starter `CLAUDE.local.md` at the repo root:

   ```markdown
   # CLAUDE.local.md — Personal preferences (not committed)

   This file is gitignored. Add personal preferences that should not be shared with the team.

   ## Personal preferences
   - (add your own)

   ## Local sandbox URLs
   - (add your own)
   ```

2. **Ensure it is gitignored.** Check `.gitignore`:
   - If `.gitignore` already contains a line matching `CLAUDE.local.md`, do nothing.
   - Otherwise, append `CLAUDE.local.md` on its own line.
   - Never overwrite an existing `.gitignore`; only append.

3. **NEVER overwrite** an existing `CLAUDE.local.md` — skip with a message if it already exists.

4. Report in the Step 8 output:

   ```
   ✓ CLAUDE.local.md  (new — personal preferences, gitignored)
   ✓ .gitignore       (appended: CLAUDE.local.md)
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
