#!/usr/bin/env bash
# CSharpier. Usage: format.sh [--check] [files...] — only our own code (not ThirdParty).
set -euo pipefail
cd "$(dirname "$0")/.."
cmd=format
[[ "${1:-}" == "--check" ]] && { cmd=check; shift; }
(( $# == 0 )) && set -- Assets/_Project Assets/Tests
dotnet csharpier "$cmd" "$@"
