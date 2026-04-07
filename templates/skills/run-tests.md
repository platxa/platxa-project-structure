---
name: run-tests
description: Run the project test suite and report results
allowed-tools: Bash Read
paths:
  - "{{SOURCE_GLOB}}"
  - "{{TEST_GLOB}}"
---

# Run Tests

Run the project's test suite using {{TEST_FRAMEWORK}}.

## Command
```bash
{{TEST_COMMAND}}
```

## After running:
- Report total tests, passed, failed, skipped
- If any tests fail, investigate the failure and suggest fixes
- Never delete or skip failing tests — fix the implementation instead
