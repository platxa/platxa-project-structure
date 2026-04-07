---
description: Check and fix code formatting using {{FORMATTER}}
allowed-tools: Bash Read Edit
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
