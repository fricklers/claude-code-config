---
name: rust-modeling
description: Rust type and error modeling process. Designs domain enums, error hierarchies, and ownership patterns before writing logic.
---

When this skill is active, follow this 6-step discipline for designing Rust types and error handling:

## 1. Map the Domain to Types

Before writing any logic, model the domain:
- One struct per entity, one enum per state machine or variant set
- Use newtypes for identity: `struct UserId(Uuid)` — prevents mixing different ID types
- Use `#[non_exhaustive]` on public enums to allow future variants without breaking changes
- Derive `Debug`, `Clone`, `PartialEq` on data types by default — add `Eq`, `Hash`, `Serialize` only when needed

## 2. Design the Error Hierarchy

Build typed errors before writing fallible code:
- Define a crate-level error enum with `thiserror`: one variant per failure category
- Each variant wraps the underlying error type: `#[error("database query failed")] Db(#[from] sqlx::Error)`
- Application binaries use `anyhow` for top-level error handling; libraries never do
- Map external errors at crate boundaries — don't leak third-party types through public APIs

## 3. Encode Invariants in the Type System

Use the compiler to prevent invalid states:
- **Typestate pattern**: `struct Order<S: State>` with `impl Order<Draft>` and `impl Order<Confirmed>` — impossible to ship an unconfirmed order
- **Enums over booleans**: `enum Visibility { Public, Private }` instead of `is_public: bool`
- **NonZero types** for values that must not be zero: `NonZeroU32` for counts, ports, IDs
- **Builder pattern** for types with many optional fields — `Default` + method chaining

## 4. Model Ownership and Borrowing

Decide ownership boundaries before writing implementations:
- Functions that only read data take `&self` or `&T`
- Functions that transform data take `self` (owned) and return a new value
- Use `Cow<'_, str>` when a function might or might not need to allocate
- Avoid `Arc<Mutex<T>>` as a first resort — prefer message passing with channels or simpler ownership

## 5. Write Conversion Traits

Define how types transform between layers:
- `From<X>` for infallible conversions (e.g., domain type → API response)
- `TryFrom<X>` for fallible conversions (e.g., raw input → validated domain type)
- Keep conversions in a `convert.rs` or `impl` block near the target type
- Test every `TryFrom` with both valid and invalid inputs

## 6. Verify with the Compiler

Let `cargo` prove the design is sound:
- `cargo check` — zero warnings (`#![warn(clippy::all, clippy::pedantic)]` in `lib.rs`)
- `cargo clippy -- -D warnings` — treat all clippy lints as errors
- `cargo test` — all type-level assertions and conversion tests pass
- If the compiler fights you, the model is wrong — redesign the types, don't add `unwrap()` or `clone()`
