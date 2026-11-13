# Flutter Best Practices (LogSpace)

## Performance
- Use a `const` constructor wherever possible; `const` widgets aren't rebuilt.
- Keep `build()` pure and cheap: no network, I/O, heavy computation, or object creation inside it.
- Narrow the rebuild area: `ref.watch(provider.select((s) => s.field))`; split big widgets into small `StatelessWidget`s (not helper methods, because they don't narrow rebuilds).
- Long lists: `ListView.builder` / `SliverList`; give `itemExtent` / `prototypeItem` when you can.
- Images: `cacheWidth`/`cacheHeight` at the display size; correct asset resolutions (1x/2x/3x); prefer WebP.
- Heavy computation (JSON > 100 KB, image processing): `Isolate.run` / `compute`.
- Animations: `AnimatedBuilder` + a `child` parameter (the static part isn't rebuilt); expensive `Opacity`/`ClipPath`/`saveLayer` aren't used in animations → `FadeTransition`, `AnimatedOpacity`.
- `RepaintBoundary` for areas that repaint constantly (animation, game view).
- Measure in profile mode on a real device (`flutter run --profile`, DevTools); not in debug.

## State management (Riverpod)
- Simple state: `Provider` / `NotifierProvider`; async: `FutureProvider` / `AsyncNotifierProvider`.
- Providers are global definitions but state lives in the `ProviderScope`; in tests, swap dependencies with `ProviderScope(overrides: [...])`.
- Services (analytics, ads, purchases, storage) are given as providers → they're overridden with fakes in tests.
- `ref.watch` in `build`, `ref.read` in callbacks; `ref.listen` for side effects (snackbar, navigation).
- `autoDispose` by default for screen-specific state.

## Architecture (KISS)
- Feature-first folders. A repository/interface is opened only when there is more than one data source or a test boundary is needed.
- Business logic lives in Notifiers/plain Dart classes, not in widgets → can be tested without widget tests.
- Errors are explicit: `AsyncValue.guard`, user-friendly + localized messages.
- Navigation: `go_router`, routes in one place; deep-link-ready paths.

## Errors and observability
- `FlutterError.onError` and `PlatformDispatcher.instance.onError` → Crashlytics (`logspace:firebase`).
- `runZonedGuarded` isn't needed (PlatformDispatcher is enough); don't wrap twice.
- Never swallow an error silently with `print`; `debugPrint` only in development, use `log` from `dart:developer`.

## UI
- Material 3 theme; colors/typography come from `ThemeData`, not inline.
- `EdgeInsetsDirectional`, `AlignmentDirectional` (RTL).
- Text scaling: test the layout at `textScaler` 1.0–2.0; long texts (de, ru) aren't clipped.
- Accessibility: `Semantics` labels; touch targets at least 48x48.

## Platform
- Lifecycle: `AppLifecycleListener` for pause/resume (sound, timers, game).
- Permissions are requested at the moment of use, with an explanation; never in bulk at startup.
- Keep `pubspec.lock` in the repo (it's an app).
