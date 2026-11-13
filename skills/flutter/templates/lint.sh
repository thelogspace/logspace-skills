#!/usr/bin/env bash
# Flutter static analysis: infos and warnings count as errors.
set -euo pipefail
cd "$(dirname "$0")/.."
flutter analyze --fatal-infos --fatal-warnings
