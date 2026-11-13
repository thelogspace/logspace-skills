#!/usr/bin/env bash
# LogSpace standard guard: structure + forbidden patterns. Runs in check.sh (locally and in CI).
# A justified exception: put "logspace-allow: <reason>" on the same line.
set -euo pipefail
cd "$(dirname "$0")/.."
fail=0
err() { echo "✗ guard: $*"; fail=1; }

# 1. Required files
required=(.logspace/project.json CLAUDE.md .ignore scripts/format.sh scripts/lint.sh scripts/test.sh scripts/check.sh
  .githooks/pre-commit .githooks/commit-msg .githooks/pre-push .claude/settings.json
  .github/workflows/ci.yml .github/workflows/release-please.yml .release-please-manifest.json
  docs/legal/privacy-policy.en.md docs/legal/terms.en.md)
if jq -e '.platforms | index("android") or index("ios")' .logspace/project.json >/dev/null; then
  required+=(.github/workflows/store-compliance.yml scripts/check-android-target.sh)
fi
for f in "${required[@]}"; do [[ -e "$f" ]] || err "missing file: $f"; done

# 2. Source files under scan (generated / third-party excluded)
list=$(mktemp); trap 'rm -f "$list"' EXIT
git ls-files -- '*.dart' '*.ts' '*.tsx' '*.js' '*.jsx' '*.mjs' '*.cs' 2>/dev/null \
  | grep -vE '(^|/)(node_modules|build|dist|\.next|Library|Packages|ThirdParty|Plugins|generated)/|^\.claude/' \
  | grep -vE '\.(g|freezed|gen|config)\.(dart|ts|js|mjs)$|firebase_options.*\.dart$|app_localizations.*\.dart$|\.d\.ts$' \
  > "$list" || true

scan() { # $1 = regex, $2 = message
  [[ -s "$list" ]] || return 0
  local hits
  hits=$(xargs grep -HnE "$1" < "$list" 2>/dev/null | grep -v 'logspace-allow:' || true)
  [[ -n "$hits" ]] && { err "$2"; echo "$hits" | head -n 20; }
  return 0
}

scan 'eslint-disable|@ts-ignore|@ts-nocheck|// ?ignore(_for_file)?:|#pragma warning disable|SuppressMessage' \
  "lint suppression found (fix the rule; if it's truly necessary, explain with logspace-allow)"
scan '\b(fdescribe|fit|xit|xdescribe)\(|\b(describe|it|test)\.(only|skip)\(|skip: true|\[Ignore\b' \
  "focused/skipped test found"
scan 'thelogspace@gmail\.com|youtube\.com/@logspaceapps|instagram\.com/thelogspace' \
  "brand value hardcoded; read it from the brand config"
scan 'AKIA[0-9A-Z]{16}|-----BEGIN [A-Z ]*PRIVATE KEY-----|sk_live_[0-9a-zA-Z]{20,}' \
  "possible secret in code"

# 3. Folder structure and project map (logspace:project-map, .logspace/structure.json)
if [[ -f .logspace/structure.json ]]; then
  roots=$(jq -r '.sourceRoots[]' .logspace/structure.json)
  stray=""
  while IFS= read -r f; do
    [[ "$f" == */* ]] || continue            # root-level config files are allowed
    ok=0; for r in $roots; do [[ "$f" == "$r"* ]] && { ok=1; break; }; done
    (( ok )) || stray="$stray$f"$'\n'
  done < "$list"
  [[ -n "$stray" ]] && { err "source file outside the allowed folders (structure.json sourceRoots):"; printf '%s' "$stray" | head -n 20; }

  if [[ ! -f docs/MAP.md ]]; then
    err "missing file: docs/MAP.md (logspace:project-map)"
  else
    for g in $(jq -r '.mapMustMention[]?' .logspace/structure.json); do
      for m in $g; do                         # glob expansion
        [[ -e "$m" ]] || continue
        n=$(basename "$m"); n=${n%.*}
        grep -q -- "$n" docs/MAP.md || err "docs/MAP.md doesn't mention \"$n\" ($m): update the map"
      done
    done
  fi
fi

# 4. Secret files mustn't be tracked
secrets=$(git ls-files 2>/dev/null | grep -E '(^|/)(\.env(\..+)?|key\.properties|.*\.(jks|keystore|p12|mobileprovision))$' \
  | grep -v '\.env\.example$' || true)
[[ -n "$secrets" ]] && { err "secret file is tracked by git:"; echo "$secrets"; }

(( fail == 0 )) && echo "✓ guard"
exit $fail
