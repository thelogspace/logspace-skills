# Unity Best Practices (LogSpace, mobile)

## Code architecture (KISS)
- **Game rules are pure C# in `Game.Logic`** (no `UnityEngine` reference): score, economy, level progression, rules. MonoBehaviours only connect input/display → fast EditMode tests.
- Config data (level settings, prices, speeds) lives in **ScriptableObjects**; not hardcoded, not scattered across scenes.
- Dependencies are given via `[SerializeField]` references or constructor/`Init` parameters. Singletons only for really global services (audio, ads, analytics); and even those behind an interface that can be swapped in tests.
- Events: C# `event`/`Action` or a ScriptableObject event channel; `SendMessage` and string-based lookup aren't used.
- Asynchrony: `Awaitable` (Unity 6) / `async` with a `destroyCancellationToken`; coroutines only for simple timing.
- asmdefs: fast compile + forced dependency direction (Logic ← Runtime ← Editor).

## CPU and GC
- **Zero allocations in `Update`**: no `new`, LINQ, string concatenation, boxing or lambda capture. Check with the Profiler's "GC Alloc" column.
- Cache `GetComponent`, `Find*`, `Camera.main` results in `Awake`/`Start`; `TryGetComponent` where needed.
- Avoid an `Update` on every object: a central manager iterates over a list; empty `Update`/`FixedUpdate` methods are deleted.
- **Object pooling** (`UnityEngine.Pool.ObjectPool<T>`): bullets, enemies, effects, UI list items. `Instantiate`/`Destroy` don't happen during gameplay.
- Physics: `Physics.RaycastNonAlloc` / `OverlapSphereNonAlloc`; layer masks; the layer collision matrix is pruned; Fixed Timestep is suitable for the game (0.02 by default; raise it if possible).
- `CompareTag("X")`, not `tag == "X"`.
- Strings: `StringBuilder` / TMP `SetText("{0}", value)` (no allocation).

## Rendering (URP mobile)
- Use the URP mobile/performant quality profile; HDR, MSAA, post-processing and shadows only if needed.
- **SRP Batcher on**; materials with the same shader variant; GPU instancing for repeated meshes.
- Textures: **ASTC** compression, max size suitable for the target (mostly 1024–2048), mipmaps on for 3D, off for UI.
- **Sprite Atlas** for 2D/UI sprites.
- Overdraw: transparent surfaces and fullscreen effects are limited; check with Scene view → Overdraw.
- LOD Groups, occlusion culling (for closed scenes), camera far plane kept short.
- Lighting: baked lighting + light probes; few realtime lights.
- `Application.targetFrameRate = 60` (or 30 for the game type); vSync off on mobile.

## UI (uGUI / UI Toolkit)
- Split Canvases: static and frequently changing elements on different Canvases (one change rebuilds the whole Canvas).
- `Raycast Target` off on non-interactive images/text.
- Layout Groups are expensive; use them sparingly in frequently changing lists.
- TextMeshPro; Arabic RTL + font fallbacks for all 13 languages (logspace:i18n).
- Safe area (notch) is applied.

## Memory and content
- **Addressables** instead of `Resources`; load/release content by scene/level (`Addressables.Release`).
- Audio: short effects "Decompress On Load", music "Streaming"; Vorbis/ADPCM; mono where possible.
- Initial download size: Play's base module limit; large content via Play Asset Delivery / Addressables remote.

## Build
- IL2CPP + ARM64, managed stripping Low (raise it with `link.xml` once tests show it's safe), incremental GC.
- Development Build / Script Debugging is off in release.
- Debug logs: `Debug.Log` calls are stripped in release builds (`[Conditional("DEVELOPMENT_BUILD")]` wrapper).

## Measuring
- **Profile on a real, low-end Android device** (Development Build + Autoconnect Profiler); the editor values are misleading.
- Memory Profiler for leaks; Frame Debugger for draw calls.
- Target: stable 60 FPS, no GC spikes during gameplay, steady memory.
