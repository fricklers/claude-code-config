---
name: react-design
description: React component design process. Covers decomposition, state ownership, accessibility, and contract testing.
---

When this skill is active, follow this 6-step discipline when designing React components:

## 1. Decompose Before Building

Sketch the component tree before writing JSX:
- Identify the smallest reusable pieces — a component should do one thing
- Name components after what they represent, not what they render: `UserAvatar`, not `CircleImage`
- Separate **container components** (data fetching, state) from **presentational components** (rendering, styling)
- Co-locate related files: `UserCard.tsx`, `UserCard.test.tsx`, `UserCard.module.css`

## 2. Define the Component Contract

Design the props interface before implementing the component:
- Export the props type: `export interface UserCardProps { ... }`
- Use discriminated unions for variant props: `{ variant: 'compact' } | { variant: 'full'; bio: string }`
- Require only what the component needs — prefer many small props over one config object
- Use `children` for composition, `renderX` props for slot patterns, `as` prop for polymorphism

## 3. Assign State Ownership

Decide where each piece of state lives before writing hooks:
- **Inventory every piece of state** the feature needs — list them all before placing any
- **Categorize each one**: UI-local (open/closed), shared (lifted), server-fetched, or URL-persisted
- **Draw the data flow**: which component owns each state, which receive it as props, which dispatch updates
- **Identify derived state**: if a value can be computed from other state, compute it — don't store it separately
- Rule: if two components need the same state, lift it — don't sync with `useEffect`

## 4. Build Accessibility In

Accessibility is part of the design, not an afterthought:
- Use semantic HTML: `<button>`, `<nav>`, `<main>`, `<dialog>` — not `<div onClick>`
- Add ARIA attributes only when semantic HTML is insufficient: `aria-label`, `aria-expanded`, `role`
- Support keyboard navigation: focus management, `tabIndex`, `onKeyDown` for custom interactions
- Test with a screen reader or `axe-core`: `npm run test -- --reporter=axe`

## 5. Handle All UI States

Every data-driven component renders four states:
- **Loading**: skeleton or spinner — never a blank screen
- **Empty**: helpful message with a call to action
- **Error**: actionable message with a retry option — show what went wrong
- **Success**: the actual content with proper transitions
- Use error boundaries (`ErrorBoundary`) to catch rendering failures without crashing the app

## 6. Test the Component Contract

Write tests against the public API, not internal implementation:
- Render with different prop combinations — especially edge cases and discriminated union variants
- Simulate user interactions: click, type, submit — use `@testing-library/user-event`
- Assert on visible output: text content, ARIA roles, element presence — never test internal state
- Test accessibility: `expect(screen.getByRole('button')).toBeInTheDocument()`
- Run with `npx vitest` or `npx jest` — zero failures
