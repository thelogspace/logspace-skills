#!/usr/bin/env bash
# PreToolUse(Bash): blocks commands that bypass the quality gates or the git flow.
# Exit 2 = command blocked, stderr goes to Claude.
set -uo pipefail
cd "${CLAUDE_PROJECT_DIR:-.}" 2>/dev/null || exit 0
[[ -f .logspace/project.json ]] || exit 0

cmd=$(jq -r '.tool_input.command // empty')
[[ -z "$cmd" ]] && exit 0
block() { echo "LogSpace guard: $1" >&2; exit 2; }

# 1. Bypassing hooks
[[ "$cmd" =~ --no-verify ]] && block "--no-verify is forbidden; fix the error the hook found."
[[ "$cmd" =~ core\.hooksPath ]] && [[ ! "$cmd" =~ core\.hooksPath[[:space:]]+\.githooks ]] \
  && block "core.hooksPath can only be .githooks."
[[ "$cmd" =~ (^|[[:space:];&|])git[[:space:]].*-c[[:space:]]+core\.hooksPath ]] && block "Overriding the hooks with git -c is forbidden."

# 2. Disabling lint / tests from the command line
[[ "$cmd" =~ (eslint|flutter[[:space:]]+analyze|dart[[:space:]]+analyze).*(--no-fatal|--max-warnings[[:space:]]*=?[[:space:]]*[1-9]) ]] \
  && block "Loosening the lint thresholds is forbidden."

# 2b. Token economy: dumping huge serialized / lock / generated files through the shell
if [[ "$cmd" =~ (^|[[:space:];&|])(cat|less|more|bat)[[:space:]][^|]*\.(unity|prefab|asset|controller|anim|shadergraph|lock|g\.dart)([[:space:]]|$) ]] \
   || [[ "$cmd" =~ (^|[[:space:];&|])(cat|less|more|bat)[[:space:]][^|]*(pnpm-lock\.yaml|package-lock\.json) ]]; then
  block "Dumping this file wastes tokens. Use scripts/unity-inspect.sh, grep -n for the needed lines, or 'pnpm why' / 'dart pub deps'."
fi
[[ "$cmd" =~ (^|[[:space:];&|])(cat|tail|less)[[:space:]][^|]*Editor\.log ]] && [[ ! "$cmd" =~ tail[[:space:]]+-n[[:space:]]*[0-9]{1,3}([[:space:]]|$) ]] \
  && block "Editor.log is huge. Use: grep -nE 'error CS|Exception|Error' <log> | tail -n 40"

# 3. Git flow: main/develop are only changed through PRs (once the branch exists on the remote)
remote_has() { git ls-remote --exit-code --heads origin "$1" >/dev/null 2>&1; }
branch=$(git branch --show-current 2>/dev/null)

if [[ "$cmd" =~ (^|[[:space:];&|])git[[:space:]]+push ]]; then
  if [[ "$cmd" =~ (--force|[[:space:]]-f([[:space:]]|$)) && ! "$cmd" =~ --force-with-lease ]]; then
    block "force push is forbidden (use --force-with-lease on your own feature branch if you need to)."
  fi
  # Positional args after "push" (without flags): 0-1 = the current branch is pushed implicitly.
  nargs=$(sed -E 's/.*git[[:space:]]+push//; s/[;&|].*//' <<<"$cmd" | tr ' ' '\n' | grep -vE '^(-|$)' | wc -l | tr -d ' ')
  for b in main develop; do
    if [[ "$cmd" =~ (^|[[:space:]:])$b([[:space:]]|$) ]] || { [[ "$branch" == "$b" ]] && (( nargs <= 1 )); }; then
      remote_has "$b" && block "Pushing directly to $b is forbidden. Open a feature/* or fix/* branch and a PR."
    fi
  done
fi

if [[ "$cmd" =~ (^|[[:space:];&|])git[[:space:]]+commit ]] && [[ "$branch" == "main" || "$branch" == "develop" ]]; then
  remote_has "$branch" && block "Committing directly on $branch is forbidden. First: git switch -c feature/<name>"
fi

exit 0
