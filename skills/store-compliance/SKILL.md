---
name: store-compliance
description: Checks a LogSpace mobile project against the CURRENT Google Play and App Store requirements and applies them (target/compile SDK, 16 KB page size, AAB, 64-bit, edge-to-edge, minimum Xcode/iOS SDK, Privacy Manifest, ATT, Data Safety, privacy policy URL). Never trusts hardcoded values; reads the official sources every time. Use at project start, before every release, when the monthly CI check opens an issue, and for "target sdk", "mağaza reddi", "store requirement", "API level".
---

# LogSpace Store Compliance

**Rule zero: don't write requirement values (API level, Xcode version, dates) from memory or from this file.** Google and Apple raise them every year. Read the sources below **every time**, write the date and the value you found to `.logspace/compliance.json`, and apply them.

## 1. Read the current requirements (official sources)

| Topic | Source |
|---|---|
| Play target API level and deadlines | https://developer.android.com/google/play/requirements/target-sdk and https://support.google.com/googleplay/android-developer/answer/11926878 |
| Latest stable Android API | https://developer.android.com/tools/releases/platforms |
| 16 KB page size | https://developer.android.com/guide/practices/page-sizes |
| Play policy changes | https://support.google.com/googleplay/android-developer/announcements |
| App Store: minimum Xcode / SDK | https://developer.apple.com/news/upcoming-requirements/ |
| Privacy Manifest / required-reason APIs | https://developer.apple.com/documentation/bundleresources/privacy-manifest-files |

If a source can't be read, **say so**; don't fill in a value by guessing.

## 2. Android checklist

| Item | Rule | Where |
|---|---|---|
| `targetSdk` | **Latest stable API level** (Play requires at least the level it currently demands; we stay at the latest so the app isn't removed) | Flutter: `android/app/build.gradle.kts` → a number, **not** `flutter.targetSdkVersion`; Unity: Player Settings → `AndroidTargetSdkVersion` (no "Automatic", a number) |
| `compileSdk` | Same as or newer than `targetSdk` | same file |
| `minSdk` | No lower than what the stack/SDKs need; don't raise it without a reason (narrows the audience) | |
| 16 KB page size | Required for apps with native code: Unity, Flutter, and native libraries in plugins. Verify with the `zipalign -c -P 16 -v 4` check on the AAB/APK and with the Android Studio APK Analyzer | |
| Format | AAB (`flutter build appbundle`, Unity "Build App Bundle") | |
| Architecture | arm64-v8a required (Unity: IL2CPP + ARM64) | |
| Edge-to-edge | Enforced when targeting Android 15+; content mustn't stay under the system bars | |
| Predictive back | Flutter: `android:enableOnBackInvokedCallback="true"` | |
| Data Safety | Must match the data collected by Firebase / AdMob / IAP | Play Console |
| Families policy | If the target audience includes children, ad and analytics settings change; ask the user | |

## 3. iOS checklist

| Item | Rule |
|---|---|
| Xcode / iOS SDK | The minimum version Apple currently demands; check what the CI runner's (`macos-latest`) Xcode version is |
| Privacy Manifest | `PrivacyInfo.xcprivacy` in the app and in every SDK (Firebase, AdMob, Unity); declare the required-reason APIs |
| ATT | If there are ads/tracking: `NSUserTrackingUsageDescription` (13 languages) + the permission prompt **after** the UMP consent |
| Export compliance | `ITSAppUsesNonExemptEncryption = NO` (if there's no custom encryption) |
| Privacy URL | Required in App Store Connect; see section 5 |

## 4. Record

Write `.logspace/compliance.json`:

```json
{
  "checkedAt": "YYYY-MM-DD",
  "android": { "requiredTargetSdk": 0, "latestStableApi": 0, "projectTargetSdk": 0, "pageSize16k": "ok|fail|n/a" },
  "ios": { "minXcode": "", "privacyManifest": "ok|fail|n/a" },
  "sources": ["<URLs read>"]
}
```

## 5. Before release (blocking)

Report on any of these and **stop the release**:
- Project `targetSdk` is below the latest stable API.
- 16 KB check fails.
- The values in `brand.json` / the project config `legal.privacyPolicyUrl` or `termsUrl` are still `TODO_...` → per `logspace:about`, publish the draft to Google Docs and enter the link.
- The Privacy Manifest is missing, or the ATT text isn't in all languages.
- Production builds still use test ad IDs (or debug builds use real ad IDs).

## 6. Monthly automatic check

Copy `templates/store-compliance.yml` to `.github/workflows/` and `templates/check-android-target.sh` to `scripts/`. On the 1st of each month, CI compares the latest stable API in the runner's Android SDK with the project's `targetSdk`; if the project is behind, it opens an issue labeled `store-compliance`. An app waiting in the store is caught before it gets removed. When the issue comes, run this skill.
