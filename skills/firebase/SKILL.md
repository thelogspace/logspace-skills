---
name: firebase
description: Adds Firebase Crashlytics and Google Analytics to a LogSpace project (Flutter with FlutterFire, Unity Firebase SDK, Analytics only on web) and keeps the event naming standard, environment separation (dev/prod), privacy settings and tests. Use for "firebase", "crashlytics", "analytics", "event ekle", "crash raporu".
---

# LogSpace Firebase (Crashlytics + Analytics)

Added by default in every project; skipped only when the user says so.

## Environments

Each app has **two Firebase projects**: `<name>-dev` and `<name>-prod`. Debug/dev data never pollutes production metrics.
- Flutter: the same package ID is registered in both Firebase projects; `flutterfire configure --project=<name>-dev --out=lib/firebase_options_dev.dart` (likewise for prod). At runtime, the options are selected by `ENV` (`--dart-define-from-file=config/<env>.json`). No native flavors needed (KISS).
- Unity: a separate `google-services.json` / `GoogleService-Info.plist` per environment; the build script selects it.
- Creating the Firebase project requires access to the console. If `firebase login` / `flutterfire` isn't authorized, ask the user to type `! firebase login`.

Config files (`google-services.json`, `GoogleService-Info.plist`, `firebase_options*.dart`) are **not secrets** (Google says so) and may be in the repo; but in CI they're injected from secrets per environment.

## Per-stack setup

| Stack | Packages | Note |
|---|---|---|
| Flutter | `firebase_core`, `firebase_crashlytics`, `firebase_analytics` | `FlutterError.onError` + `PlatformDispatcher.instance.onError` → Crashlytics; dSYM / `--split-debug-info` symbols are uploaded in CI |
| Unity | Firebase Unity SDK (`FirebaseAnalytics`, `FirebaseCrashlytics`) via `.tgz` UPM packages | Initialize after `CheckAndFixDependenciesAsync`; IL2CPP symbols are uploaded |
| Web-game | Firebase runs in the Flutter shell; the Phaser game sends `{type:"analytics", name, params}` through the JS bridge | the game doesn't load the Firebase JS SDK |
| Next.js / Three.js | Firebase JS `analytics` (only if needed), loaded lazily after cookie consent | no Crashlytics; use the browser's error reporting if needed |

## Events

- One file, one place: `Analytics` wrapper (Flutter: `lib/core/analytics/`, Unity: `Analytics.cs`, web: `src/analytics.ts`). The rest of the code never calls the SDK directly → it can be mocked in tests.
- Names: `snake_case`, verb_noun: `level_start`, `level_complete`, `purchase_click`. Use Firebase's recommended event names when they fit (`level_start`, `level_end`, `purchase`, `ad_impression`).
- No personal data (e-mail, name) in event params.
- Debug builds: Analytics `setAnalyticsCollectionEnabled(false)` or the dev project; Crashlytics collection is off in debug.

## Consent

With ads, the consent state goes through `logspace:monetization` (UMP); Analytics consent mode (`ad_storage`, `analytics_storage`, `ad_user_data`, `ad_personalization`) is updated from it.

## Tests

- The wrapper sends the right event names and params (mock SDK).
- An uncaught error reaches the crash reporter (mock).
- Collection is off in debug.

The Data Safety form and the Privacy Manifest must include Firebase (`logspace:store-compliance`).
