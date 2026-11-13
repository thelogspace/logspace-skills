#!/usr/bin/env bash
# Copies the community skills in the catalog, pinned to their SHA, into the project's .claude/skills/.
# Usage (from the project root): vendor.sh <projectType>   e.g. vendor.sh web-game
# No GitHub API: only codeload.github.com (tarball) is used, so there's no rate limit.
set -euo pipefail
type="${1:?project type required (unity-game|web-game|mobile-app|website|web-3d)}"
catalog="$(cd "$(dirname "$0")/../../.." && pwd)/shared/third-party-skills.json"
dest=".claude/skills"; lock=".logspace/third-party-skills.lock.json"
tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
mkdir -p "$dest" .logspace

entries=$(jq -c --arg t "$type" '.vendored | to_entries[] | select(.value.skills[$t]) | {key, repo: .value.repo, sha: .value.sha, license: .value.license, paths: .value.skills[$t]}' "$catalog")
[[ -z "$entries" ]] && { echo "No vendored skills in the catalog for $type."; exit 0; }

echo '[]' > "$tmp/lock.json"
{ echo "# Third-party skills (vendored)"; echo
  echo "Precedence: LogSpace rules (CLAUDE.md) > stack best-practices > these skills."
  echo "Don't edit them by hand; update them via logspace:third-party."; echo
  echo "| Skill | Source | SHA | License |"; echo "|---|---|---|---|"; } > "$tmp/THIRD_PARTY.md"

while IFS= read -r e; do
  repo=$(jq -r .repo <<<"$e"); sha=$(jq -r .sha <<<"$e"); lic=$(jq -r .license <<<"$e")
  name=${repo#*/}
  echo "▶ $repo @ ${sha:0:7}"
  curl -fsSL "https://codeload.github.com/$repo/tar.gz/$sha" -o "$tmp/$name.tgz"
  mkdir -p "$tmp/$name" && tar -xzf "$tmp/$name.tgz" -C "$tmp/$name" --strip-components=1
  for p in $(jq -r '.paths[]' <<<"$e"); do
    skill=$(basename "$p")
    [[ -f "$tmp/$name/$p/SKILL.md" ]] || { echo "✗ not found: $repo/$p"; exit 1; }
    rm -rf "${dest:?}/$skill" && cp -R "$tmp/$name/$p" "$dest/$skill"
    [[ -f "$tmp/$name/LICENSE" && ! -f "$dest/$skill/LICENSE" ]] && cp "$tmp/$name/LICENSE" "$dest/$skill/LICENSE"
    echo "| \`$skill\` | [$repo](https://github.com/$repo/tree/$sha/$p) | \`${sha:0:7}\` | $lic |" >> "$tmp/THIRD_PARTY.md"
    jq --arg s "$skill" --arg r "$repo" --arg p "$p" --arg h "$sha" '. + [{skill:$s, repo:$r, path:$p, sha:$h}]' \
      "$tmp/lock.json" > "$tmp/lock2.json" && mv "$tmp/lock2.json" "$tmp/lock.json"
    echo "  ✓ $skill"
  done
done <<<"$entries"

cp "$tmp/THIRD_PARTY.md" "$dest/THIRD_PARTY.md"
cp "$tmp/lock.json" "$lock"
echo "✓ $(jq length "$lock") skills → $dest (lock: $lock)"
