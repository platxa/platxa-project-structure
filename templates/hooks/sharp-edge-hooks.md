# Sharp Edge → Hook Mapping

Maps detected sharp edge patterns to concrete Claude Code hook configurations for `.claude/settings.json`.

## Pattern → Hook Map

### shell=True / exec() / eval()
Dangerous command execution detected. Block writes to files containing these patterns without review.

```json
{
  "event": "on_file_edit",
  "pattern": "{{FILE_GLOB}}",
  "command": "grep -n 'shell=True\\|eval(\\|exec(' \"$FILE\" && echo 'WARNING: File contains dangerous execution patterns. Review carefully.' >&2 || true"
}
```

### Hardcoded credentials
Passwords or secrets hardcoded in source files.

```json
{
  "event": "pre_commit",
  "command": "grep -rn --include='*.py' --include='*.ts' --include='*.yaml' 'password.*=.*[\"'\\''\"'\\''']' --exclude-dir=test --exclude-dir=fixture . && echo 'BLOCKED: Hardcoded credentials detected. Use environment variables.' >&2 && exit 1 || true"
}
```

### SQL injection risk (f-string SQL)
Raw SQL built with f-strings or string formatting.

```json
{
  "event": "on_file_edit",
  "pattern": "{{FILE_GLOB}}",
  "command": "grep -n 'f\".*SELECT\\|f\".*INSERT\\|f\".*UPDATE\\|f\".*DELETE' \"$FILE\" && echo 'WARNING: Possible SQL injection — use parameterized queries.' >&2 || true"
}
```

### dangerouslySetInnerHTML
React XSS risk pattern.

```json
{
  "event": "on_file_edit",
  "pattern": "**/*.tsx,**/*.jsx",
  "command": "grep -n 'dangerouslySetInnerHTML' \"$FILE\" && echo 'WARNING: XSS risk — sanitize HTML before rendering.' >&2 || true"
}
```

### Lint on file edit
Always run linter after Claude edits source files.

```json
{
  "event": "on_file_edit",
  "pattern": "{{SOURCE_GLOB}}",
  "command": "{{LINT_COMMAND}}"
}
```

### Block writes to sensitive directories
Prevent Claude from modifying migration files, secrets, or lock files without confirmation.

```json
{
  "event": "on_file_edit",
  "pattern": "**/migrations/**,**/.env*,**/secrets/**",
  "command": "echo 'BLOCKED: Editing sensitive files requires explicit approval.' >&2 && exit 1"
}
```
