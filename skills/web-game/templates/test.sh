#!/usr/bin/env bash
# Game (vitest) + shell (flutter test). coverage/percent.txt = the lower of the two.
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p coverage

pnpm --dir game exec vitest run --coverage --coverage.reporter=json-summary --coverage.reporter=text-summary
game_pct=$(jq '.total.lines.pct' game/coverage/coverage-summary.json)

(cd app && flutter test --coverage)
app_pct=$(awk '
  /^SF:/ { skip = ($0 ~ /\.g\.dart$|app_localizations|firebase_options/) }
  /^LF:/ && !skip { split($0,a,":"); lf += a[2] }
  /^LH:/ && !skip { split($0,a,":"); lh += a[2] }
  END { printf "%.1f", (lf ? lh*100/lf : 100) }' app/coverage/lcov.info)

echo "coverage: game ${game_pct}% · app ${app_pct}%"
awk -v a="$game_pct" -v b="$app_pct" 'BEGIN { printf "%.1f\n", (a < b ? a : b) }' > coverage/percent.txt
