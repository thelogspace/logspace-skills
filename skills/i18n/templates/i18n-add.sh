#!/usr/bin/env bash
# Adds or updates ONE key in all locale files at once, without reading them into the conversation.
# Usage: scripts/i18n-add.sh [--dir <locale dir>] <key> '<json>'
#   json: {"en":"Play","tr":"Oyna",...all 13...,"@description":"Main menu play button"}
#   Next.js / i18next keys may be dotted (home.play → nested). ARB keys are flat camelCase.
# Non-source languages are recorded in .logspace/i18n-review.json for human review.
set -euo pipefail
cd "$(dirname "$0")/.."

dir=""
[[ "${1:-}" == "--dir" ]] && { dir=$2; shift 2; }
key="${1:?key required}"; json="${2:?translations json required}"
if [[ -z "$dir" ]]; then
  for d in lib/l10n messages src/i18n game/src/i18n app/lib/l10n; do [[ -d "$d" ]] && { dir=$d; break; }; done
fi
[[ -d "$dir" ]] || { echo "✗ locale dir not found (use --dir)"; exit 1; }
jq -e . >/dev/null <<<"$json" || { echo "✗ translations are not valid JSON"; exit 1; }

desc=$(jq -r '."@description" // empty' <<<"$json")
locale_of() { local b; b=$(basename "$1"); b=${b%.*}; b=${b#app_}; echo "${b//_/-}"; }   # app_pt_BR.arb → pt-BR
# A base-language file (app_pt.arb, app_zh.arb, required by Flutter gen-l10n) takes its
# regional translation (pt-BR, zh-Hans) when the json has no exact entry for it.
value_for() {
  jq -r --arg l "$1" '.[$l] // ([to_entries[] | select(.key | startswith($l + "-")) | .value][0]) // empty' <<<"$json"
}
shopt -s nullglob
files=("$dir"/*.arb "$dir"/*.json)

# All-or-nothing: validate every locale before touching any file.
missing=""
for f in "${files[@]}"; do
  loc=$(locale_of "$f")
  [[ -n "$(value_for "$loc")" ]] || missing="$missing $loc"
done
[[ -n "$missing" ]] && { echo "✗ missing translations for:$missing (no file was changed)"; exit 1; }

updated=0
for f in "${files[@]}"; do
  loc=$(locale_of "$f")
  val=$(value_for "$loc")
  tmp=$(mktemp)
  if [[ "$f" == *.arb ]]; then
    jq --indent 2 --arg k "$key" --arg v "$val" --arg d "$desc" --arg l "$loc" \
      '.[$k] = $v | if ($l == "en" and $d != "") then .["@" + $k] = {description: $d} else . end' "$f" > "$tmp"
  else
    jq --indent 2 --arg k "$key" --arg v "$val" 'setpath($k | split("."); $v)' "$f" > "$tmp"
  fi
  mv "$tmp" "$f"; updated=$((updated + 1))
done

mkdir -p .logspace; review=.logspace/i18n-review.json
[[ -f "$review" ]] || echo '[]' > "$review"
jq --arg k "$key" 'map(select(. != $k)) + [$k]' "$review" > "$review.tmp" && mv "$review.tmp" "$review"
echo "✓ $key → $updated locale files ($dir); queued for translation review"
