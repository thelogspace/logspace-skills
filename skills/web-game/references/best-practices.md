# Phaser 4 Best Practices (LogSpace)

## Architecture
- **Game rules live in `src/logic/`, in pure TS** (no Phaser import): score, level, collision decisions, economy. Scenes only render and forward input → the rules can be tested with Vitest.
- Scene flow: `Boot` (minimal config) → `Preload` (all assets + progress bar) → `Menu` → `Game` → `GameOver`. Each scene does one job.
- Config (speeds, levels, prices) lives in a JSON/TS constants file; not scattered across code.
- Communication between scenes: `this.registry` or a small event emitter; no global variables.

## Performance
- **Texture atlas**: combine sprites into an atlas (TexturePacker / free-tex-packer); a single draw call instead of many textures.
- **Object pooling**: bullets, enemies, particles from a `Group` with `get()` / `setActive(false).setVisible(false)`; no `new` + `destroy` every frame.
- No object, array or closure creation in `update()` (GC stutter); reuse temporary `Vector2`s.
- Physics: Arcade Physics is enough (light); Matter only when there's real rigid body need. Keep the number of bodies low; disable physics on static objects.
- Cap the `devicePixelRatio` (`resolution: Math.min(window.devicePixelRatio, 2)`); 3x screens burn the fill rate.
- Scale: `Phaser.Scale.FIT` or `RESIZE` + `autoCenter`; design resolution e.g. 1080x1920 portrait.
- Text: bitmap fonts for scores that change often; a `Text` object re-renders its texture on every change.
- Audio: compressed (`.m4a` + `.ogg`), short effects; music streamed; total size is watched.
- Target 60 FPS; measure on a low-end Android device (inside the WebView).

## Web/WebView-specific
- **Audio unlock**: browsers start audio after the first touch; begin the menu with a "touch to start" step.
- **Visibility**: on `visibilitychange` + the bridge `pause` message, `game.loop.sleep()` and `sound.pauseAll()`.
- **WebGL context loss**: listen to `webglcontextlost`; restore or reload textures.
- Prevent pinch zoom and long-press menu (meta viewport + CSS `touch-action: none`, `user-select: none`).
- Safe area: notch/rounded corners with `env(safe-area-inset-*)`; UI isn't placed in those areas.
- Bundle: the Phaser import is tree-shaken where possible; assets are lazy-loaded per level; total initial download is kept small (bundled into the app, but still affects memory).

## Persistence
- Small data (high score, settings): `localStorage` with a version key (`save.v1`); a migration when the schema changes. Important data (purchases) is kept on the Flutter side.

## Tests
- Logic: Vitest, 100% of the rules (simple pure functions).
- Bridge: the message format, no-op in the browser.
- Playwright smoke: the canvas appears, no console errors, the game reaches the menu.
