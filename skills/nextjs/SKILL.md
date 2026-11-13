---
name: nextjs
description: Next.js stack of LogSpace (App Router, TypeScript strict, Tailwind, next-intl 13 languages, Vitest, Playwright + axe). Sets up the website skeleton, SEO, security headers, env validation, scripts contract and CI. Also the rulebook for every Next.js coding task. Use for "website", "web sitesi", "next.js", "sayfa ekle", "landing", and from the init flow for website.
---

# LogSpace Next.js

Before writing code: `references/best-practices.md` and `references/pitfalls.md`. Follow the documentation of the **installed** Next.js version (`node_modules/next/package.json`); APIs change between majors (e.g. `middleware.ts` → `proxy.ts` in Next 16).

## 1. Create

```bash
pnpm create next-app@latest . --ts --tailwind --eslint --app --src-dir --import-alias "@/*" --use-pnpm
pnpm add next-intl zod
pnpm add -D vitest @vitest/coverage-v8 @vitejs/plugin-react jsdom @testing-library/react @testing-library/jest-dom \
  @playwright/test @axe-core/playwright prettier prettier-plugin-tailwindcss
```

`create-next-app`'s flags can change between versions; check them with `--help`, and if it asks interactively, choose: TypeScript, ESLint, Tailwind, `src/`, App Router, alias `@/*`.

`tsconfig.json`: `"strict": true`, `"noUncheckedIndexedAccess": true`. ESLint: the flat config (`eslint.config.mjs`) created by create-next-app + `jsx-a11y` strict rules; run with `eslint .`, not `next lint`.

## 2. Structure

```
src/
  app/
    [locale]/
      layout.tsx        # <html lang dir>, fonts, NextIntlClientProvider
      page.tsx
      about/page.tsx    # logspace:about
      not-found.tsx
    sitemap.ts  robots.ts  manifest.ts
  components/           # shared UI (Server Components by default)
  features/<feature>/   # feature-specific components + logic
  lib/                  # pure functions (tested)
  i18n/                 # routing.ts, request.ts (next-intl)
  config/
    env.ts              # zod-validated env
    brand.json          # from logspace:about
  middleware.ts         # next-intl routing (proxy.ts in Next 16+)
messages/<locale>.json  # 13 languages
tests/unit, tests/e2e
```

## 3. Mandatory settings

- **i18n**: next-intl with `localePrefix: 'as-needed'` (`/` en, `/tr` ...); `generateStaticParams` for every locale; `hreflang` alternates; `dir="rtl"` for `ar`.
- **SEO**: `generateMetadata` on every page (localized title/description, canonical, OG/Twitter); `sitemap.ts` with all locales; `robots.ts`; OG image (`opengraph-image.tsx`).
- **Security headers** (`next.config.ts` → `headers()`): `Content-Security-Policy`, `Strict-Transport-Security`, `X-Content-Type-Options: nosniff`, `Referrer-Policy: strict-origin-when-cross-origin`, `Permissions-Policy`, `frame-ancestors 'none'` (in CSP).
- **Env**: `src/config/env.ts` parses `process.env` with zod at startup; a wrong/missing variable fails the build. Only `NEXT_PUBLIC_*` reaches the client.
- **Fonts**: `next/font` (subsets for all 13 languages: latin, cyrillic, arabic, devanagari; CJK via system font or lazily).
- **Images**: `next/image`, with `sizes` given.
- **Analytics** (if `logspace:firebase` is chosen): loaded lazily after cookie consent.

## 4. Scripts contract

Copy `templates/format.sh`, `lint.sh`, `test.sh`, `ci.yml`, and `templates/vitest.config.ts` to the root. E2E (Playwright + axe) runs in CI after `check.sh`; locally with `pnpm exec playwright test`.

## 5. Deploy

The deploy target (Vercel, Cloudflare, own server) is decided per project; ask the user. `develop` → preview/staging, `main` → production.

## 6. Skeleton tests

- Unit: `lib/` functions, env validation (missing variable → error), the About link list.
- Component: the language switcher, the footer links.
- E2E: every locale's home page opens, `lang`/`dir` are correct, **axe finds no violations**, sitemap and robots respond.
- i18n key parity.
