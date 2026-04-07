# Sharp Edge → Hook Mapping

Maps detected sharp edge patterns to **canonical Claude Code hook configurations** for `.claude/settings.json`.

All snippets below follow the official format: events nest under `hooks.{EventName}[]` with a `matcher` (regex on tool name) and a `hooks[]` array of handlers. The optional `if:` field uses permission rule syntax (`Edit(*.py)`, `Bash(rm *)`) to narrow further.

Event reference: <https://code.claude.com/docs/en/hooks>

---

## shell=True / exec() / eval()

Dangerous command execution patterns. Warn (non-blocking) after Claude edits a Python source file.

```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Edit|Write|MultiEdit",
        "hooks": [
          {
            "type": "command",
            "if": "Edit({{SOURCE_GLOB}})",
            "command": "FILE=$(jq -r '.tool_input.file_path'); grep -nE 'shell=True|\\beval\\(|\\bexec\\(' \"$FILE\" >&2 && echo 'WARNING: dangerous execution patterns detected — review carefully.' >&2; exit 0"
          }
        ]
      }
    ]
  }
}
```

---

## Hardcoded credentials

Block (exit 2) any Bash commit attempt that introduces hardcoded passwords. Runs before the tool executes so the commit never lands.

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "if": "Bash(git commit*)",
            "command": "if git diff --cached -U0 | grep -nE '^\\+.*(password|secret|api_key|token)\\s*=\\s*[\"\\x27][^\\x27\"]+[\"\\x27]' | grep -viE 'test|example|mock|fixture|placeholder'; then echo 'BLOCKED: hardcoded credentials detected. Use environment variables.' >&2; exit 2; fi"
          }
        ]
      }
    ]
  }
}
```

`exit 2` is the canonical blocking signal for `PreToolUse`. The stderr message is fed back to Claude as an error.

---

## SQL injection risk (f-string SQL)

Warn after edits to Python files that introduce f-string SQL.

```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Edit|Write|MultiEdit",
        "hooks": [
          {
            "type": "command",
            "if": "Edit(*.py)",
            "command": "FILE=$(jq -r '.tool_input.file_path'); grep -nE 'f[\"\\x27].*(SELECT|INSERT|UPDATE|DELETE)' \"$FILE\" >&2 && echo 'WARNING: possible SQL injection — use parameterized queries.' >&2; exit 0"
          }
        ]
      }
    ]
  }
}
```

---

## dangerouslySetInnerHTML

React XSS risk. Warn on JSX/TSX edits.

```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Edit|Write|MultiEdit",
        "hooks": [
          {
            "type": "command",
            "if": "Edit(*.{jsx,tsx})",
            "command": "FILE=$(jq -r '.tool_input.file_path'); grep -n 'dangerouslySetInnerHTML' \"$FILE\" >&2 && echo 'WARNING: XSS risk — sanitize HTML before rendering.' >&2; exit 0"
          }
        ]
      }
    ]
  }
}
```

---

## Lint on file edit

Always run the project linter after Claude edits source files. Surfaces issues to Claude via `additionalContext` so it can self-correct in the next turn.

```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Edit|Write|MultiEdit",
        "hooks": [
          {
            "type": "command",
            "if": "Edit({{SOURCE_GLOB}})",
            "command": "FILE=$(jq -r '.tool_input.file_path'); OUT=$({{LINT_COMMAND}} \"$FILE\" 2>&1) || jq -nc --arg ctx \"Lint failed for $FILE:\\n$OUT\" '{hookSpecificOutput:{hookEventName:\"PostToolUse\",additionalContext:$ctx}}'; exit 0"
          }
        ]
      }
    ]
  }
}
```

`PostToolUse` cannot block (the tool already ran) — instead it pipes lint output back into Claude's context via `hookSpecificOutput.additionalContext`.

---

## Block writes to sensitive directories

Prevent edits to migrations, secrets, or `.env` files via `PreToolUse` blocking.

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Edit|Write|MultiEdit",
        "hooks": [
          {
            "type": "command",
            "command": "FILE=$(jq -r '.tool_input.file_path'); case \"$FILE\" in *migrations/*|*.env|*.env.*|*secrets/*) echo 'BLOCKED: editing sensitive files requires explicit approval.' >&2; exit 2 ;; esac; exit 0"
          }
        ]
      }
    ]
  }
}
```

---

## InstructionsLoaded — debug which rules fire when

Diagnostic hook for path-scoped rule debugging. Logs every CLAUDE.md / `.claude/rules/*.md` file as it loads, with the trigger reason.

```json
{
  "hooks": {
    "InstructionsLoaded": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "jq -r '\"[\" + .reason + \"] \" + (.files | join(\", \"))' >> \"$CLAUDE_PROJECT_DIR/.claude/instructions.log\"; exit 0"
          }
        ]
      }
    ]
  }
}
```

This hook is invaluable for diagnosing why a path-scoped rule did or did not fire on a given file read. See <https://code.claude.com/docs/en/memory#path-specific-rules>.

---

## Notes on canonical hook semantics

| Behavior | How |
|---|---|
| Block a tool call | `PreToolUse` handler exits with code `2` and writes the reason to stderr |
| Surface info to Claude (non-blocking) | `PostToolUse` handler emits JSON with `hookSpecificOutput.additionalContext` |
| Run only on tool name | Top-level `matcher` regex (e.g. `"Edit\|Write\|MultiEdit"`) |
| Run only on argument shape | `if:` field with permission rule syntax (e.g. `Edit(*.py)`, `Bash(git commit*)`) |
| Get the affected file path inside a command hook | `jq -r '.tool_input.file_path'` from stdin JSON |
| Get the project root inside a hook | `$CLAUDE_PROJECT_DIR` env var (always set) |

`additionalContext` enters Claude's context **untruncated** — keep it concise. Plain stdout from a hook does not enter context (verbose mode only).
