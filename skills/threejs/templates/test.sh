#!/usr/bin/env bash
# Vitest with coverage → coverage/percent.txt
set -euo pipefail
cd "$(dirname "$0")/.."
pnpm exec vitest run --coverage --coverage.reporter=json-summary --coverage.reporter=text-summary
jq '.total.lines.pct' coverage/coverage-summary.json > coverage/percent.txt
