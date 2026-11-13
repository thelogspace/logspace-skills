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
| Loading the game from `file://` (modules and fetch break) | `InAppLocalhostServer`; Vite `base: './'` |
| Cleartext HTTP blocked → white screen | iOS `NSAllowsLocalNetworking`, Android localhost-only network security config |
| Not unbinding event listeners when the scene closes (`this.input.on`, `this.events.on`) | Clean up in `shutdown` / use `once` |
| Changing a `Text` every frame | BitmapText; update only when the value changes |
| Hardcoded text in the scene | i18next key; locale comes from the bridge |
| Calling an ad SDK directly from the game | Request via the bridge (`showRewarded`); the shell manages it |
| Using `Math.random` directly (untestable) | An injected RNG with a seed |
| Not watching the bundle size | `vite build --report` / rollup-plugin-visualizer |
