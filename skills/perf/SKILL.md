---
name: perf
description: Performance and memory-leak discipline for LogSpace projects. Sets up per-type performance budgets, automated leak tests (Flutter leak_tracker, Unity zero-GC-alloc and scene load/unload tests, Playwright heap-growth tests, Three.js renderer.info checks), Lighthouse CI for websites, and the profiling/leak-hunting procedures per stack. Use for "performans", "yavaş", "takılma", "FPS", "memory leak", "bellek", "RAM", "uygulama boyutu", "açılış süresi", "profiling", and from the init flow.
---

# LogSpace Performance and Memory

## Principles

1. **Measure first, then optimize.** No optimization without a measurement (ponytail: no speculative optimization). Measure in release/profile mode, **on a real, low-end device**.
2. **Budgets are written down.** `.logspace/budgets.json` (from `templates/budgets.json`, the project type's block). The PR description states which budget a change may affect.
3. **Leak tests block, performance budgets advise.** A memory leak is a bug: the test fails, CI is red. FPS/size/LCP budgets are reported as warnings, like coverage (they depend on the machine).
4. **Hot paths have a test.** The functions called every frame (update loop, scroll, render) get a "doesn't allocate" / "doesn't grow" test.

## Setup (from the init flow)

| Stack | Leak test (blocking) | Performance measurement (advisory) |
|---|---|---|
| Flutter | `templates/flutter_test_config.dart` → `test/flutter_test_config.dart` (leak_tracker: undisposed objects fail widget tests); `flutter pub add dev:leak_tracker_flutter_testing` | `integration_test` + `traceAction` frame times; `flutter build appbundle --analyze-size` |
| Unity | `templates/HotPathAllocationTests.cs` (EditMode, `Is.Not.AllocatingGCMemory()`), `templates/SceneLeakTests.cs` (PlayMode, load/unload ×3, assets return to baseline) | `com.unity.test-framework.performance` measurements; Build Report size |
| Phaser / Three.js | `templates/memory.spec.ts` (Playwright + CDP: forced GC, heap growth after N play cycles < budget); Three.js: `renderer.info.memory` returns to baseline after a scene switch | FPS sample in Playwright; bundle size with `vite build` + budget |
| Next.js | `templates/memory.spec.ts` for SPA-like flows (optional) | `templates/lighthouserc.json` (Lighthouse CI, 3 runs, `filesystem` upload: reports stay private) |

Details and leak-hunting procedures: `references/flutter.md`, `references/unity.md`, `references/web.md`.

## The test hooks the game needs

For web games / 3D: in test mode (`import.meta.env.MODE === 'test'` or `?e2e=1`), expose `window.__test = { startLevel(id), finishLevel(), toMenu(), stats() }`. Playwright drives play cycles with them; they aren't included in the production build.

## When there's a perf problem

1. Reproduce and measure (which device, which scene, how many ms / MB).
2. Find the cause with the stack profiler (references). Is it CPU, GPU, GC or I/O?
3. Write the test that catches it (a leak test, a no-alloc test or a budget check).
4. The smallest fix; measure again; report the numbers before/after in the PR.

## Mobile-specific

- Battery and heat: frame rate cap (30 for menus/static screens), stop the loop in the background, don't keep a GPS/sensor open without need.
- Startup time: only what's needed before the first frame; ads/analytics init after the first frame (after consent).
- App size: per-ABI split (AAB does this), compressed assets, unused packages removed; check the size report in every release.
