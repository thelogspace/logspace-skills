---
name: about
description: Adds the About screen to a LogSpace project (LogSpace website, e-mail, YouTube, Instagram, app version, privacy policy, terms of use) and keeps the privacy policy / terms drafts inside the app. At store release, it moves the drafts to Google Docs and updates the links. Use for "hakkında", "about", "gizlilik politikası", "privacy policy", "kullanım koşulları".
---

# LogSpace About Screen and Legal Texts

The link and contact values come **only** from `../../shared/brand.json`. When the project is created, they're copied into the project config (`.logspace/brand.json`), and the app reads them from there (Flutter: `assets/brand.json`, web: `src/config/brand.json`, Unity: a `BrandConfig` ScriptableObject). If a link changes, update brand.json and rerun this skill.

## About screen content

| Item | Source | Behavior |
|---|---|---|
| App name + icon | project.json `displayName` | |
| Version | at runtime (`package_info_plus` / `Application.version` / `package.json`) | `1.2.0 (42)` format, with the build number |
| LogSpace website | `website` | opens in the external browser |
| E-mail | `email` | `mailto:`, subject prefilled: `<displayName> <version>` |
| YouTube | `youtube` | opens the app if installed, otherwise the browser |
| Instagram | `instagram` | same |
| Privacy policy | `legal.privacyPolicyUrl` | if the URL is `TODO_...`, the draft **bundled in the app** is shown |
| Terms of use | `legal.termsUrl` | same |
| Privacy settings | if there are ads | button that reopens the UMP consent form (GDPR requirement) |
| Open-source licenses | Flutter `showLicensePage`, others a generated list | |
| © year LogSpace | | |

All labels are in the 13 languages (`logspace:i18n`); the screen is tested in RTL too.

Placement: mobile app → in the settings menu; game → a small ⓘ button in the main menu; website → footer + `/about` page.

## Tests

- Every link goes to the expected URL from brand.json (open the URL through a mockable launcher).
- The version text matches the running version.
- When the URL is `TODO_...`, the in-app draft opens.

## Legal drafts (inside the app)

When the project is created, fill `templates/privacy-policy.md` and `templates/terms.md` from project.json:
- `docs/legal/privacy-policy.en.md`, `docs/legal/privacy-policy.tr.md`
- `docs/legal/terms.en.md`, `docs/legal/terms.tr.md`

Include only the sections the project actually uses (Firebase, AdMob, Unity Ads, IAP). The drafts are also bundled into the app as assets (shown offline). The top of each draft says "DRAFT — must be legally reviewed before publishing".

## Store release: publish

1. Remove the "DRAFT" note from the draft; get the user's approval that it was legally reviewed.
2. Create a Google Docs document (if a Google Docs connector is available, through it; otherwise ask the user to create it from the content you produce).
3. In Google Docs: **File → Share → Publish to web**, and get the link (`https://docs.google.com/document/d/e/.../pub`).
4. Write the links to `legal.privacyPolicyUrl` / `termsUrl` in the project's `.logspace/brand.json`; commit with `docs(legal): publish privacy policy`.
5. Enter the same link in Play Console and App Store Connect.

`logspace:store-compliance` blocks the release while a link is still `TODO_...`.
