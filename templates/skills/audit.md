---
name: audit
description: Audit the project's .claude/ structure for stale rules, dead globs, bloat, and broken skills. Use when you want a quick health check on the generated rules and skills.
allowed-tools: Bash Read Glob
disable-model-invocation: true
---

# Audit

Run a health check on the `.claude/` directory: detect stale rules, orphaned `paths:` globs that match zero files, CLAUDE.md bloat (>200 lines), rules over 50 lines, skills referencing uninstalled commands, and modules with no rule coverage.

This skill is a thin wrapper around the project-structure plugin's audit mode.

## Command

```bash
/platxa-project-structure:setup --audit
```

## After running

The audit report is a read-only health summary. It never modifies files. Review the ERROR and WARN findings, then decide per-file whether to:

- **Delete** an orphaned rule whose target module no longer exists
- **Update** a rule whose `paths:` glob no longer matches any files
- **Trim** a rule or CLAUDE.md that exceeds the line budget
- **Re-run** `/platxa-project-structure:setup` to scaffold a rule for an uncovered module

Never bypass findings without justification — the audit catches real drift between `.claude/` and the actual codebase.
