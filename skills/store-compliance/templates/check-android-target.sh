#!/usr/bin/env bash
# Compares the project's targetSdk with the latest stable API in the installed Android SDK.
# Output: "ok" or a description of the problem. Exit 1 = behind.
set -euo pipefail
cd "$(dirname "$0")/.."

target=$(
  { grep -hoE 'targetSdk(Version)?\s*=?\s*[0-9]+' android/app/build.gradle* 2>/dev/null \
    || grep -hoE 'AndroidTargetSdkVersion: [0-9]+' ProjectSettings/ProjectSettings.asset 2>/dev/null \
    || true; } | grep -oE '[0-9]+$' | head -n1
)

sdk="${ANDROID_HOME:-${ANDROID_SDK_ROOT:-}}"
sdkmanager=$(ls "$sdk"/cmdline-tools/*/bin/sdkmanager 2>/dev/null | head -n1 || true)
latest=$( { [[ -n "$sdkmanager" ]] && "$sdkmanager" --list 2>/dev/null; } \
  | grep -oE 'platforms;android-[0-9]+ ' | grep -oE '[0-9]+' | sort -n | tail -n1 || true)

if [[ -z "$latest" ]]; then echo "Couldn't read the latest Android API (sdkmanager not found)."; exit 2; fi
if [[ -z "$target" || "$target" == "0" ]]; then
  echo "targetSdk isn't a number (Automatic or flutter.targetSdkVersion). Set it explicitly to $latest."; exit 1
fi
if (( target < latest )); then
  echo "targetSdk $target < latest stable API $latest. Run /logspace:store-compliance."; exit 1
fi
echo "ok (targetSdk $target, latest $latest)"
