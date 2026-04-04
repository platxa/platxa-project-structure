---
paths:
  - "{{MODULE_PATH}}/**/*.ts"
  - "{{MODULE_PATH}}/**/*.tsx"
---

# {{MODULE_NAME}} — TypeScript Rules

## Code Quality
- Strict TypeScript mode — no `any` types unless explicitly justified
- Run `{{TYPE_CHECKER}}` before marking complete — zero errors
- Run `{{LINTER}}` for linting — zero errors
- Use `{{FORMATTER}}` for formatting

## Testing
- Run tests: `{{TEST_COMMAND}}`
- Test framework: {{TEST_FRAMEWORK}}
- Prefer integration tests over unit tests for API endpoints

## React/Component Conventions (if applicable)
- Functional components with hooks only — no class components
- Props must be typed with explicit interfaces (not inline)
- Use named exports, not default exports

## Conventions
- No `console.log` in production code — use proper logging
- No hardcoded API URLs — use environment variables
- Follow existing patterns in this module before inventing new ones

{{SHARP_EDGES}}
