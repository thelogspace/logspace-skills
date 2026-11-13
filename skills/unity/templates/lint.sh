#!/usr/bin/env bash
# Compile with Roslyn analyzers, warnings = errors. Needs the solution Unity generates
# (Preferences → External Tools → Regenerate project files). CI catches it in any case via the compile.
set -euo pipefail
cd "$(dirname "$0")/.."
sln=$(ls ./*.sln 2>/dev/null | head -n1 || true)
if [[ -z "$sln" ]]; then
  echo "⚠ no .sln: open the project once in Unity and regenerate the project files. Lint skipped locally (CI checks it)."
  exit 0
fi
dotnet build "$sln" -warnaserror -nologo -v quiet -clp:ErrorsOnly
