---
name: flutter
description: Flutter stack of LogSpace. Sets up the skeleton of a mobile app (or a web-game's native shell): Riverpod, go_router, feature-first structure, environment config, global error handling, the scripts contract and CI. Also the rulebook for every Flutter coding task (references/best-practices.md, pitfalls.md). Use for "flutter", "mobil uygulama", "ekran ekle", "widget", and from the init flow for mobile-app / web-game.
---

# LogSpace Flutter

Before writing code, follow `references/best-practices.md` and `references/pitfalls.md`. Read them at the start of every Flutter task.

## 1. Create

```bash
flutter --version   # latest stable channel; if not, flutter upgrade (ask the user)
flutter create --org xyz.logspace --project-name <idSegment> --platforms ios,android --empty .
```

`<idSegment>` = the last segment of the package ID (`colorstrix`). That way the Android `applicationId` and the iOS bundle ID are exactly `xyz.logspace.colorstrix`, with no manual edits. The web-game shell is created in the `app/` folder.

Display name: Android `android:label` and iOS `CFBundleDisplayName` = `displayName` (localized names come from `logspace:i18n`).

## 2. Packages

```bash
flutter pub add flutter_riverpod go_router package_info_plus url_launcher shared_preferences intl \
  flutter_localizations --sdk=flutter
flutter pub add dev:very_good_analysis dev:mocktail dev:integration_test --sdk=flutter
```

Don't pin versions; use the latest compatible ones `pub add` picks. **No extra package without a real need** (ponytail). Code generation (riverpod_generator, freezed) isn't added by default; add it only if the project actually needs it.

## 3. Structure

```
lib/
  main.dart              # bootstrap: env → Firebase → error handlers → ProviderScope(App)
  app.dart               # MaterialApp.router: theme, l10n, router
  core/
    config/env.dart      # ENV (dev|prod) from --dart-define-from-file
    brand/brand.dart     # reads assets/brand.json
    router.dart
    analytics/  ads/  purchases/   # (by logspace:firebase / monetization)
  features/
    home/  settings/  about/
      <feature>_screen.dart, <feature>_controller.dart (if needed), widgets/
  l10n/                  # ARB files
assets/brand.json
config/dev.json, config/prod.json   # --dart-define-from-file (no secrets!)
test/                    # mirrors lib/
integration_test/app_test.dart
```

Feature-first; `data/domain/presentation` sublayers are opened **only** when a feature actually needs them (KISS).

`analysis_options.yaml`:

```yaml
include: package:very_good_analysis/analysis_options.yaml
analyzer:
  exclude: ["**/*.g.dart", "lib/l10n/app_localizations*.dart", "lib/firebase_options*.dart"]
  language: { strict-casts: true, strict-inference: true, strict-raw-types: true }
linter:
  rules:
    public_member_api_docs: false   # app code, not a library
```

## 4. Environment

`flutter run --dart-define-from-file=config/dev.json`. `env.dart` exposes `const String.fromEnvironment('ENV')`. The two environments use the same package ID; Firebase selects `firebase_options_dev/prod.dart` from ENV (`logspace:firebase`). Secrets aren't put in `config/*.json`, because the app binary can be decompiled.

## 5. Scripts contract

Copy `templates/format.sh`, `lint.sh`, `test.sh` to `scripts/` (for the web-game, the root versions in that skill). CI: `templates/ci.yml` → `.github/workflows/ci.yml`.

## 6. Android / iOS settings

- `android/app/build.gradle.kts`: `targetSdk` and `compileSdk` **an explicit number**; the value comes from `logspace:store-compliance` (not `flutter.targetSdkVersion`).
- `AndroidManifest.xml`: `android:enableOnBackInvokedCallback="true"`.
- Edge-to-edge: `SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge)` + `SafeArea` where needed.
- Release build: `flutter build appbundle --obfuscate --split-debug-info=build/symbols --dart-define-from-file=config/prod.json --build-number=$GITHUB_RUN_NUMBER`.
- iOS: deployment target = the highest of what Flutter + Firebase + the ads SDK require; `PrivacyInfo.xcprivacy` is present.
- Signing: `key.properties` and keystore come from CI secrets; never into the repo.

## 7. Skeleton tests (minimum)

- `test/app_test.dart`: the app opens, the home screen appears.
- Router: every route opens the right screen.
- l10n key parity (`logspace:i18n`).
- About links (`logspace:about`).
- `integration_test/app_test.dart`: open the app → go to settings → change the language → the text changes.
