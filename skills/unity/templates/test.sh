#!/usr/bin/env bash
# EditMode + PlayMode tests in batchmode with Code Coverage → coverage/percent.txt
set -euo pipefail
cd "$(dirname "$0")/.."
source scripts/unity-path.sh
mkdir -p coverage

if [[ ! -x "$UNITY" ]]; then
  echo "✗ Unity editor not found: $UNITY (set UNITY_PATH)"; exit 1
fi
if [[ -f Temp/UnityLockfile ]] && pgrep -fi "Unity.*-projectpath.*$(pwd)" >/dev/null 2>&1; then
  echo "⚠ The project is open in the Unity editor; batchmode can't run."
  echo "  Run the tests from the Test Runner window (CI runs them in any case)."
  exit 0
fi

# Short summary from the NUnit XML (the Unity log itself is huge; it stays in the file).
summary() {
  local xml=$1
  grep -o '<test-run[^>]*' "$xml" 2>/dev/null | grep -oE '(total|passed|failed|skipped)="[0-9]+"' | tr '\n' ' '; echo
  grep -oE '<test-case [^>]*result="Failed"' "$xml" 2>/dev/null | grep -oE 'fullname="[^"]*"' | head -n 20 | sed 's/^/  ✗ /'
}

for mode in EditMode PlayMode; do
  if ! "$UNITY" -batchmode -projectPath . -runTests -testPlatform "$mode" \
    -testResults "coverage/results-$mode.xml" \
    -enableCodeCoverage -coverageResultsPath coverage/unity \
    -coverageOptions "generateAdditionalMetrics;generateHtmlReport;assemblyFilters:+Game.*;dontClear" \
    -logFile "coverage/unity-$mode.log"; then
    echo "✗ $mode tests failed: $(summary "coverage/results-$mode.xml")"
    grep -nE 'error CS[0-9]+' "coverage/unity-$mode.log" | head -n 20   # compile errors, if that's the cause
    exit 1
  fi
  echo "✓ $mode: $(summary "coverage/results-$mode.xml" | head -n1)"
done

grep -o '<Linecoverage>[0-9.]*' coverage/unity/Report/Summary.xml 2>/dev/null \
  | grep -o '[0-9.]*$' > coverage/percent.txt || rm -f coverage/percent.txt
