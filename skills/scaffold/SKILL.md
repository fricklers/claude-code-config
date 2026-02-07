---
name: scaffold
description: Full-stack feature scaffolding. Forces top-down design before writing code.
---

When this skill is active, work through these layers in order when starting a new feature. Complete each step before moving to the next:

## 1. Data Model

- What tables or columns are needed? Define types, constraints, and relationships
- Write the migration first — the schema is the source of truth
- Consider: indexes needed for expected query patterns, nullable vs required, default values

## 2. Access Control

- Who can read? Who can write? Who can delete?
- Draft RLS policies (Supabase) or middleware checks (API server)
- Default deny — explicitly grant access, never implicitly allow
- Consider: service role vs user role, row-level vs table-level, admin overrides

## 3. API Layer

- Endpoints, edge functions, or direct client queries?
- Define request and response shapes before implementing
- Consider: pagination, filtering, error response format, rate limiting
- If using Supabase client directly: which tables need `.select()` vs RPC calls?

## 4. Shared Types

- TypeScript interfaces that match the DB schema — single source of truth
- Generate from `supabase gen types typescript` or define manually
- Export from a shared location, import everywhere
- Include: request/response types, form state types, error types

## 5. Component Tree

- Sketch the component hierarchy before writing JSX
- Identify state ownership — which component owns which piece of state?
- Plan data flow: props down, events up, server state in query hooks
- Consider: where do loading/error boundaries go?

## 6. Error States

Design all four states for every data-driven view:
- **Loading**: skeleton, spinner, or progressive reveal
- **Empty**: helpful message, call to action, not just blank space
- **Error**: actionable message, retry option, fallback content
- **Unauthorized**: redirect to login or show permission denied

## 7. Test Strategy

Plan tests before writing them:
- **Unit tests**: pure logic, transformations, validators, hooks
- **Integration tests**: API calls with mocked responses, database operations
- **Component tests**: render with different props/states, user interactions
- Identify: what's the riskiest part? Test that first
