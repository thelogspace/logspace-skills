---
name: web-game
description: LogSpace web-based mobile game stack. A Phaser 4 + Vite + TypeScript game, run inside a Flutter shell's WebView (no Capacitor). Sets up the monorepo, the JS↔Flutter bridge, lifecycle, build pipeline, scripts and CI. The same shell is used for Three.js apps that go to mobile. Also the rulebook for every Phaser coding task. Use for "web oyun", "phaser", "html5 oyun", "oyun köprüsü", and from the init flow for web-game.
---

# LogSpace Web Game (Phaser 4 + Flutter shell)

Before writing code: `references/best-practices.md` and `references/pitfalls.md` (Phaser), plus the `logspace:flutter` references for the shell.

## 1. Structure (monorepo)

```
<name>/
  game/                 # Phaser 4 + Vite + TS (runs in the browser on its own: pnpm dev)
    src/
      main.ts           # Phaser.Game config
      scenes/           # Boot, Preload, Menu, Game, GameOver
      logic/            # PURE TS game rules (no Phaser import) → tested with Vitest
      bridge.ts         # Flutter bridge (no-op in the browser)
      i18n/             # i18next + 13 languages JSON
    public/assets/      # atlases, audio
    tests/              # vitest (logic) + e2e (playwright smoke)
  app/                  # Flutter shell (logspace:flutter, created with --project-name <idSegment>)
    lib/features/game/  # GameScreen: WebView + bridge
    assets/game/        # game/dist is copied here at build time (gitignored)
  scripts/              # contract scripts for both sides
```

## 2. Create

```bash
# game
pnpm create vite game --template vanilla-ts
cd game && pnpm add phaser@latest i18next
pnpm add -D vitest @vitest/coverage-v8 eslint @eslint/js typescript-eslint prettier @playwright/test
```

Check that `phaser@latest` is major version **4**; if v4 isn't stable yet, use the latest stable major and tell the user.

`vite.config.ts`: `base: './'` (relative paths are required for the WebView); `build.assetsInlineLimit: 0`; `build.target: 'es2020'`.
TS: `"strict": true`, `"noUncheckedIndexedAccess": true`.

```bash
# shell (from the root)
flutter create --org xyz.logspace --project-name <idSegment> --platforms ios,android --empty app
cd app && flutter pub add flutter_inappwebview
```

Apply the other `logspace:flutter` steps (packages, structure, analysis_options) to `app/`.

## 3. Bridge

Templates: `templates/bridge.ts` → `game/src/bridge.ts`, `templates/game_screen.dart` → `app/lib/features/game/game_screen.dart`.

- The game is served from `assets/game/` by `InAppLocalhostServer` (`http://localhost:<port>/`): ES modules, fetch and audio work as on the web. `file://` isn't used.
- Messages are JSON `{type, ...}`. Game → Flutter: `analytics`, `showRewarded`, `showInterstitial`, `haptic`, `ready`. Flutter → game: `setLocale`, `pause`, `resume`, `rewardResult`.
- Flutter side: `AppLifecycleListener` → sends `pause`/`resume` to the game; the game stops its sound and loop.
- In the browser (`pnpm dev`), the bridge is a no-op: the game can be developed and tested without Flutter.
- The message types are defined on both sides; an unknown message is logged, never crashes.
- **Platform settings for localhost** (otherwise you get a white screen):
  - iOS `Info.plist`: `NSAppTransportSecurity` → `NSAllowsLocalNetworking = true` (only local, not the whole ATS).
  - Android: `res/xml/network_security_config.xml` with cleartext allowed **only** for `localhost`, referenced by `android:networkSecurityConfig` in the manifest.

## 4. Build

`templates/build-game.sh` → `scripts/build-game.sh`: `pnpm --dir game build` → copies `game/dist/*` to `app/assets/game/`. It runs before every `flutter build` / `flutter run` (CI too). `app/assets/game/` is in `.gitignore`.

## 5. Scripts contract

Copy `templates/format.sh`, `lint.sh`, `test.sh` and `ci.yml`. They run both sides; `coverage/percent.txt` holds the **lower** of the two coverages.

## 6. Skeleton tests

- `game/tests/logic/*.test.ts`: score, level progression, collision rules (pure TS).
- `game/tests/bridge.test.ts`: messages are serialized correctly; no-op in the browser.
- `game/tests/e2e/smoke.spec.ts` (Playwright): the game opens, the canvas is drawn, there are no console errors.
- `app/test/game_bridge_test.dart`: incoming messages are routed to the right service (analytics/ads fake).
- Shell: about, i18n key parity, router (logspace:flutter).
