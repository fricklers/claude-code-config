---
description: Rust conventions
globs:
  - "**/*.rs"
---

## Ownership

- Prefer borrowing (`&T`, `&mut T`) over cloning — clone only when ownership transfer is needed
- Use `&str` in function signatures, `String` from constructors and builders
- Avoid unnecessary `Arc<Mutex<T>>` — prefer message passing or simpler ownership
- Use `Cow<'_, str>` when a function might or might not need to allocate

## Error Handling

- Libraries: `thiserror` for typed error enums with `#[error("...")]`
- Applications: `anyhow` for flexible error context with `.context("...")`
- Never `.unwrap()` in library code — use `?` or return `Result`
- `.expect("reason")` is acceptable in application code for truly impossible states

## Types

- Newtypes for domain concepts: `struct UserId(Uuid)` prevents mixing IDs
- Derive `Debug`, `Clone`, `PartialEq` on data types by default
- Use `#[non_exhaustive]` on public enums to allow future variants
- Prefer enums over booleans: `enum Visibility { Public, Private }` over `is_public: bool`

## Async

- `tokio` as the async runtime — use `tokio::select!` for concurrent operations
- Set timeouts on all network calls: `tokio::time::timeout(Duration::from_secs(10), fut)`
- Use `Arc` for shared state across tasks, `tokio::sync::Mutex` for async-safe locking
- Prefer `tokio::spawn` for independent background work, `join!` for concurrent dependencies

## Testing

- `#[cfg(test)]` modules in the same file for unit tests
- `rstest` for parameterized tests, `mockall` for trait mocking
- `#[tokio::test]` for async tests
- Use `assert_matches!` for pattern matching in assertions

## Patterns

- Iterators over explicit loops — `.filter().map().collect()` is idiomatic and often faster
- `Option`/`Result` combinators (`.map()`, `.and_then()`, `.unwrap_or_default()`) over match when simple
- Builder pattern for types with many optional fields
- Avoid `unsafe` — if needed, isolate it and document the safety invariants
