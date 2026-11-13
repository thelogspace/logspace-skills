# Unity Common Mistakes

| Mistake | Right way |
|---|---|
| `GetComponent` / `Find` / `Camera.main` in `Update` | Cache in `Awake` |
| `Instantiate`/`Destroy` during gameplay | `ObjectPool<T>` |
| LINQ, `string +`, `new List` in `Update` (GC spikes) | Reused buffers, `StringBuilder`, NonAlloc APIs |
| Game rules inside MonoBehaviours (untestable) | Pure C# in `Game.Logic` |
| Everything as a Singleton | Serialized references; singletons only for global services, behind an interface |
| `Resources.Load` for everything | Addressables + Release |
| Not committing `.meta` files / committing `Library/` | Meta files in git, `Library/` in .gitignore (Unity template) |
| Binary serialization or LFS missing (huge repo, broken merges) | Force Text + `.gitattributes` LFS + UnityYAMLMerge |
| Two people editing the same scene | Split content into prefabs; the scene only composes |
| Profiling only in the editor | Development Build on a real device |
| One giant Canvas, Raycast Target everywhere | Split Canvases, Raycast Target only on interactive elements |
| Uncompressed textures / max size 4096 everywhere | ASTC, need-based max size, Sprite Atlas |
| `async void` / an async task that continues after the object is destroyed | `Awaitable` + `destroyCancellationToken` |
| Movement in `Update` without `Time.deltaTime`; physics in `Update` | `deltaTime`; Rigidbody movement in `FixedUpdate` |
| `public` fields for Inspector access | `[SerializeField] private` |
| Hardcoded text in `Text`/`TMP_Text` | Localization String Table |
| `AndroidTargetSdkVersion` "Automatic" | An explicit number (logspace:store-compliance) |
| Mono backend / ARMv7 only | IL2CPP + ARM64 |
| Leaving `Debug.Log` calls in release | Conditional log wrapper |
| Ads SDK init before consent | UMP → ATT → init (logspace:monetization) |
