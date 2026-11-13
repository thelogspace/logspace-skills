#!/usr/bin/env bash
# Flutter unit + widget tests with coverage → coverage/percent.txt
set -euo pipefail
cd "$(dirname "$0")/.."
flutter test --coverage
mkdir -p coverage
# Exclude generated files from the coverage calculation.
awk '
  /^SF:/ { skip = ($0 ~ /\.g\.dart$|app_localizations|firebase_options/) }
  /^LF:/ && !skip { split($0,a,":"); lf += a[2] }
  /^LH:/ && !skip { split($0,a,":"); lh += a[2] }
  END { printf "%.1f\n", (lf ? lh*100/lf : 100) }
' coverage/lcov.info > coverage/percent.txt
