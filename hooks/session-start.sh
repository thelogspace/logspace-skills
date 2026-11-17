#!/usr/bin/env bash
# SessionStart (also fires after /clear and compaction): reminds Claude of the LogSpace rules
# and reports the project's state. Stdout is added to Claude's context.
set -uo pipefail
cd "${CLAUDE_PROJECT_DIR:-.}" 2>/dev/null || exit 0
[[ -f .logspace/project.json ]] || exit 0

p() { jq -r "$1 // empty" .logspace/project.json; }
name=$(p .name); type=$(p .type); projver=$(p .logspaceSkillsVersion)
plugver=$(jq -r .version "${CLAUDE_PLUGIN_ROOT}/.claude-plugin/plugin.json" 2>/dev/null)

warn=()
# ponytail
grep -qs ponytail "$HOME/.claude/plugins/installed_plugins.json" \
  || warn+=("ponytail isn't installed: install it with the logspace:quality skill (DietrichGebert/ponytail).")
# superpowers
grep -qs superpowers "$HOME/.claude/plugins/installed_plugins.json" \
  || warn+=("superpowers isn't installed: install it with the logspace:quality skill (obra/superpowers).")
# git hooks
if [[ -d .git && -d .githooks && "$(git config core.hooksPath)" != ".githooks" ]]; then
  git config core.hooksPath .githooks && warn+=("git hooks weren't active; core.hooksPath=.githooks was set.")
fi
# skill set version
[[ -n "$plugver" && "$projver" != "$plugver" ]] \
  && warn+=("Project was created with logspace $projver; the current version is $plugver. Run /logspace:audit to sync with the current standards.")
# store compliance freshness (mobile)
if jq -e '.platforms | index("android") or index("ios")' .logspace/project.json >/dev/null 2>&1; then
  checked=$(jq -r '.checkedAt // empty' .logspace/compliance.json 2>/dev/null)
  if [[ -z "$checked" ]]; then
    warn+=("Store compliance has never been checked: run /logspace:store-compliance.")
  else
    then_s=$(date -j -f %Y-%m-%d "$checked" +%s 2>/dev/null || date -d "$checked" +%s 2>/dev/null || echo 0)
    (( ( $(date +%s) - then_s ) > 30*86400 )) \
      && warn+=("Store compliance was last checked $checked (over 30 days ago): run /logspace:store-compliance.")
  fi
fi

cat <<EOF
LogSpace project: ${name} (${type}). The logspace plugin is supervising this project.
Mandatory rules: work with ponytail on every task (smallest change that fully solves it); follow the superpowers process scaled to
the task (bug: root cause + failing test first; feature: brainstorm, plan, test-first; never claim done without check.sh passing);
LogSpace overrides superpowers where they differ (CLAUDE.md "Work discipline"); KISS first, SOLID only for a real need;
zero lint errors; a test for every behavior / business rule / error case; no hardcoded user-visible text (13 languages, logspace:i18n);
follow the best-practices.md and pitfalls.md references of the stack skill; conventional commits; work on a feature/* branch, not on main/develop.
Details: CLAUDE.md. Format+lint runs after every edit; scripts/check.sh runs when you finish.
EOF
if (( ${#warn[@]} > 0 )); then
  echo "Warnings:"
  for w in "${warn[@]}"; do echo "- $w"; done
fi
exit 0
