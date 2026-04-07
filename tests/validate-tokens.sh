#!/usr/bin/env bash
# validate-tokens.sh — verify every {{TOKEN}} used in templates/ has a known
# source in the analyzer schema or the documented derivation map, and that
# every documented token is actually used somewhere.
#
# This is a Claude Code plugin (no runtime) — the test runs as plain bash.
# Exits 0 on pass, 1 on any unknown or orphaned tokens.
#
# Usage:  bash tests/validate-tokens.sh
#         (run from repo root)

set -euo pipefail
cd "$(dirname "$0")/.."

REPO_ROOT="$(pwd)"
ANALYZER="agents/project-analyzer.md"
TOKEN_DOC="skills/setup/references/templates.md"

# ---- Allowed token registry --------------------------------------------------
# A token is "known" if it appears in this list. Each entry is annotated with
# its source: ANALYZER (direct field), DERIVED (computed from analyzer field
# inside the setup skill), or COMPUTED (synthesized at generation time).
#
# When you add a new {{TOKEN}} to a template, add it here AND document it in
# skills/setup/references/templates.md.

ALLOWED_TOKENS=(
  # ---- Direct from analyzer JSON output ----
  "MODULE_NAME"           # modules[].name
  "MODULE_PATH"           # modules[].path
  "FILE_COUNT"            # modules[].files
  "LINE_COUNT"            # modules[].lines
  "COMPLEXITY"            # modules[].complexity
  "LINTER"                # stack.linter
  "TYPE_CHECKER"          # stack.typeChecker
  "FORMATTER"             # stack.formatter
  "TEST_FRAMEWORK"        # stack.testFramework

  # ---- Derived from analyzer fields by the setup skill ----
  "TEST_COMMAND"          # derived from stack.testFramework
  "LINT_COMMAND"          # derived from stack.linter
  "LINT_FIX_COMMAND"      # derived from stack.linter
  "TYPE_CHECK_COMMAND"    # derived from stack.typeChecker
  "FORMAT_CHECK_COMMAND"  # derived from stack.formatter
  "FORMAT_FIX_COMMAND"    # derived from stack.formatter
  "FORMAT_COMMAND"        # alias for FORMAT_FIX_COMMAND in claude-md templates
  "DEV_COMMAND"           # derived from stack/framework (e.g. npm run dev)
  "SOURCE_GLOB"           # derived from stack.language (e.g. **/*.py)
  "TEST_GLOB"             # derived from stack.testFramework (e.g. tests/**/*.py)
  "DATABASE_RULES"        # concatenated database template content
  "SHARP_EDGES"           # formatted from sharpEdges[] per module

  # ---- Computed at generation time by the setup skill ----
  "ARCHITECTURE_SUMMARY"  # derived narrative from modules[]
)

# Documentation-only literal — appears in token reference docs as an example.
DOC_ONLY_TOKENS=(
  "DOUBLE_BRACE"
)

# ---- Scan templates for actual token usage ----------------------------------
mapfile -t USED_TOKENS < <(
  grep -rohE '\{\{[A-Z_]+\}\}' templates/ skills/ agents/ 2>/dev/null \
    | sed -E 's/^\{\{([A-Z_]+)\}\}$/\1/' \
    | sort -u
)

# ---- Check 1: every used token must be in ALLOWED_TOKENS or DOC_ONLY_TOKENS -
unknown=()
for tok in "${USED_TOKENS[@]}"; do
  if [[ " ${ALLOWED_TOKENS[*]} ${DOC_ONLY_TOKENS[*]} " != *" $tok "* ]]; then
    unknown+=("$tok")
  fi
done

# ---- Check 2: every ALLOWED_TOKENS entry must be used somewhere -------------
orphaned=()
for tok in "${ALLOWED_TOKENS[@]}"; do
  if [[ " ${USED_TOKENS[*]} " != *" $tok "* ]]; then
    orphaned+=("$tok")
  fi
done

# ---- Check 3: every used token must be documented in templates.md -----------
undocumented=()
for tok in "${USED_TOKENS[@]}"; do
  if [[ " ${DOC_ONLY_TOKENS[*]} " == *" $tok "* ]]; then continue; fi
  if ! grep -qF "{{${tok}}}" "$TOKEN_DOC" 2>/dev/null; then
    undocumented+=("$tok")
  fi
done

# ---- Report ------------------------------------------------------------------
echo "Token validation report"
echo "======================="
echo "Used tokens:    ${#USED_TOKENS[@]}"
echo "Allowed tokens: ${#ALLOWED_TOKENS[@]}"
echo

fail=0

if (( ${#unknown[@]} > 0 )); then
  echo "FAIL  Unknown tokens (used but not in ALLOWED_TOKENS):"
  printf '  - {{%s}}\n' "${unknown[@]}"
  fail=1
fi

if (( ${#orphaned[@]} > 0 )); then
  echo "FAIL  Orphaned tokens (in ALLOWED_TOKENS but not used anywhere):"
  printf '  - {{%s}}\n' "${orphaned[@]}"
  fail=1
fi

if (( ${#undocumented[@]} > 0 )); then
  echo "FAIL  Undocumented tokens (not listed in $TOKEN_DOC):"
  printf '  - {{%s}}\n' "${undocumented[@]}"
  fail=1
fi

if (( fail == 0 )); then
  echo "PASS  All ${#USED_TOKENS[@]} tokens are known, used, and documented."
fi

# ---- Bonus check: analyzer schema field cross-reference ---------------------
# Verify that every "ANALYZER" or "DERIVED" token has its source field present
# in the analyzer's example output JSON. This catches drift between the schema
# and the templates.
echo
echo "Analyzer schema cross-reference"
echo "-------------------------------"

declare -A SCHEMA_FIELDS=(
  [MODULE_NAME]='"name"'
  [MODULE_PATH]='"path"'
  [FILE_COUNT]='"files"'
  [LINE_COUNT]='"lines"'
  [COMPLEXITY]='"complexity"'
  [LINTER]='"linter"'
  [TYPE_CHECKER]='"typeChecker"'
  [FORMATTER]='"formatter"'
  [TEST_FRAMEWORK]='"testFramework"'
)

missing_schema=()
for tok in "${!SCHEMA_FIELDS[@]}"; do
  field="${SCHEMA_FIELDS[$tok]}"
  if ! grep -qF "$field" "$ANALYZER" 2>/dev/null; then
    missing_schema+=("$tok → $field")
  fi
done

if (( ${#missing_schema[@]} > 0 )); then
  echo "FAIL  Tokens whose source field is missing from $ANALYZER:"
  printf '  - %s\n' "${missing_schema[@]}"
  fail=1
else
  echo "PASS  All direct-mapped tokens have their source field in the analyzer schema."
fi

exit $fail
