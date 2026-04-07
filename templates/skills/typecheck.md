---
description: Run type checking using {{TYPE_CHECKER}}
allowed-tools: Bash Read
---

# Type Check

Run the project's type checker to verify type safety.

## Command
```bash
{{TYPE_CHECK_COMMAND}}
```

## After running:
- Report total errors and warnings
- If errors found, fix them — never suppress type errors with `# type: ignore` or `any` without justification
- Type checking must pass with zero errors before committing
