---
paths:
  - "{{MODULE_PATH}}/**"
---

# {{MODULE_NAME}} Module Rules

## Architecture
- This module has {{FILE_COUNT}} files and {{LINE_COUNT}} lines (complexity: {{COMPLEXITY}})
- Always read existing code before modifying — use Read tool, never guess

## Safety
- Never overwrite files without reading them first
- Run tests after changes: `{{TEST_COMMAND}}`
- Run linter after changes: `{{LINT_COMMAND}}`

{{SHARP_EDGES}}
