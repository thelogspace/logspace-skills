---
name: web-game
description: LogSpace web-based mobile game stack. A Phaser 4 + Vite + TypeScript game, run inside a Flutter shell's WebView (official webview_flutter, no Capacitor). Sets up the monorepo, the JS↔Flutter bridge, the loopback asset server, lifecycle, build pipeline, scripts and CI. The same shell is used for Three.js apps that go to mobile. Also the rulebook for every Phaser coding task. Use for "web oyun", "phaser", "html5 oyun", "oyun köprüsü", and from the init flow for web-game.
---

# LogSpace Web Game (Phaser 4 + Flutter shell)

Before writing code: `references/best-practices.md` and `references/pitfalls.md` (Phaser), plus the `logspace:flutter` references for the shell. Every step below was verified end to end on 2026-11-14 with a real project (build, APK, Android emulator).

## 1. Structure (monorepo)

```
<name>/
  game/                 # Phaser 4 + Vite + TS (runs in the browser on its own: pnpm dev)
    src/
      main.ts           # i18n, bridge, Phaser.Game config, e2e test hooks (?e2e=1)
      scenes/           # menu, game, game over... rendering only
      logic/            # PURE TS game rules (no Phaser import) → tested with Vitest
      bridge.ts         # Flutter bridge (no-op in the browser)
      i18n/             # i18next + 13 locale JSON files
    public/assets/      # atlases, audio
    tests/logic/        # vitest
    tests/e2e/          # playwright: smoke + memory (logspace:perf)
  app/                  # Flutter shell (logspace:flutter, created with --project-name <idSegment>)
    lib/features/game/  # GameScreen (webview_flutter), GameBridge, AssetServer
    assets/game/        # game/dist is copied here at build time (gitignored except .gitkeep)
  scripts/              # contract scripts for both sides
```

## 2. Create the game

```bash
pnpm create vite game --template vanilla-ts
cd game && pnpm add phaser@latest i18next
pnpm add -D vitest @vitest/coverage-v8 eslint @eslint/js typescript-eslint prettier @playwright/test @types/node
pnpm add -D typescript@^6   # see the TypeScript note
```

- Check that `phaser@latest` is major **4** (`import * as Phaser from 'phaser'`: v4 ships named exports only).
- **TypeScript note:** the Vite template installs TypeScript 7, which `typescript-eslint` doesn't support yet (it refuses to run). Pin `typescript@^6` until typescript-eslint supports the newer major; re-check on every audit.
- `tsconfig.json`: the template's file has comments (JSONC): edit it by hand, `jq` can't parse it. Add `"strict": true`, `"noUncheckedIndexedAccess": true`, `"resolveJsonModule": true`, `"types": ["vite/client", "node"]`, include `tests`.
- `vite.config.ts` (from `vitest/config`): `base: './'` (relative paths, required in the WebView); `build.target: 'es2022'` (top-level `await` needs it; current Android WebView and iOS Safari support it); `build.assetsInlineLimit: 0`; `build.chunkSizeWarningLimit` = the `initialJsKB` budget (Phaser alone is ~1.4 MB).
- `templates/eslint.config.js`: typescript-eslint `strict`; in `tests/` the non-null assertion rule is off (a missing value fails the test anyway). Inline `eslint-disable` stays forbidden (guard).
- Delete the Vite starter files (`counter.ts`, `style.css`, `src/assets`, `public/icons.svg`).

### Official Phaser skills

