#!/usr/bin/env bash
# Builds the web game and copies it into the Flutter shell's assets.
set -euo pipefail
cd "$(dirname "$0")/.."
pnpm --dir game install --frozen-lockfile --silent
pnpm --dir game build > /dev/null
rm -rf app/assets/game && mkdir -p app/assets/game
cp -R game/dist/. app/assets/game/
touch app/assets/game/.gitkeep

# Flutter asset folders are not recursive: every folder of the build must be listed in
# app/pubspec.yaml, or its files silently miss the APK/IPA (the game shows a black screen).
missing=""
while IFS= read -r dir; do
  grep -qE "^\s*-\s*${dir#app/}/\s*$" app/pubspec.yaml || missing="$missing ${dir#app/}/"
done < <(find app/assets/game -type d)
if [[ -n "$missing" ]]; then
  echo "✗ not declared under flutter.assets in app/pubspec.yaml:$missing"
  exit 1
fi
echo "✓ game → app/assets/game"
