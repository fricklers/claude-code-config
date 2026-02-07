---
description: Supabase client-side conventions
globs:
  - "**/supabase/**"
  - "**/*supabase*"
  - "**/lib/db*"
---

## Auth

- Client-side: use `getSession()` for reading auth state (cached, fast)
- Server-side / edge functions: use `getUser()` (validates with Supabase Auth, not just the JWT)
- Never trust client-side auth for write operations — always verify server-side
- Store the Supabase client as a singleton — don't recreate on every request

## Row-Level Security

- Every table gets at least one RLS policy — no exceptions
- Default deny: `ALTER TABLE t ENABLE ROW LEVEL SECURITY` with no policies = blocked
- Test policies with different roles: anon, authenticated, service_role
- Avoid `security definer` functions unless absolutely necessary — they bypass RLS

## Migrations

- One migration per feature — keep them focused and reviewable
- Always write a `down` migration for rollback
- Never rename or drop a column in the same deploy that removes code using it — do it in two deploys
- Test rollback: `supabase db reset` should succeed after applying then reverting

## Edge Functions

- Follow Deno conventions: top-level imports, `Deno.serve()` handler
- Validate request bodies with Zod or similar — never trust client input
- Return proper HTTP status codes: 400 for bad input, 401/403 for auth, 500 for server errors
- Set CORS headers explicitly — don't use wildcards in production

## Realtime

- Subscribe with filters to reduce message volume: `.on('postgres_changes', { filter: 'id=eq.123' })`
- Always unsubscribe on cleanup — return the cleanup function from `useEffect`
- Handle reconnection — Supabase Realtime auto-reconnects, but UI should show connection status

## Types

- Generate types after every migration: `supabase gen types typescript --local > src/types/database.ts`
- Use generated types in all Supabase client calls: `supabase.from<Database['public']['Tables']['users']['Row']>('users')`
- Keep generated types in version control — they serve as documentation
