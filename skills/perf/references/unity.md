# Unity: Performance and Leak Hunting

## Tools
- **Profiler** on a real device: Development Build + Autoconnect Profiler (or attach over USB/Wi-Fi). Modules: CPU (Timeline view), GPU, Rendering (batches, SetPass calls), Memory, Audio.
- **Frame Debugger**: why a draw call wasn't batched.
- **Memory Profiler package** (`com.unity.memoryprofiler`): snapshot before → play a level → back to menu → snapshot after → **Compare**. What exists in "after" but not "before" is the leak; the references panel shows who holds it.
- **Profile Analyzer**: compare two captures (before/after optimization) statistically.
- **Build Report** (Console → Editor.log after a build, or the Build Report Inspector package): what makes the build big.
- `ProfilerRecorder` API: read counters (GC Allocated In Frame, Draw Calls, System Used Memory) in code for an on-device debug HUD. Note: some counters read 0 unless the profiler is recording in some versions; verify on the target Unity version.

## Automated (set up by logspace:perf)
- **No-alloc tests** (EditMode): `Assert.That(() => hotPath(), Is.Not.AllocatingGCMemory())` with `using Is = UnityEngine.TestTools.Constraints.Is;` (NUnit has its own `Is`). Warm up once before asserting.
- **Scene leak tests** (PlayMode): load/unload a level ×3 → `Resources.UnloadUnusedAssets()` + `GC.Collect()` → texture/mesh/GameObject counts ≤ baseline.
- **Performance Testing package** (`com.unity.test-framework.performance`): `Measure.Frames()`, `Measure.Method()` for benchmarks of critical systems; results are compared across runs (advisory).

## Common leak sources
| Source | Fix |
|---|---|
| Event subscription (`+=`) without unsubscription (`-=`); static events | Subscribe in `OnEnable`, unsubscribe in `OnDisable` |
| Static lists/dictionaries holding scene objects | Clear on scene unload; avoid statics for scene state |
| `Addressables.LoadAssetAsync` / `InstantiateAsync` without `Release` / `ReleaseInstance` | Pair every load with a release (handle ownership) |
| `new Material` / `renderer.material` (creates an instance) never destroyed | `sharedMaterial` or `Destroy` the instance; MaterialPropertyBlock for per-object values |
| `RenderTexture`, `Texture2D` created at runtime | `Release()` / `Destroy()` |
| Coroutines / async tasks running after the object is destroyed | `destroyCancellationToken`; stop coroutines in `OnDisable` |
| `DontDestroyOnLoad` objects duplicated on every scene load | Guard with a single instance check |
| Native containers (`NativeArray`) not disposed | `Dispose()`; leak detection on in the editor |

## Stutter checklist
- GC spikes → Profiler "GC.Alloc" markers → find allocations in `Update` (LINQ, string, boxing, closures, `foreach` over non-List interfaces).
- `Instantiate` hitches → pools; prewarm pools during loading.
- Shader compilation hitches → shader variant collection + prewarm in loading.
- Physics spikes → too many contacts; simplify colliders, layer matrix.
- UI rebuilds → split Canvases (Profiler: `Canvas.SendWillRenderCanvases`).
- Loading on the main thread → `LoadSceneAsync`, Addressables async, `Awaitable`.

## Thermal and battery
- `Application.targetFrameRate` 30 in menus, 60 in gameplay; Adaptive Performance package (Samsung and others) to scale quality under heat.
- Turn off what's off-screen (cameras, particles, animators: `cullingMode`).
