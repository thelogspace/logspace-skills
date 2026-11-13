---
name: i18n
description: Sets up and maintains 13-language support (en, tr, es, pt-BR, fr, de, ru, ar-RTL, hi, zh-Hans, ja, id, ko) in a LogSpace project. Covers the per-stack infrastructure (Flutter gen-l10n, next-intl, Unity Localization, i18next), device language detection, RTL, key naming, translation workflow and the key-parity test. Use when adding text or a new screen, and for "çeviri", "dil ekle", "localization", "i18n", "RTL".
---

# LogSpace Localization (13 languages)

The language list and default language come from `../../shared/brand.json` (`languages`, `defaultLanguage`, `rtlLanguages`). **Never write a user-visible string directly in code.**

## Per-stack infrastructure

| Stack | Infrastructure | Files |
|---|---|---|
| Flutter (app + web-game shell) | `flutter_localizations` + `gen-l10n` (`l10n.yaml`, `nullable-getter: false`) | `lib/l10n/app_<locale>.arb` |
| Next.js | `next-intl` (App Router, `[locale]` segment, middleware) | `messages/<locale>.json` |
| Unity | `com.unity.localization` (String Table Collection) | `Assets/Localization/` |
| Phaser / Three.js | `i18next` (JSON, no plugins needed) | `src/i18n/<locale>.json` |

In the web-game, the Phaser side has its own JSON; the Flutter shell passes the device language to the game through the JS bridge (`setLocale`).

Locale codes: Flutter ARB uses `pt_BR`, `zh_Hans` (in the `zh_Hans` file, `@@locale: "zh_Hans"`); web uses `pt-BR`, `zh-Hans`; Unity uses `pt-BR`, `zh-Hans`. Map them per stack; the language is the same.

## Behavior

- On first launch, the **device language** is used; if it isn't supported, `en`.
- The language can be changed in the settings/About screen; the choice is saved.
- Plurals and variables use ICU format (`{count, plural, one{# item} other{# items}}`); don't build strings by concatenation.
- Dates, numbers and currency are formatted with the locale (`intl` / `Intl.*`).
- Next.js: `hreflang` alternates and a localized `sitemap` for each language.

## RTL (Arabic)

- Flutter: use `EdgeInsetsDirectional`, `AlignmentDirectional`, `start/end`; not `left/right`.
- Web: CSS logical properties (`margin-inline-start`, `ps-*`/`pe-*` in Tailwind), `<html dir>` set per language.
- Unity/Phaser: mirror the UI layout; game-world content doesn't flip. Arabic needs a font that supports shaping (Unity: TextMeshPro + an RTL-capable font / a package like RTLTMPro).
- Fonts: Latin + Cyrillic + Arabic + Devanagari (hi) + CJK (zh, ja, ko). Choose fonts that cover all of them (e.g. the Noto family) and include only the subsets you need.

## Keys

- Format: `screen_element_meaning` → `about_youtube_label`, `game_over_title`.
- One key, one meaning; don't reuse a key in a different context just because the text is the same.
- Every key has a description for the translator (`@key.description` in ARB).

## Translation workflow

1. Add a key with **one call**, for all 13 languages at once, without reading the locale files (saves tokens):
   `scripts/i18n-add.sh [--dir <dir>] <key> '{"en":"...","tr":"...",...,"@description":"..."}'`
   (template: `templates/i18n-add.sh`). It's all-or-nothing: if a language is missing, no file is changed. Dotted keys (`home.play`) become nested in JSON.
2. `en` and `tr` are written by the developer / checked by them; Claude writes the other 11. Every added key goes into `.logspace/i18n-review.json` for human review.
3. The review list is checked before the store release.
4. Unity: string tables are YAML assets; don't edit them as text. Keep the source of truth in `Assets/_Project/Localization/strings.csv` and import it with the Localization package's CSV extension.

## Test (mandatory)

A **key-parity test** in every stack: all language files must contain the same keys as `en`, with no empty values, and placeholders (`{name}`) must match. A missing translation fails CI.

Store listing (name, short description, description, ATT text) is kept for 13 languages too: `store/listing/<locale>.json`.
