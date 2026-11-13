# Web (Phaser, Three.js, Next.js): Performance and Leak Hunting

## Tools
- Chrome DevTools **Performance** panel (CPU 4x/6x throttling + "Low-tier mobile" to simulate a weak phone), **Memory** (heap snapshots, allocation timeline), **Rendering** (FPS meter, paint flashing, layer borders).
- **Remote debugging on the real device**: Android `chrome://inspect` (the Flutter WebView is debuggable in debug builds: `InAppWebViewSettings(isInspectable: kDebugMode)`), iOS Safari → Develop menu.
- Three.js: `renderer.info.render` (calls, triangles) and `renderer.info.memory` (geometries, textures); `stats.js` / `stats-gl` in dev only.
- Phaser: `game.loop.actualFps`; the number of active display objects / bodies.
- Next.js: Lighthouse CI (set up by logspace:perf), `@next/bundle-analyzer`, the Web Vitals report from `useReportWebVitals`.

## Leak hunting
1. **Automated** (logspace:perf `memory.spec.ts`): forced GC via CDP, N play cycles, heap growth < budget; Three.js also compares `renderer.info.memory` before/after.
2. **Manual, three snapshots**: snapshot 1 → do the action (play a level, open a modal) → back to the start → snapshot 2 → repeat → snapshot 3. In snapshot 3, "Objects allocated between 1 and 2" that still exist = leak. "Detached" DOM nodes are a classic sign.
3. **memlab** (Meta, open source) for deep analysis: a scenario file (`url`, `action`, `back`) → `memlab run --scenario` → leak traces grouped by retainer path. Use it when the automated test fails and the cause isn't obvious.

## Common leak sources
| Source | Fix |
|---|---|
| `addEventListener` (window, document, resize, keydown) not removed | `AbortController` signal: `addEventListener(type, fn, { signal })` → `abort()` on teardown |
| `setInterval` / `requestAnimationFrame` loops not stopped | Clear them on scene shutdown / component unmount |
| Phaser: `this.events.on` / `this.input.on` / `EventEmitter` listeners on global emitters (`game.events`, `registry`) not removed on scene shutdown | `this.events.once(Phaser.Scenes.Events.SHUTDOWN, cleanup)`; prefer scene-local emitters |
| Phaser: tweens/timers on destroyed objects; textures added at runtime (`textures.addCanvas`) never removed | `tweens.killTweensOf`, `textures.remove` |
| Three.js: geometry/material/texture/render target not disposed | `disposeObject()`; check `renderer.info.memory` |
| Three.js: `ImageBitmap` from loaders not closed | `texture.source.data.close?.()` when disposing (where used) |
| Closures in caches / module-level Maps that grow forever | Bounded caches (LRU) or `WeakMap` |
| React/Next: effects without cleanup (subscriptions, timers, observers) | Return a cleanup function from `useEffect` |
| Detached DOM: removed elements still referenced from JS | Drop references on teardown |

## Frame budget checklist (games / 3D)
- Long tasks (> 50 ms) in the Performance panel → split work, move to a worker (`OffscreenCanvas` / Web Worker for heavy computation).
- GC sawtooth in the memory timeline → allocations in the loop (temporary vectors, arrays, closures).
- GPU-bound (low FPS even with an empty update) → pixel ratio, overdraw, shadows, post-processing.
- Asset hitch on first use → preload; for Three.js `renderer.compileAsync(scene, camera)` before the first frame of a new scene.

## Website checklist (Core Web Vitals)
- LCP: hero image `priority`, server-rendered, preconnect to critical origins.
- INP: break up long event handlers; `startTransition` for non-urgent updates.
- CLS: reserve space (width/height, `aspect-ratio`), `next/font`.
- JS: per-route first-load budget; dynamic `import()` for heavy, below-the-fold components.
