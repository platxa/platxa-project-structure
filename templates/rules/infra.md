---
paths:
  - "**/Dockerfile"
  - "**/Dockerfile.*"
  - "**/docker-compose.yml"
  - "**/docker-compose.*.yml"
  - "k8s/**/*.{yml,yaml}"
  - "kubernetes/**/*.{yml,yaml}"
  - "manifests/**/*.{yml,yaml}"
  - "helm/**/*.{yml,yaml}"
  - "charts/**/*.{yml,yaml}"
  - "**/*.tf"
---

# Infrastructure Rules

Rules that activate when Claude reads Dockerfiles, Kubernetes manifests, Helm charts, Terraform, or docker-compose files.

## Dockerfile

- Pin base images to a digest or specific version — never `latest`
- Use multi-stage builds for compiled languages to keep final images small
- Run processes as a non-root user (`USER` directive) — never as root in production
- Set `WORKDIR` explicitly; do not rely on `/`
- Combine related `RUN` commands with `&&` and clean up in the same layer (`rm -rf /var/lib/apt/lists/*`)
- Use `COPY` not `ADD` unless you need `ADD`'s tar-unpacking or URL fetching
- Avoid `ENV` for secrets — use build-time args or runtime secret mounts
- Add a `HEALTHCHECK` for long-running services

## Kubernetes Manifests

- Every Deployment must declare both `resources.requests` and `resources.limits` for cpu and memory
- Set `securityContext.runAsNonRoot: true` and `readOnlyRootFilesystem: true` where possible
- Never hard-code secrets in manifests — reference `Secret` objects via `env.valueFrom.secretKeyRef`
- Use explicit image tags or digests — never `latest`
- Declare liveness and readiness probes on every Pod spec
- Label resources with `app.kubernetes.io/name`, `app.kubernetes.io/version`, `app.kubernetes.io/managed-by` for observability
- Prefer `Deployment` + `Service` over bare `Pod`

## docker-compose

- Pin service image versions; avoid `latest`
- Use named volumes for persistent data, not bind mounts to arbitrary host paths
- Do not commit `.env` files — reference them via `env_file:` and gitignore the file
- Declare network aliases explicitly for inter-service references

## Terraform

- Always run `terraform fmt` and `terraform validate` before committing
- Use remote state with locking (S3 + DynamoDB, GCS, etc.) — never commit state files
- Declare `required_providers` and `required_version` in every module
- Prefer data sources over hard-coded resource IDs
- Never commit `*.tfvars` containing credentials

## Universal

- Treat infra files as production code — review, test, and version them
- Never commit credentials, private keys, or tokens in any infra manifest
- Document non-obvious decisions (port choices, resource limits, selector labels) with inline comments
