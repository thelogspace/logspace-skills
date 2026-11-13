#!/usr/bin/env bash
# Full quality check: format, lint, guard, tests. Coverage is advisory only.
# Quiet by design (AI agents pay per token): one line per passing step; on failure only the
# relevant lines. The full output of every step is in .logspace/logs/<step>.log.
set -uo pipefail
cd "$(dirname "$0")/.."
mkdir -p .logspace/logs

run() {
  local step=$1; shift
  local log=".logspace/logs/$step.log"
  if "$@" > "$log" 2>&1; then
    echo "✓ $step"
    grep -h '^⚠' "$log" || true            # surface warnings, nothing else
    return 0
  fi
  echo "✗ $step (full log: $log)"
  # Error lines with a little context first; fall back to the tail.
  { grep -nE -A2 'error|Error|ERROR|✗|FAIL|Failed|failed|Expected|Exception|Unhandled' "$log" || tail -n 30 "$log"; } | head -n 60
  exit 1
}

run format scripts/format.sh --check
run lint   scripts/lint.sh
run guard  scripts/guard.sh
run test   scripts/test.sh

target=80
if [[ -f coverage/percent.txt ]]; then
  pct=$(cut -d. -f1 < coverage/percent.txt)
  if (( pct < target )); then
    echo "⚠ coverage ${pct}% < ${target}% target (advisory, not blocking)"
  else
    echo "✓ coverage ${pct}%"
  fi
fi
echo "✓ check passed"
