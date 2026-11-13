# Three.js Common Mistakes

| Mistake | Right way |
|---|---|
| `scene.remove(mesh)` and done (memory leak) | `disposeObject(mesh)`: geometry, material, textures |
| `new Vector3()` every frame | Reuse temporary objects at module level |
| New material for each mesh | Shared material; `InstancedMesh` |
| `setPixelRatio(devicePixelRatio)` (3x) | `Math.min(dpr, 2)` |
| Movement independent of frame rate (`x += 0.1`) | Multiply by `dt`; cap `dt` |
| Raycast against the whole scene on every `pointermove` | Target list + throttle |
| Huge PNG/JPG textures, uncompressed GLB | KTX2 + Meshopt/Draco (`scripts/optimize-assets.sh`) |
| Wrong color space (washed out / too dark colors) | `SRGBColorSpace` for color maps only |
| Many dynamic lights + shadows on every light | Environment map + one shadowed light |
| Static scene rendered at 60 FPS (battery) | Render on demand |
| Resize with `window.onresize` only (container doesn't adapt) | `ResizeObserver` on the canvas container |
| Debug tools in the production bundle | Only behind `import.meta.env.DEV` |
| `import * as THREE` + all addons (big bundle) | Named imports, addons as needed |
| Text drawn in 3D with hardcoded strings | DOM overlay + i18next |
| Game/app rules mixed into Three.js objects | Pure TS in `logic/`, the scene only displays |
