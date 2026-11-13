#!/usr/bin/env bash
# Flutter format. Usage: format.sh [--check] [files...]
set -euo pipefail
cd "$(dirname "$0")/.."
check=false
[[ "${1:-}" == "--check" ]] && { check=true; shift; }
(( $# == 0 )) && set -- lib test $( [[ -d integration_test ]] && echo integration_test )
if $check; then
  dart format --output=none --set-exit-if-changed "$@"
else
  dart format "$@"
fi
