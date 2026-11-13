# Phaser / WebView Common Mistakes

| Mistake | Right way |
|---|---|
| Game rules written inside a scene (untestable) | Pure TS in `src/logic/`; the scene calls it |
| `new Sprite` / `destroy` every frame | Pool with `Group.get()` |
| Separate PNG for every sprite | Texture atlas |
| `update()` depends on frame rate (`x += 5`) | Multiply by `delta`: `x += speed * delta / 1000` |
| Resolution = `devicePixelRatio` (3x) | `Math.min(dpr, 2)` |
| Audio starts at boot, nothing plays on iOS | Start audio after the first touch |
| Game keeps running in the background (battery, sound) | `pause`/`resume` via the bridge + `visibilitychange` |
| Loading the game from `file://` (modules and fetch break) | The template `AssetServer` (loopback HTTP); Vite `base: './'` |
| Cleartext HTTP blocked → white screen | iOS `NSAllowsLocalNetworking`, Android localhost-only network security config |
| Not unbinding event listeners when the scene closes (`this.input.on`, `this.events.on`) | Clean up in `shutdown` / use `once` |
| Changing a `Text` every frame | BitmapText; update only when the value changes |
| Hardcoded text in the scene | i18next key; locale comes from the bridge |
| Calling an ad SDK directly from the game | Request via the bridge (`showRewarded`); the shell manages it |
| Using `Math.random` directly (untestable) | An injected RNG with a seed |
| Not watching the bundle size | `vite build --report` / rollup-plugin-visualizer |
| Flutter asset folder listed, its subfolders not (assets are not recursive) → JS bundle missing from the APK, black screen | List every build folder in pubspec.yaml; `build-game.sh` checks it |
| `flutter_inappwebview` (unmaintained since 2024-10; fails with the current Android Gradle Plugin) | Official `webview_flutter` + the template `AssetServer` |
| TypeScript 7 from the Vite template → typescript-eslint refuses to run | Pin `typescript@^6` until typescript-eslint supports it |
| `build.target: 'es2020'` with top-level `await` in main.ts | `es2022` |
| Language from `navigator.languages` inside the WebView (follows the device, not the in-app setting) | The shell passes `?lang=`; the game falls back to `navigator.languages` only in the browser |
| `test.skip(browserName !== 'chromium')` in a Chromium-only test (guard rejects skips; a skipped test looks green) | `test.use({ browserName: 'chromium' })` |
