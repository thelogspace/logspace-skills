#!/usr/bin/env bash
# Copies Phaser's OFFICIAL agent skills (shipped inside the phaser npm package, so they always
# match the installed version) into .claude/skills/phaser-<name>. Run after installing/upgrading Phaser.
# Only the listed skills: every skill's description costs context tokens in every session.
set -euo pipefail
cd "$(dirname "$0")/.."
src=game/node_modules/phaser/skills
[[ -d "$src" ]] || { echo "✗ $src not found: run pnpm --dir game install first"; exit 1; }
skills=(${PHASER_SKILLS:-game-setup-and-config scenes loading-assets input-keyboard-mouse-touch text-and-bitmaptext tweens groups-and-containers scale-and-responsive time-and-timers v4-new-features})
version=$(jq -r .version game/node_modules/phaser/package.json)
mkdir -p .claude/skills
for s in "${skills[@]}"; do
  [[ -f "$src/$s/SKILL.md" ]] || { echo "✗ phaser $version has no skill '$s'"; exit 1; }
  rm -rf ".claude/skills/phaser-$s" && cp -R "$src/$s" ".claude/skills/phaser-$s"
  sed -i.bak "s/^name: .*/name: phaser-$s/" ".claude/skills/phaser-$s/SKILL.md" && rm ".claude/skills/phaser-$s/SKILL.md.bak"
  cp game/node_modules/phaser/LICENSE.md ".claude/skills/phaser-$s/LICENSE.md"
done
echo "${skills[*]}" | tr ' ' '\n' | jq -R . | jq -s --arg v "$version" '{source: "npm:phaser", version: $v, license: "MIT", skills: .}' > .logspace/phaser-skills.lock.json
echo "✓ ${#skills[@]} official Phaser $version skills → .claude/skills/phaser-*"
