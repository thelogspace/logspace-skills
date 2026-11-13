#!/usr/bin/env bash
# Lint for both sides; warnings count as errors.
set -euo pipefail
cd "$(dirname "$0")/.."
pnpm --dir game exec tsc --noEmit
pnpm --dir game exec eslint . --max-warnings=0
(cd app && flutter analyze --fatal-infos --fatal-warnings)
