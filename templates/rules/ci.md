---
paths:
  - ".github/workflows/**/*.yml"
  - ".github/workflows/**/*.yaml"
  - ".gitlab-ci.yml"
  - ".circleci/config.yml"
  - "azure-pipelines.yml"
  - "Jenkinsfile"
---

# CI/CD Rules

Rules that activate when Claude reads CI pipeline definitions.

## Core principles

- **Hermetic**: every job should produce the same result given the same inputs. Pin action versions (use full commit SHA for third-party GitHub Actions, never `@main` or a floating tag), pin toolchain versions (`setup-node@v4` with `node-version: '20.11.1'`, not `20`).
- **Idempotent**: re-running a workflow on the same commit should not change the result. No timestamps baked into artifacts, no race on external state, no `if: always()` where `if: success()` would do.
- **Cache-correct**: cache keys must include every input that affects the cache content (lockfile hash, OS, toolchain version). A cache-miss should be harmless; a cache-hit should never cause a stale build.
- **Fast feedback**: order jobs so the fastest, most-likely-to-fail checks run first (lint before tests before e2e before build).

## GitHub Actions specifics

- Pin third-party actions by full commit SHA with a version comment:
  ```yaml
  uses: actions/checkout@11bd71901bbe5b1630ceea73d27597364c9af683  # v4.2.2
  ```
- Use `permissions:` at the workflow or job level to grant only what the job needs (principle of least privilege). Start with `permissions: read-all` and tighten as needed.
- Never echo secrets: `run: echo "${{ secrets.X }}"` leaks in logs.
- Use `concurrency:` to cancel in-progress runs on the same ref when a new commit lands.
- Matrix builds: include `fail-fast: false` when partial failures are informative.
- Artifacts: use `actions/upload-artifact@v4` and set a short `retention-days` unless legally required to retain.

## Cache keys

- Include the lockfile hash: `key: deps-${{ hashFiles('**/package-lock.json') }}`
- Include the OS: `key: deps-${{ runner.os }}-${{ hashFiles(...) }}`
- Use `restore-keys` as a fallback chain, not as the primary key

## Secrets

- Never commit secrets in workflow files. Use `${{ secrets.NAME }}` only.
- Rotate `GITHUB_TOKEN` permissions per job, not globally.
- For OIDC-based cloud auth, prefer `id-token: write` over long-lived cloud credentials.

## Testing

- Run the same commands the developers run locally — do not redefine test invocations in CI (e.g., call `make test` or `npm test`, not an inline pytest command that drifts from the local one).
- Fail fast on missing tests: a workflow that says "tests passed" when zero tests ran is worse than no tests.

## Deploy jobs

- Guard deployments on `if: github.ref == 'refs/heads/main' && github.event_name == 'push'` (or a release event), not just on `push`.
- Use environments (`environment: production`) with required reviewers for anything touching production.
- Never `force push` from CI.
