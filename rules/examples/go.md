---
description: Go conventions
globs:
  - "**/*.go"
---

## Errors

- Return `error` as the last return value — always
- Wrap errors with `fmt.Errorf("context: %w", err)` to preserve the chain
- Check errors immediately — no deferred error checking
- Use sentinel errors (`var ErrNotFound = errors.New(...)`) or custom types for expected failures

## Interfaces

- Define interfaces at the consumer, not the implementor
- Keep interfaces small: 1-3 methods. The bigger the interface, the weaker the abstraction
- Accept interfaces, return structs — concrete types give callers more flexibility
- Embed interfaces for composition: `type ReadWriteCloser interface { io.Reader; io.Writer; io.Closer }`

## Concurrency

- Channels for communication between goroutines, mutexes for protecting shared state
- Always `defer cancel()` after `context.WithCancel` or `context.WithTimeout`
- Use `errgroup.Group` for coordinating goroutine groups with error propagation
- Don't start goroutines in init or constructors — let the caller control lifecycle

## Naming

- Short names for short scopes: `i`, `r`, `ctx` inside a function
- Descriptive names for exports: `HandleUserRegistration`, not `Handle`
- Package name is part of the API: `http.Client`, not `http.HTTPClient`
- Avoid `Get` prefix on getters: `user.Name()`, not `user.GetName()`

## Testing

- Table-driven tests with `[]struct{ name string; ... }` for multiple cases
- Use `t.Helper()` in test helper functions for correct line reporting
- `_test.go` suffix — tests are in the same package for unit tests, `_test` package for integration
- `t.Parallel()` by default — opt out only when tests share state

## Patterns

- Functional options: `func WithTimeout(d time.Duration) Option` for configurable constructors
- Composition over embedding — embed only when the outer type IS-A inner type
- Use `context.Context` as the first parameter for anything that does I/O
- Prefer `sync.Once` for lazy initialization over manual bool + mutex
