# Next.js Best Practices (LogSpace)

## Rendering
- **Server Component by default.** `"use client"` only at the leaves that need interactivity (button, form, animation); not on a whole page.
- Static where possible: marketing pages are prerendered for all locales (`generateStaticParams`). Dynamic rendering only for real per-request data.
- Data is fetched on the server; parallel requests use `Promise.all` (no waterfall).
- Slow parts are wrapped in `<Suspense>` + `loading.tsx`; error boundaries via `error.tsx`.
- Caching: be explicit about the cache behavior of `fetch` / data functions in the installed version (it changed between majors); invalidate with `revalidatePath`/`revalidateTag`.

## Performance (Core Web Vitals)
- LCP: the hero image is `next/image` with `priority`; fonts via `next/font` (no layout shift).
- CLS: dimensions are given to images, embeds and ads.
- INP: heavy client JS is avoided; third-party scripts via `next/script` `lazyOnload`.
- Bundle: client components import only what they need; `@next/bundle-analyzer` is checked periodically.
- Lighthouse target: 90+ in all categories on mobile.

## Security
- Server Actions / Route Handlers: **all input is validated with zod**; authorization is checked in each action.
- Secrets only on the server; a module that must never go to the client imports `server-only`.
- CSP + security headers (SKILL.md section 3).
- No `dangerouslySetInnerHTML`; if unavoidable, sanitize.

## SEO and i18n
- A unique title/description per page and per language; canonical + `hreflang` alternates (including `x-default`).
- Semantic HTML: one `h1` per page, `nav`, `main`, `footer`; links are `<Link>`.
- Localized URLs come from next-intl `routing`; texts from `messages/`.

## Accessibility
- `jsx-a11y` lint rules + axe in E2E; keyboard navigation and visible focus.
- Color contrast WCAG AA; images have `alt` text (localized).

## Code
- Tailwind: classes are sorted (prettier-plugin-tailwindcss); a repeated combination is extracted into a component, not into `@apply`.
- Pure logic lives in `lib/` and is tested with Vitest; components stay thin.
- Types: `any` is forbidden; external data is parsed with zod, the type is derived from the schema (`z.infer`).
