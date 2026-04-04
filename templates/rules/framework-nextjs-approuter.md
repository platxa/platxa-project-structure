## Framework Rules — Next.js App Router

- Default to Server Components — only add `"use client"` when using hooks, event handlers, or browser APIs
- Keep Client Components small and leaf-level — push state down, not up
- Use `loading.tsx` for Suspense boundaries, `error.tsx` for error boundaries
- Data fetching belongs in Server Components or Route Handlers, never in Client Components
- Use `next/image` for all images — never raw `<img>` tags
- Colocate components, styles, and tests in the same route segment
