---
name: rust-modeling
description: Rust type and error modeling process. Designs domain enums, error hierarchies, and ownership patterns before writing logic.
---

When this skill is active, follow this 6-step discipline for designing Rust types and error handling:

## 1. Map the Domain to Types

Before writing any logic, sketch the type graph:
- **List every entity and relationship** — draw a dependency diagram (even in comments)
- **One struct per entity, one enum per variant set** — if two concepts have different lifecycles, they're separate types
- **Decide visibility upfront**: which types are `pub`? Which fields? Start private, widen only when needed
- **Write type signatures first** — `fn process(order: &Order) -> Result<Receipt, OrderError>` before any body

## 2. Design the Error Hierarchy

Build the error tree before writing fallible code:
- **Enumerate failure modes**: list every way each operation can fail — network, parse, validation, not-found
- **Group by recovery strategy**: errors the caller can retry vs errors that are fatal determine your variant structure
- **Map external errors at boundaries** — don't leak third-party types through public APIs; wrap them in domain errors
- **Write the `Display` messages for humans**: each `#[error("...")]` string should be actionable, not just descriptive

## 3. Encode Invariants in the Type System

Make illegal states unrepresentable — push validation into types:
- **Typestate pattern**: `struct Order<S: State>` with `impl Order<Draft>` and `impl Order<Confirmed>` — impossible to ship an unconfirmed order
- **Ask "can this field be invalid?"** — if yes, use a newtype that validates on construction
- **NonZero types** for values that must not be zero: `NonZeroU32` for counts, ports, IDs
- **Builder pattern** for types with many optional fields — `Default` + method chaining

## 4. Model Ownership and Borrowing

Decide ownership boundaries before writing implementations:
- **Draw the ownership tree**: which struct owns which data? Where are the borrows?
- **Annotate each function signature** with `&self`, `&mut self`, or `self` — this determines your API's flexibility
- **Identify shared-state points**: if two subsystems need the same data, decide channels vs `Arc` before coding
- **Benchmark before cloning**: if you reach for `.clone()`, measure whether borrowing is feasible first

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
