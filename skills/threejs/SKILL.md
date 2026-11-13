---
name: threejs
description: Three.js stack of LogSpace (Vite + TypeScript, WebGL; WebGPU where suitable). Sets up the 3D web app skeleton, the render loop, resize, asset pipeline (glTF + Draco/Meshopt + KTX2), dispose discipline, scripts contract and CI. If mobile is chosen, it's packaged in the logspace:web-game Flutter shell. Also the rulebook for every Three.js coding task. Use for "three.js", "3D", "webgl", "sahne", "model yükle", and from the init flow for web-3d.
---

# LogSpace Three.js

Before writing code: `references/best-practices.md` and `references/pitfalls.md`.

## 1. Create

**Web only:** in the project root. **If mobile is chosen as well:** create the `logspace:web-game` monorepo, but put this skill's Three.js app in `game/` instead of Phaser (the shell, bridge and scripts stay the same).

```bash
pnpm create vite . --template vanilla-ts      # (mobile: pnpm create vite game ...)
pnpm add three i18next
pnpm add -D @types/three vitest @vitest/coverage-v8 eslint @eslint/js typescript-eslint prettier @playwright/test
pnpm add -D @gltf-transform/cli               # asset optimization
```

`vite.config.ts`: `base: './'`, `build.target: 'es2022'` (top-level await). TS strict + `noUncheckedIndexedAccess`. Pin `typescript@^6` while typescript-eslint doesn't support TypeScript 7 (the Vite template installs 7); details and the ESLint config: `logspace:web-game` section 2.

## 2. Structure

```
src/
  main.ts            # bootstrap: create the renderer, start the app, connect the UI
  core/
    renderer.ts      # WebGLRenderer settings (pixel ratio cap, color space, tone mapping)
    loop.ts          # setAnimationLoop, delta time, pause/resume
    resize.ts        # ResizeObserver → camera aspect + renderer size
    assets.ts        # GLTFLoader + DRACOLoader/Meshopt + KTX2Loader, cache
    dispose.ts       # disposeObject(object3D): geometry, material, texture
  scenes/            # each scene: create(), update(dt), dispose()
  logic/             # PURE TS rules (no Three.js object needed) → Vitest
  ui/                # DOM overlay: menu, about, language (i18next)
public/
  models/ textures/  # optimized output (originals in assets-src/, outside the build)
assets-src/          # source glb/png (Git LFS)
tests/unit, tests/e2e
```

## 3. Asset pipeline

`templates/optimize-assets.sh` → `scripts/optimize-assets.sh`: for each `.glb` in `assets-src/`, `gltf-transform optimize` (meshopt compression, texture resize, KTX2/WebP) → `public/models/`. KTX2 encoding needs KTX-Software (`toktx`); if it isn't installed, fall back to WebP and tell the user. Store the large source files with Git LFS (`*.glb`, `*.fbx`, `*.blend`, `*.psd` in `.gitattributes`).

## 4. Scripts contract

Copy `templates/format.sh`, `lint.sh`, `test.sh`, `ci.yml` (mobile: use the web-game versions). E2E runs in CI with headless Chromium + SwiftShader (WebGL without a GPU): in `playwright.config.ts`, `use.launchOptions.args: ['--use-angle=swiftshader', '--enable-unsafe-swiftshader']`. For screenshot comparison, use a tolerance (`maxDiffPixelRatio: 0.02`), because GPU rendering differs slightly from machine to machine.

## 5. Skeleton tests

- `dispose.ts`: the geometry/material/texture `dispose` methods are called on the whole tree (works in Node, no WebGL needed).
- `loop.ts`: `update` isn't called when paused; delta time is capped (`Math.min(dt, 0.1)`), no jump after a background tab.
- `logic/`: all rules.
- E2E: the canvas appears, the first frame is drawn (pixel isn't empty), no console errors/warnings, `renderer.info` draw calls are within budget (exposed on `window.__stats` in test mode).
