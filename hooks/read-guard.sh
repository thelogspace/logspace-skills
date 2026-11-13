#!/usr/bin/env bash
# PreToolUse(Read): blocks unbounded reads of files that burn tokens without adding understanding
# (build output, lock files, binaries, Unity serialized YAML, generated code, very large files).
# Passing an explicit `limit` is a deliberate, bounded read and is allowed (except binaries).
set -uo pipefail
root="${CLAUDE_PROJECT_DIR:-.}"
[[ -f "$root/.logspace/project.json" ]] || exit 0

input=$(cat)
f=$(jq -r '.tool_input.file_path // empty' <<<"$input")
limit=$(jq -r '.tool_input.limit // empty' <<<"$input")
[[ -z "$f" || ! -f "$f" ]] && exit 0
rel="${f#"$root"/}"
block() { echo "LogSpace token guard: $1" >&2; exit 2; }

size=$(wc -c < "$f" | tr -d ' ')
tokens=$(( size / 4 ))

# Binaries: never useful as text.
[[ "$f" =~ \.(glb|gltf|fbx|obj|blend|wav|mp3|ogg|m4a|mp4|ttf|otf|ktx2|basis|aab|apk|ipa|dll|so|a|jar|aar|zip|unitypackage)$ ]] \
  && block "$rel is a binary asset. Inspect metadata instead (file size, import settings, gltf-transform inspect)."

[[ -n "$limit" ]] && exit 0   # bounded read: the caller chose a window

# Build output / caches inside the project.
if [[ "$rel" != /* ]] && [[ "$rel" =~ (^|/)(Library|Temp|Logs|obj|UserSettings|node_modules|\.next|dist|build|\.dart_tool|Pods|coverage|playwright-report|test-results|\.lighthouseci)/ ]]; then
  block "$rel is build output or a cache. Read the source instead; for errors use the log summary in .logspace/logs/."
fi

case "$f" in
  *pnpm-lock.yaml|*package-lock.json|*yarn.lock|*pubspec.lock|*packages-lock.json|*Podfile.lock)
    block "$rel is a lock file (~$tokens tokens). Use 'pnpm why <pkg>', 'dart pub deps', or grep for one package." ;;
esac

if [[ "$f" =~ \.(unity|prefab|asset|mat|anim|controller|overrideController|physicMaterial|lighting|shadergraph|vfx|meta)$ ]]; then
  lines=$(wc -l < "$f" | tr -d ' ')
  (( lines > 150 )) && block "$rel is Unity serialized YAML ($lines lines, ~$tokens tokens). Use 'scripts/unity-inspect.sh $rel' for a hierarchy summary, 'scripts/unity-inspect.sh --usages <Script.cs>' to find usages, or grep -n then Read with offset/limit."
fi

if [[ "$f" =~ (\.g\.dart|\.freezed\.dart|app_localizations.*\.dart|firebase_options.*\.dart|\.min\.js|\.map)$ ]]; then
  block "$rel is generated. Read its source (ARB file, model, config) instead."
fi

(( size > 100000 )) && block "$rel is $(( size / 1024 )) KB (~$tokens tokens). Grep for what you need, then Read with offset/limit."
exit 0
