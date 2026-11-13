# Next.js Common Mistakes

| Mistake | Right way |
|---|---|
| `"use client"` at the top of the page / layout | Only on the interactive leaf component |
| Fetching data in the client with `useEffect` | Fetch in a Server Component |
| Sequential `await`s (waterfall) | `Promise.all` |
| Secret in a `NEXT_PUBLIC_` variable | Only on the server; `server-only` import |
| Server Action without input validation / authorization check | zod + check in every action |
| `<img>`, `<a href>` for internal links | `next/image`, `next/link` |
| Font via `<link>` from Google Fonts | `next/font` |
| Hydration mismatch (`Date.now()`, `Math.random()`, `window` during render) | Compute on the server or in `useEffect` |
| `localStorage` access during server rendering | Only in a client component, inside `useEffect` |
| Same title/description on every page | `generateMetadata` per page and language |
| Missing `hreflang` / sitemap for languages | next-intl routing + `sitemap.ts` with all locales |
| `margin-left` / `pl-*` (breaks RTL) | Logical properties: `ms-*`, `ps-*` |
| Blocking third-party script in `<head>` | `next/script` with `lazyOnload` / `afterInteractive` |
| Using API advice from another major version | Follow the docs of the installed version |
| `next lint` | `eslint .` (next lint was removed) |
