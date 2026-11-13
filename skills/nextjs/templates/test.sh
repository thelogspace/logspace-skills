#!/usr/bin/env bash
# Vitest (unit + component) with coverage → coverage/percent.txt
set -euo pipefail
cd "$(dirname "$0")/.."
pnpm exec vitest run --coverage
jq '.total.lines.pct' coverage/coverage-summary.json > coverage/percent.txt
