---
name: audit
description: Audits an existing LogSpace project end to end against the current LogSpace standard and offers fixes. Checks the guard, quality gates, drift from the plugin templates, i18n completeness, About/legal state, store compliance freshness, monetization rules, stack best practices and ponytail-style bloat. Use when the session warns of a version mismatch, periodically (e.g. before every release), and for "denetle", "audit", "standarda uyuyor mu", "projeyi kontrol et".
---

# LogSpace Project Audit

Continuous supervision has three layers; this skill is the deepest:

| Layer | When | What |
|---|---|---|
| Plugin hooks (automatic) | every session, every command, every edit, every finish | rules reminder, dangerous git commands blocked, format+lint, `check.sh` |
| `scripts/guard.sh` (automatic) | every `check.sh`: pre-push and CI on every PR | required files, lint suppression, focused tests, hardcoded brand values, secrets |
| **This skill** (on demand) | version mismatch warning, before a release, periodically | full standard check + drift + fix suggestions |

## Steps

Report each step as ✓ / ⚠ / ✗. **Don't change anything until the end**; show all findings first, then get the user's approval for the fixes.

1. **Basic check:** `scripts/check.sh` (format, lint, guard, tests, coverage).
2. **Template drift:** compare the project's files with the plugin's current templates:
   - `scripts/check.sh`, `scripts/guard.sh`, `scripts/setup.sh`, `.githooks/*` ↔ `logspace:quality` templates
   - `.github/workflows/release-please.yml`, `back-merge.yml`, PR template ↔ `logspace:versioning`
   - `.github/workflows/store-compliance.yml`, `scripts/check-android-target.sh` ↔ `logspace:store-compliance`
   - `.github/workflows/ci.yml`, `scripts/{format,lint,test}.sh` ↔ the stack skill
   - `.claude/settings.json` ↔ `logspace:quality/templates/claude-settings.json`
   - If a project file differs, show the diff; separate intentional project changes from outdated ones.
3. **Brand:** do the values in the project's `.logspace/brand.json` match `shared/brand.json` (excluding the project's own legal links)?
4. **i18n:** do all 13 languages exist, does the key-parity test pass, how many items are in the `needsReview` list?
5. **About / legal:** are the links set; are the privacy policy sections consistent with the SDKs actually used (Firebase, AdMob, Unity Ads, IAP)?
6. **Store (mobile):** what is the `checkedAt` date in `.logspace/compliance.json`? If it's older than 30 days, run `logspace:store-compliance`.
7. **Monetization:** test/real ad ID separation, consent order (UMP → ATT → SDK init), Restore Purchases button.
8. **Stack best practices:** scan the code against the `best-practices.md` + `pitfalls.md` references of the stack skill; give file:line for each violation.
9. **Bloat:** run `ponytail-audit` (if installed); separate unnecessary abstractions, dead code and dependencies.
9a. **Map and structure:** does `docs/MAP.md` still describe the code (flow, data flow, dependency direction), beyond what the guard checks mechanically?
9b. **Performance:** do the leak tests exist and pass; are hot paths covered by no-allocation tests; is the last measured value of each budget in `.logspace/budgets.json` recorded? List the budgets never measured.
9c. **Games:** do level validation tests exist (schema, reachability, difficulty curve, economy); is `docs/game/levels.md` generated and current; is the GDD current?
9d. **Third-party skills:** for each entry in `.logspace/third-party-skills.lock.json`, is there a newer upstream SHA (`git ls-remote`)? If so, follow the update review in `logspace:third-party`. Check that the project's lock still matches the plugin catalog.
9e. **Work discipline:** are ponytail and superpowers enabled in `.claude/settings.json`; does `CLAUDE.md` have the "Work discipline" section? Do features merged since the last audit have a plan in `docs/superpowers/` and tests that arrived with (not after) the code?
10. **Git:** are `main`/`develop` protected, does the default branch `develop`, any stale branches.

## Ending

- Findings table: severity (✗ blocking / ⚠ should fix / ℹ info), file:line, what to do.
- After approval, apply the fixes on a `chore/logspace-audit` branch, with Conventional Commits.
- When the templates have been synced, update `logspaceSkillsVersion` in `.logspace/project.json` to the current plugin version (this silences the session warning).
