#!/usr/bin/env bash
# Format for both sides. Usage: format.sh [--check] [files...]
set -euo pipefail
cd "$(dirname "$0")/.."
check=false
[[ "${1:-}" == "--check" ]] && { check=true; shift; }

dart_files=(); web_files=()
for f in "$@"; do
  case "$f" in
    *.dart) dart_files+=("$f") ;;
    *) web_files+=("$(cd "$(dirname "$f")" && pwd)/$(basename "$f")") ;;
  esac
done
if (( $# == 0 )); then dart_files=(app/lib app/test); web_files=(.); fi

if (( ${#dart_files[@]} )); then
  if $check; then dart format --output=none --set-exit-if-changed "${dart_files[@]}"; else dart format "${dart_files[@]}"; fi
fi
if (( ${#web_files[@]} )); then
  if $check; then pnpm --dir game exec prettier --check "${web_files[@]}"; else pnpm --dir game exec prettier --write "${web_files[@]}"; fi
fi
