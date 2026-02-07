---
name: docker-deploy
description: Container construction workflow. Multi-stage builds, layer caching, security hardening, and deployment verification.
---

When this skill is active, follow this 6-step discipline when building Docker containers:

## 1. Multi-Stage Build

Structure the Dockerfile with separate stages for build and runtime:
- **Build stage**: install dependencies, compile code, run tests — use a full SDK image
- **Runtime stage**: copy only the final artifact into a minimal base image (`alpine`, `distroless`, or `scratch`)
- Name stages for clarity: `FROM node:22-alpine AS build`, `FROM node:22-alpine AS runtime`
- Never ship build tools, source code, or dev dependencies in the final image

## 2. Optimize Layer Caching

Order instructions to maximize cache reuse:
- Copy dependency manifests first (`package.json`, `go.sum`, `Cargo.lock`), then install dependencies
- Copy source code after dependency installation — code changes shouldn't re-download packages
- Use `.dockerignore` to exclude `node_modules/`, `.git/`, `dist/`, test files, and documentation
- Pin base image digests for reproducibility: `FROM node:22-alpine@sha256:<digest>`

## 3. Security Hardening

Reduce the attack surface of the final image:
- Run as a non-root user: `RUN addgroup -S app && adduser -S app -G app` then `USER app`
- No shell in production images when possible — use `distroless` or remove `/bin/sh`
- Scan for vulnerabilities: `docker scout cves <image>` or `trivy image <image>`
- Set read-only filesystem: `--read-only` flag at runtime, use tmpfs for writable paths
- Never store secrets in the image — use build-time `--mount=type=secret` or runtime environment variables

## 4. Health Checks and Signals

Configure the container to report its status and shut down cleanly:
- Add `HEALTHCHECK` instruction: `HEALTHCHECK --interval=30s --timeout=3s CMD wget -qO- http://localhost:3000/health || exit 1`
- Use `STOPSIGNAL SIGTERM` and handle it in the application for graceful shutdown
- Use `exec` form for `CMD` and `ENTRYPOINT`: `CMD ["node", "server.js"]` — not shell form
- Set a reasonable stop timeout to allow in-flight requests to complete

## 5. Compose for Local Development

Use `docker-compose.yml` to mirror the production topology locally:
- Mount source code as volumes for hot reload during development
- Match service dependencies: database, cache, message queue
- Use `.env` files for configuration — never hardcode connection strings
- Define named volumes for database persistence across restarts

## 6. Verify the Image

Confirm the container works before deploying:
- `docker build --target runtime -t <image> .` — build completes without errors
- `docker run --rm <image>` — application starts and responds to health checks
- `docker image ls <image>` — verify final image size is reasonable (target: under 200MB for most services)
- `docker scout cves <image>` — zero critical or high vulnerabilities
- Test with production-like config: environment variables, network isolation, resource limits
- If any step fails, fix the issue and re-run the entire chain
