---
name: go-service
description: Production Go service construction. Covers project structure, dependency injection, structured logging, graceful shutdown, and race testing.
---

When this skill is active, follow this 7-step discipline when building a Go service:

## 1. Project Structure

Organize the service using standard Go project layout:
- `cmd/<service>/main.go` — entry point, wiring only, no business logic
- `internal/` — private application code: `internal/handler/`, `internal/service/`, `internal/repo/`
- `pkg/` only for code genuinely intended for external consumption (rare)
- Keep `go.mod` clean: `go mod tidy` after every dependency change

## 2. Dependency Injection

Wire dependencies explicitly in `main.go` — no global state, no `init()` functions:
- **Draw the dependency graph** before coding: which service depends on which repository, logger, or config?
- **Constructor injection only**: `func NewUserService(repo UserRepo, logger *slog.Logger) *UserService`
- **`func main()` is the composition root** — construct all dependencies, wire them together, then start
- **Verify testability**: every constructor should accept interfaces, making it possible to pass mocks in tests

## 3. Structured Logging with slog

Use `log/slog` (standard library) for all logging:
- Create the logger once in `main.go`: `slog.New(slog.NewJSONHandler(os.Stdout, &slog.HandlerOptions{Level: slog.LevelInfo}))`
- Pass the logger as a dependency — never use the global `slog.Default()`
- Log with structured fields: `logger.Info("user created", "user_id", id, "email", email)`
- Use `logger.With("request_id", reqID)` to create request-scoped loggers in middleware

## 4. Graceful Shutdown

Handle termination signals so in-flight requests complete:
- Listen for `os.Interrupt` and `syscall.SIGTERM` with `signal.NotifyContext`
- Call `server.Shutdown(ctx)` with a timeout context (e.g., 15 seconds)
- Close database connections, flush logs, and release resources in deferred cleanup
- Log shutdown progress: "shutting down", "connections drained", "shutdown complete"

## 5. Error Handling Strategy

Design the error flow across layers before implementing:
- **Map every error to an HTTP status** in the handler layer — business logic returns domain errors, handlers translate
- **Wrap with context at each layer boundary**: `fmt.Errorf("userService.Create: %w", err)` — the chain reads like a call stack
- **List sentinel errors upfront**: `var ErrNotFound`, `var ErrConflict`, etc. — define them before writing the code that returns them
- **Log once, at the top**: handlers log the full error chain; lower layers wrap and propagate, never log

## 6. Testing with Race Detection

Write tests that catch concurrency bugs:
- **Always run with `-race`**: `go test -race ./...` — make this the default in CI and local dev
- **Test each layer independently**: `httptest.NewServer` for handlers, mock interfaces for services, real DB for repos
- **Stress-test concurrent paths**: launch N goroutines hitting the same endpoint and assert no races or data corruption
- **Measure coverage on critical paths**: `go test -coverprofile=cover.out ./internal/service/` — review uncovered branches

## 7. Verify Before Shipping

Run the full verification chain before declaring the service ready:
- `go vet ./...` — catch common mistakes
- `golangci-lint run` — comprehensive lint check
- `go test -race -count=1 ./...` — all tests pass with race detection, no caching
- `go build ./cmd/<service>` — binary compiles cleanly
- If any step fails, fix and re-run the entire chain
