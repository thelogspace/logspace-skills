# Flutter: Performance and Leak Hunting

## Tools
- `flutter run --profile` on a real device + DevTools: **Performance** (frame chart: UI thread = build/layout, Raster thread = paint/GPU), **CPU Profiler**, **Memory**, **Network**, **App Size**.
- Frame budget at 60 Hz: 16 ms total; build and raster each ≲ 8 ms. On 120 Hz screens, 8 ms.
- "Track widget rebuilds" (DevTools / Flutter Inspector) shows which widgets rebuild too often.
- Size: `flutter build appbundle --analyze-size` → DevTools App Size.

## Leak hunting (in this order)
1. **leak_tracker in tests** (set up by logspace:perf): a widget test fails if it leaves an undisposed object; the failure names the type and the test. Most leaks are caught here.
2. **DevTools Memory → Diff Snapshots**: take a snapshot, open and close the suspect screen 5 times, take another snapshot, diff → the class whose instance count keeps rising is the leak; "Retaining path" shows who holds it.
3. Fix the reference holding it, then write a test that reproduces it.

## Common leak sources
| Source | Fix |
|---|---|
| `AnimationController`, `TextEditingController`, `ScrollController`, `FocusNode`, `PageController` not disposed | `dispose()` in State |
| `StreamSubscription` / `Timer` not cancelled | `cancel()` in `dispose` / `ref.onDispose` |
| Listener added with `addListener` not removed | `removeListener` in `dispose` |
| A closure capturing `BuildContext` / `State` stored in a global / singleton | Don't store; pass values, not context |
| Provider that should be `autoDispose` kept forever | `autoDispose` for screen-level state |
| Large images decoded at full resolution | `cacheWidth`/`cacheHeight`; `precacheImage` only what's needed; `imageCache` limits |
| `InAppWebView` (game shell) not released | One WebView for the screen's life; dispose its controller |

## Jank checklist
- Expensive work in `build` → move to a provider / `Isolate.run`.
- `saveLayer` (Opacity, ShaderMask, ClipRRect with antiAlias in animations) → DevTools "Highlight oversized images" and "saveLayer" counters.
- First-run shader jank: Impeller (default on iOS and modern Android) removes most of it; if you still see it, measure before doing anything.
- Long lists without builders; huge `Column`s in a `SingleChildScrollView`.

## Startup
- Before `runApp`: only `WidgetsFlutterBinding.ensureInitialized`, environment, Firebase core. Ads, IAP, remote config after the first frame (`WidgetsBinding.instance.addPostFrameCallback`).
- Splash: native splash (`flutter_native_splash` only if needed) → first Flutter frame quickly.
