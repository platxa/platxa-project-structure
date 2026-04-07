---
description: Check and fix code formatting using {{FORMATTER}}. User-invoked only — has side effects (rewrites files).
allowed-tools: Bash Read Edit
disable-model-invocation: true
paths:
  - "{{SOURCE_GLOB}}"
---

# Format Check

Verify code formatting and auto-fix where possible.

## Commands
```bash
# Check formatting (report only)
{{FORMAT_CHECK_COMMAND}}

# Auto-fix formatting
{{FORMAT_FIX_COMMAND}}
```

## After running:
- Report number of files reformatted
- If formatting changes are made, stage them before committing
- Never manually adjust whitespace — let the formatter handle it
