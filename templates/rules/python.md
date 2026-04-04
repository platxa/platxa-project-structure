---
paths:
  - "{{MODULE_PATH}}/**/*.py"
---

# {{MODULE_NAME}} — Python Rules

## Code Quality
- Type hints required on all function signatures
- Use `{{FORMATTER}}` for formatting — never manually adjust whitespace
- Run `{{LINTER}}` before marking work complete — zero errors required
- Run `{{TYPE_CHECKER}}` for type checking — zero errors required

## Testing
- Run tests: `{{TEST_COMMAND}}`
- Tests must use the project's test framework ({{TEST_FRAMEWORK}})
- Never mock core business logic — use real implementations where possible

## Conventions
- Follow existing import patterns in this module
- No workarounds or TODO placeholders — fix root cause
- No hardcoded credentials — use environment variables

{{DATABASE_RULES}}

{{SHARP_EDGES}}
