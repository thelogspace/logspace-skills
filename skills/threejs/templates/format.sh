#!/usr/bin/env bash
# Prettier. Usage: format.sh [--check] [files...]
set -euo pipefail
cd "$(dirname "$0")/.."
if [[ "${1:-}" == "--check" ]]; then
  shift; pnpm exec prettier --check "${@:-.}"
else
  pnpm exec prettier --write "${@:-.}"
fi
