#!/usr/bin/env bash
# assets-src/*.glb → public/models/*.glb (meshopt + texture compression)
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p public/models
tex=webp
command -v toktx >/dev/null && tex=ktx2 || echo "⚠ toktx (KTX-Software) not found; textures will be WebP."
find assets-src -name '*.glb' -print0 2>/dev/null | while IFS= read -r -d '' src; do
  out="public/models/$(basename "$src")"
  pnpm exec gltf-transform optimize "$src" "$out" --compress meshopt --texture-compress "$tex" --texture-size 2048
  echo "✓ $src → $out"
done
