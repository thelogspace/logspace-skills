#!/usr/bin/env bash
# Type check + ESLint; warnings count as errors.
set -euo pipefail
cd "$(dirname "$0")/.."
pnpm exec tsc --noEmit
pnpm exec eslint . --max-warnings=0
