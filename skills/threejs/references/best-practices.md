# Three.js Best Practices (LogSpace)

## Renderer
- `renderer.setPixelRatio(Math.min(devicePixelRatio, 2))`; on low-end mobile, even 1.5. The fill rate is the most common bottleneck.
- `antialias: true` only if needed (expensive on mobile); `powerPreference: 'high-performance'`.
- Color: `renderer.outputColorSpace = SRGBColorSpace`, color textures `texture.colorSpace = SRGBColorSpace`; data textures (normal, roughness) stay linear.
- Tone mapping: `ACESFilmicToneMapping` or `AgXToneMapping`, chosen consistently.
- Loop: `renderer.setAnimationLoop(fn)` (not `requestAnimationFrame`, it's also XR compatible). Render on demand if the scene is static (only on change).
- WebGPU: `WebGPURenderer` (three/webgpu) falls back to WebGL automatically; use it when there's a reason (compute, TSL); otherwise `WebGLRenderer` is the simple and reliable default.

## Draw call and geometry budget
- Mobile target: **< 100 draw calls**, a few hundred thousand triangles. Monitor `renderer.info.render.calls` / `.triangles`.
- Repeated objects: `InstancedMesh` (or `BatchedMesh` for different geometries with the same material).
- Static scene parts: merge geometries (`BufferGeometryUtils.mergeGeometries`).
- Share materials and geometries; don't create a new material per mesh.
- `LOD` for distant objects; frustum culling stays on (`frustumCulled = true`, correct bounding spheres).

## Textures and models
- glTF/GLB only; compression: Meshopt or Draco; textures KTX2 (Basis) → GPU-compressed, low memory.
- Texture sizes are powers of two and sized to need (mobile max 2048, mostly 1024).
- Mipmaps on; `anisotropy` moderate.
- Assets are loaded once and cached; clones (`clone()`) share geometry/material.

## Lighting and shadows
- Lights are expensive: few dynamic lights; prefer an environment map (`RoomEnvironment` / HDR + PMREM) for image-based lighting.
- Shadows: one directional light, a tight shadow camera frustum, `shadow.mapSize` 1024; static scenes `shadowMap.autoUpdate = false`. Baked lighting where possible.
- `MeshStandardMaterial` is enough in most cases; `MeshPhysicalMaterial` only when its features are needed.

## Memory
- **Every object removed from the scene is disposed**: `geometry.dispose()`, `material.dispose()`, each `texture.dispose()`, render targets. Use `core/dispose.ts`.
- Scene change: the old scene is fully disposed; `renderer.info.memory` returns to its starting values (tested).

## Loop and time
- `const dt = Math.min(clock.getDelta(), 0.1)`; movements are multiplied by `dt`.
- No `new Vector3()` / `new Matrix4()` in `update`; module-level temporary objects are reused.
- Stop the loop when the tab is hidden (`visibilitychange`) and when the bridge sends `pause`.

## Interaction and UI
- Raycasting: only against relevant objects (a layer or array), not the whole scene; throttle on pointer move.
- UI (menu, texts, about) is a DOM overlay; texts come from i18next, RTL is handled in CSS.
- Imports: `three/addons/...` modules only as needed (tree-shaking).

## Debug
- `lil-gui`, `stats.js` and helpers are loaded only in dev (`import.meta.env.DEV`); not in the production bundle.
