#!/usr/bin/env bash
# Unity-specific one-time setup (called by scripts/setup.sh).
set -euo pipefail
cd "$(dirname "$0")/.."
source scripts/unity-path.sh
merge="$(dirname "$UNITY")/../Tools/UnityYAMLMerge"
[[ -x "$merge" ]] || merge="$(dirname "$UNITY")/../Resources/Tools/UnityYAMLMerge"
git config merge.unityyamlmerge.name "Unity SmartMerge"
git config merge.unityyamlmerge.driver "'$merge' merge -p %O %B %A %A"
git config merge.unityyamlmerge.recursive binary
dotnet tool restore
echo "✓ unity setup (merge driver, csharpier)"
