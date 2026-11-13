#!/usr/bin/env bash
# PostToolUse(Edit|Write): format the edited file, then lint. Exit 2 sends the error back to Claude.
set -uo pipefail
cd "${CLAUDE_PROJECT_DIR:-.}" 2>/dev/null || exit 0
[[ -f .logspace/project.json && -x scripts/lint.sh ]] || exit 0

file=$(jq -r '.tool_input.file_path // empty')
[[ -z "$file" || ! -f "$file" ]] && exit 0
# Only source code; skip markdown / json / assets.
[[ "$file" =~ \.(dart|ts|tsx|js|jsx|mjs|cs)$ ]] || exit 0

scripts/format.sh "$file" >/dev/null 2>&1 || true
if ! out=$(scripts/lint.sh 2>&1); then
  echo "Lint errors (zero lint error rule; fix them before continuing, don't disable the rule):" >&2
  echo "$out" | tail -n 40 >&2
  exit 2
fi
exit 0
