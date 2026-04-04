---
paths:
  - "{{MODULE_PATH}}/**/*.rs"
---

# {{MODULE_NAME}} — Rust Rules

## Code Quality
- Run `cargo clippy -- -D warnings` before marking complete
- Run `cargo fmt --check` for formatting
- Run `cargo test` for tests

## Safety
- Document every `unsafe` block with a `// SAFETY:` comment explaining the invariant
- Prefer safe abstractions over raw unsafe code
- No `.unwrap()` in library code — use `?` operator or proper error handling

## Conventions
- Use `thiserror` for library errors, `anyhow` for application errors
- Keep modules focused — split large files at 500 lines
- Follow Rust API guidelines for naming

{{SHARP_EDGES}}