Phaser 4 ships its own agent skills **inside the npm package** (`node_modules/phaser/skills`, MIT, always matching the installed version). `templates/sync-phaser-skills.sh` → `scripts/`; run it after installing or upgrading Phaser. It copies a selected subset to `.claude/skills/phaser-*` (each skill's description costs context tokens every session; override the list with `PHASER_SKILLS="..."`). These replace community Phaser skills.

## 3. Create the shell

```bash
flutter create --org xyz.logspace --project-name <idSegment> --platforms ios,android --empty app
cd app && flutter pub add webview_flutter
```

Apply the other `logspace:flutter` steps (packages, structure, analysis_options, l10n) to `app/`.

**Why not flutter_inappwebview:** its last release is from 2024-10 and it doesn't build with the current Android Gradle Plugin (`proguard-android.txt` is rejected). The official `webview_flutter` plus our own small asset server is maintained and has no such risk.

## 4. Bridge and asset server

Templates (replace `<idSegment>`):

| Template | Target |
|---|---|
| `bridge.ts` | `game/src/bridge.ts` |
| `asset_server.dart` | `app/lib/features/game/asset_server.dart` |
| `game_bridge.dart` | `app/lib/features/game/game_bridge.dart` |
| `game_screen.dart` | `app/lib/features/game/game_screen.dart` |
| `asset_server_test.dart` | `app/test/features/game/asset_server_test.dart` |
| `network_security_config.xml` | `app/android/app/src/main/res/xml/` |

- **AssetServer:** a `dart:io` HttpServer bound to `127.0.0.1` on a random free port. It serves **only** the keys listed in Flutter's `AssetManifest` under `assets/game` (a whitelist: no traversal, nothing else from the bundle). ES modules and fetch don't work over `file://`, so this is required.
- **Transport:** game → shell through the JavaScript channel `window.logspace.postMessage(json)`; shell → game with `runJavaScript("window.logspaceBridge.receive(...)")`.
- **Messages** are JSON `{type, ...}`; both sides declare their types. Start with `ready`, `haptic` (game → shell) and `setLocale`, `pause`, `resume` (shell → game). Add `analytics` (logspace:firebase) or `showRewarded`/`rewardResult` (logspace:monetization) only when the project uses them. An unknown message is logged, never crashes.
- **Language:** the shell passes the app's language as `?lang=` on the URL (the WebView's `navigator.languages` follows the device, not the in-app setting).
- **Lifecycle:** `AppLifecycleListener` → `pause`/`resume`; the game sleeps its loop (also on `visibilitychange`).
- **Platform settings** (otherwise a white screen):
  - Android: `network_security_config.xml` allows cleartext **only** for `localhost` and `127.0.0.1`; reference it with `android:networkSecurityConfig` in the manifest.
  - iOS `Info.plist`: `NSAppTransportSecurity` → `NSAllowsLocalNetworking = true` (local only, not the whole ATS).
- In the browser (`pnpm dev`) the bridge is a no-op: the game is developed and tested without Flutter.

## 5. Build

`templates/build-game.sh` → `scripts/build-game.sh`: builds the game and copies `game/dist/*` to `app/assets/game/`. Run it before every `flutter build` / `flutter run` (CI too).

**Flutter asset folders are not recursive.** Every folder of the game build (`assets/game/`, `assets/game/assets/`, ...) must be listed under `flutter.assets` in `app/pubspec.yaml`, or its files are silently missing from the APK/IPA and the game shows a black screen. `build-game.sh` fails when a folder isn't declared.

## 6. Scripts contract

Copy `templates/format.sh`, `lint.sh`, `test.sh` and `ci.yml`. They run both sides; `coverage/percent.txt` holds the **lower** of the two coverages.

## 7. Skeleton tests

- `game/tests/logic/*.test.ts`: the game rules (pure TS), seeded RNG, catalog/level validation (logspace:game-design).
- `game/tests/logic/*bridge*.test.ts`: no-op in the browser, JSON over `postMessage` when hosted, listeners unsubscribe; i18n key parity.
- `game/tests/e2e/smoke.spec.ts`: the game boots (with `?lang=`), a full game plays through the test hooks, no console errors. `memory.spec.ts` from logspace:perf.
- `app/test/features/game/`: `asset_server_test.dart` (loopback, content types, 404, nothing outside the game), `game_bridge_test.dart` (routing, invalid input never throws).
- Shell: about, i18n key parity, router (logspace:flutter).

## 8. Verify on a device

Unit and e2e tests don't prove the WebView loads the game. Before the first release, and after changing the shell:
1. `scripts/build-game.sh && (cd app && flutter build apk --debug)`
2. Check the APK actually contains the game: `unzip -l app/build/app/outputs/flutter-apk/app-debug.apk | grep assets/game/` must list the JS bundle.
3. Install on an emulator/device, open the game, and check `adb logcat` for the `Phaser v4... (WebGL ...)` line served from `http://127.0.0.1:<port>`.
