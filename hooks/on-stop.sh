#!/usr/bin/env bash
# Stop: run the full check when Claude wants to finish. Blocks at most once (no loop).
set -uo pipefail
cd "${CLAUDE_PROJECT_DIR:-.}" 2>/dev/null || exit 0
[[ -f .logspace/project.json && -x scripts/check.sh ]] || exit 0

[[ "$(jq -r '.stop_hook_active // false')" == "true" ]] && exit 0
# If nothing changed in the session, don't spend time on it.
if git rev-parse HEAD >/dev/null 2>&1 && git diff --quiet HEAD -- \
   && [[ -z "$(git ls-files --others --exclude-standard)" ]]; then
  exit 0
fi

if ! out=$(scripts/check.sh 2>&1); then
  echo "scripts/check.sh failed. Fix it before you finish (tests, lint, guard):" >&2
  echo "$out" | tail -n 60 >&2
  exit 2
fi
exit 0
