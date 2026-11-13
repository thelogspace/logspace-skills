# Flutter Common Mistakes

| Mistake | Right way |
|---|---|
| Using `BuildContext` after `await` | Check `if (!context.mounted) return;` |
| Calling `setState` / `ref` after dispose | `mounted` check; `ref.onDispose` to clean up |
| Not disposing a `TextEditingController`, `AnimationController`, `StreamSubscription` | Release in `dispose()` (or use hooks/Notifier ownership) |
| Starting a `Future` inside `build` (`FutureBuilder(future: fetch())`) | Create the future once, in a provider/state |
| `MediaQuery.of(context)` everywhere (rebuilds on every change) | `MediaQuery.sizeOf(context)` and the other narrow accessors |
| Huge `build` methods / widgets made of helper methods | Small `StatelessWidget` classes |
| Unbounded height `ListView` inside a `Column` | `Expanded` / `shrinkWrap` only for short lists |
| `left/right` padding (breaks RTL) | `EdgeInsetsDirectional.only(start: ...)` |
| Hardcoded text `Text('Play')` | `Text(context.l10n.homePlayButton)` |
| `print` | `log` (dart:developer) / Crashlytics |
| `flutter.targetSdkVersion` as the target SDK | An explicit number (logspace:store-compliance) |
| Firebase/ads init before `runApp` with a long `await` (white screen) | Minimal init, splash; non-critical SDKs after the first frame |
| Ads SDK init before consent | UMP → ATT → init (logspace:monetization) |
| Secret / API key in `config/*.json` or Dart code | Server side; the app binary can be decompiled |
| Mocking your own classes in tests | Mock only at external boundaries; override with a fake provider |
| `pumpAndSettle` with an infinite animation (timeout) | `pump(duration)` |
| Making a Notifier depend on `BuildContext` | Pass the needed value as a parameter |
