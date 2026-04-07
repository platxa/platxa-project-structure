# Audit Mode

Invoked with `--audit` (e.g., `/platxa-project-structure:setup --audit`). Skips all generation steps and instead analyzes existing `.claude/` structure for health issues.

## Audit Steps

1. **Run the project-analyzer agent** (same as Step 1 of the main pipeline) to get the current module list
2. **Read all existing `.claude/rules/*.md` files** and parse their YAML frontmatter to extract each rule's `paths:` glob list
3. **Glob-verify each `paths:` entry**: for every glob found in a rule's frontmatter, invoke the Glob tool with that pattern. If the result is empty (zero matching files), flag the rule as an **orphaned rule** (ERROR severity). This catches rules whose target modules have been deleted or renamed.
   ```
   For rule .claude/rules/api.md with paths: ["src/api/**/*.ts"]:
     Glob(pattern="src/api/**/*.ts") → if result is empty, report ERROR
   ```
4. **Cross-reference** rules against actual modules (from the analyzer's `modules[]` list) using the checks below
5. **Print audit report** — never modifies files

## Health Checks

| Check | Finding | Severity |
|-------|---------|----------|
| Module exists but has no rule file | Gap — uncovered module | WARN |
| Rule references a path that no longer exists | Stale rule — dead reference | ERROR |
| Rule file exceeds 50 lines | Bloated rule | WARN |
| Rule `paths:` glob matches zero files (use Glob tool to verify) | Orphaned rule — no matching files | ERROR |
| CLAUDE.md exceeds 200 lines | Bloated CLAUDE.md | WARN |
| Skill references a command that isn't installed | Broken skill | WARN |

## Output Format

```
+======================================================================+
|  PROJECT STRUCTURE AUDIT                                             |
+======================================================================+

Project: {{project_name}}
Rules:   {{rules_count}} files | Skills: {{skills_count}} | Hooks: {{hook_count}}

Health:  {{healthy_count}}/{{total_checks}} checks passed

Issues found:
  ✗ ERROR  .claude/rules/old-module.md — paths match 0 files (module deleted?)
  ✗ ERROR  .claude/rules/api.md:15 — references src/api/v1/ which no longer exists
  ⚠ WARN   .claude/rules/database.md — 67 lines (exceeds 50-line limit)
  ⚠ WARN   No rule for module: src/notifications/ (12 files, 890 lines)

No issues:
  ✓ .claude/rules/auth.md — 28 lines, paths valid
  ✓ .claude/rules/python.md — 22 lines, paths valid
  ✓ .claude/skills/run-tests/SKILL.md — command found
  ✓ CLAUDE.md — 85 lines (OK)

Suggestions:
  1. Delete .claude/rules/old-module.md (orphaned)
  2. Update paths in .claude/rules/api.md
  3. Trim .claude/rules/database.md to under 50 lines
  4. Run /platxa-project-structure:setup to generate rule for src/notifications/
```

**Audit NEVER modifies files** — it only reports. The user decides what to fix.
