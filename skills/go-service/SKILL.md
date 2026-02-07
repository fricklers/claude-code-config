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

Wire dependencies explicitly in `main.go` — no global state, no init() functions:
- Pass dependencies as constructor arguments: `func NewUserService(repo UserRepo, logger *slog.Logger) *UserService`
- Define interfaces at the consumer, not the implementor: `type UserRepo interface { ... }` lives in `service/`, not `repo/`
- Keep interfaces small (1-3 methods) — accept the narrowest interface that satisfies the function's needs
- Use `func main()` as the composition root — construct all dependencies, wire them together, then start

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

## 5. Error Handling

Use Go's error conventions consistently:
- Return `error` as the last value — check it immediately, never defer
- Wrap with context: `fmt.Errorf("create user: %w", err)` — the chain should read like a stack trace
- Define sentinel errors for expected failures: `var ErrNotFound = errors.New("not found")`
- Map errors to HTTP status codes in the handler layer, not in business logic

## 6. Testing with Race Detection

Write tests that catch concurrency bugs:
- Run all tests with `-race`: `go test -race ./...`
- Table-driven tests: `tests := []struct{ name string; ... }{ ... }` with `t.Run(tc.name, ...)`
- Call `t.Parallel()` in every test that doesn't share mutable state
- Use `httptest.NewServer` for handler tests, mock interfaces for service-layer tests
- Use `t.Helper()` in all test helper functions for accurate line reporting

## 7. Verify Before Shipping

Run the full verification chain before declaring the service ready:
- `go vet ./...` — catch common mistakes
- `golangci-lint run` — comprehensive lint check
- `go test -race -count=1 ./...` — all tests pass with race detection, no caching
- `go build ./cmd/<service>` — binary compiles cleanly
- If any step fails, fix and re-run the entire chain
