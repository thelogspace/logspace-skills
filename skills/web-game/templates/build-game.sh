#!/usr/bin/env bash
# Builds the web game and copies it into the Flutter shell's assets.
set -euo pipefail
cd "$(dirname "$0")/.."
pnpm --dir game install --frozen-lockfile
pnpm --dir game build
rm -rf app/assets/game && mkdir -p app/assets/game
cp -R game/dist/. app/assets/game/
echo "✓ game → app/assets/game"
