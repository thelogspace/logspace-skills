#!/usr/bin/env bash
# Run once after cloning.
set -euo pipefail
cd "$(dirname "$0")/.."

git config core.hooksPath .githooks
chmod +x scripts/*.sh .githooks/* 2>/dev/null || true
if [[ -f .gitattributes ]] && grep -q "filter=lfs" .gitattributes; then
  git lfs install --local
  git lfs pull
fi
[[ -x scripts/setup-stack.sh ]] && scripts/setup-stack.sh
echo "✓ setup done. Full check: scripts/check.sh"
