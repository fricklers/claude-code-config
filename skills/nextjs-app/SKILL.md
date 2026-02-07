---
name: nextjs-app
description: Next.js App Router architecture workflow. Navigates server vs client components, caching tiers, and Server Actions.
---

When this skill is active, follow this 7-step discipline for Next.js App Router development:

## 1. Default to Server Components

Every component is a Server Component unless it needs interactivity:
- Server Components can `async/await` directly, access databases, read files, and call APIs without exposing secrets
- Add `'use client'` only when the component uses hooks (`useState`, `useEffect`), event handlers, or browser APIs
- Push `'use client'` boundaries as low as possible — wrap the interactive leaf, not the page

## 2. Route and Layout Design

Plan the route tree before creating files:
- `app/<route>/page.tsx` for pages, `app/<route>/layout.tsx` for shared UI
- Use route groups `(marketing)`, `(dashboard)` to organize without affecting URLs
- Co-locate `loading.tsx`, `error.tsx`, and `not-found.tsx` at each route segment
- Use `generateStaticParams` for routes that can be statically generated at build time

## 3. Data Fetching Strategy

Choose the right data pattern for each component:
- **Server Components**: `fetch()` directly in the component — no client-side state management needed
- **Dynamic data**: use `cache: 'no-store'` or `revalidate: 0` for data that changes per request
- **Static data**: default `fetch()` caching or `revalidate: 3600` for content that changes infrequently
- **Client-side**: use `SWR` or `TanStack Query` only for data that must update without navigation (real-time, optimistic UI)

## 4. Server Actions for Mutations

Use Server Actions instead of API routes for form submissions and mutations:
- Define with `'use server'` at the top of the function or file
- Accept `FormData` or typed arguments, return structured results
- Validate input with `zod` on the server — never trust client data
- Call `revalidatePath()` or `revalidateTag()` after mutations to update cached data

## 5. Caching Tiers

Understand and configure each caching layer:
- **Request memoization**: duplicate `fetch()` calls in the same render are deduplicated automatically
- **Data cache**: `fetch()` responses cached across requests — control with `revalidate` or `cache` options
- **Full route cache**: statically rendered routes are cached as HTML — use `dynamic = 'force-dynamic'` to opt out
- **Router cache**: client-side cache of visited routes — use `router.refresh()` to invalidate

## 6. Middleware and Edge

Use middleware for cross-cutting concerns:
- Authentication checks, redirects, and header manipulation in `middleware.ts` at the project root
- Keep middleware lightweight — it runs on every matching request
- Use `matcher` config to limit which routes trigger middleware
- Edge Runtime functions for latency-sensitive operations: geolocation, A/B testing, bot detection

## 7. Verify the Build

Confirm the application works in production mode:
- `npx next build` — zero errors, check for unexpected dynamic routes
- `npx next lint` — all lint rules pass
- Review the build output: static vs dynamic pages, bundle sizes, route segments
- Test Server Actions with form submissions — they must work without JavaScript activated
- If any step fails, fix the issue and re-run the entire chain
