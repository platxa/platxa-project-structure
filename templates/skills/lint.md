---
name: lint
description: Run linter and fix issues automatically. User-invoked only — has side effects (auto-fixes files).
allowed-tools: Bash Read Edit
disable-model-invocation: true
paths:
  - "{{SOURCE_GLOB}}"
---

# Lint

Run the project linter and auto-fix where possible.

## Commands
```bash
# Check for issues
{{LINT_COMMAND}}

# Auto-fix
{{LINT_FIX_COMMAND}}
```

## After running:
- Report number of issues found and fixed
- For issues that can't be auto-fixed, explain and fix manually
- Never suppress lint warnings without justification
