# Dry-Run Mode

Invoked with `--dry-run`. Executes the full analysis pipeline (Steps 1-2) but **skips all file writes** in Steps 3-7. Collects the list of files that *would* be created and prints a preview report.

## Output Format

```
+======================================================================+
|  DRY RUN — No files will be created                                  |
+======================================================================+

Project: my-api
Stack:   Python + FastAPI | pytest | ruff

Would create:
  → .claude/rules/api.md              (paths: src/api/**)
  → .claude/rules/auth.md             (paths: src/auth/**)
  → .claude/rules/python.md           (paths: **/*.py)
  → .claude/skills/run-tests/SKILL.md (pytest -v)
  → .claude/skills/lint/SKILL.md      (ruff check --fix)
  → .claude/agents/security-reviewer.md
  → CLAUDE.md                         (45 lines)

Would skip (already exist):
  ⊘ .claude/rules/config.md

Score: 15% → 87% (+72%) if applied

Run without --dry-run to create these files.
```

All analysis, scoring, and hook suggestions are computed and shown. Only file creation is suppressed.
