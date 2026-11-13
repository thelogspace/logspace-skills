---
name: init
description: Starts a new LogSpace project from scratch. Asks for the app name, type (Unity game, Phaser web game, Flutter app, Next.js website, Three.js 3D), platforms and location. Then sets up the skeleton, versioning, quality gates, 13 languages, the About screen, Firebase, monetization and store compliance, in that order. Use for "yeni proje", "uygulama başlat", "proje oluştur", "new app", "/logspace:init".
---

# LogSpace Project Starter

This skill is an orchestrator. It does little work itself; it asks questions, derives identifiers, and calls the other skills **in order**. Each step ends with its own commit, so the history shows every layer separately.

Shared values (website, e-mail, social links, languages, package prefix) live in only one place: `../../shared/brand.json` (relative to this skill's directory). **Never hardcode them in a skill or template.**

## 0. Preflight

Check the tools below. If one is missing, give the user the install command, and don't continue the steps that need it.

| Tool | Check | Needed by |
|---|---|---|
| git | `git --version` | all |
| GitHub CLI | `gh auth status` and `gh api orgs/thelogspace --jq .login` | all (repo creation) |
| ponytail | the check in the `logspace:quality` skill | all |
| git-lfs | `git lfs version` | Unity |
| Unity Hub / Unity 6 LTS | `ls /Applications/Unity/Hub/Editor` | Unity |
| Flutter | `flutter --version` | Flutter, Phaser (shell) |
| Node + pnpm | `node -v`, `pnpm -v` | Phaser, Next.js, Three.js |

## 1. Questions

Ask with `AskUserQuestion` where possible; ask the free-text answers (name, display name) as plain questions.

1. **App name**: lowercase kebab-case. Validate it with `^[a-z][a-z0-9]*(-[a-z0-9]+)*$`; if it doesn't match, ask again with a suggestion (`Color Strix` → `color-strix`).
2. **Display name**: the name shown to users (e.g. `Color Strix`). Suggest a Title Case form of the app name.
3. **Type**:
   - `unity-game`: standalone Unity game → `logspace:unity`
   - `web-game`: Phaser 4 game + Flutter shell → `logspace:web-game`
   - `mobile-app`: Flutter app → `logspace:flutter`
   - `website`: Next.js site → `logspace:nextjs`
   - `web-3d`: Three.js app → `logspace:threejs` (if mobile is chosen, it goes into the `logspace:web-game` monorepo + Flutter shell)
4. **Platforms**: iOS, Android, Web (multiple choice; ask only what fits the type).
5. **Location**: the folder is created under the current directory by default; another parent directory can be chosen. If `<location>/<name>` exists and isn't empty, **stop**.
6. **Monetization**: ads (AdMob / Unity Ads) and/or in-app purchases? (mobile only)
6b. **Unity only**: should Claude be able to drive the Unity Editor (unity-mcp, `logspace:third-party` → optionalMcp)?
7. Firebase (Crashlytics + Analytics) is **added by default**. Ask only "skip it?".

## 2. Derive identifiers

| Value | Rule | `color-strix` |
|---|---|---|
| Repo | `thelogspace/<name>`, private | `thelogspace/color-strix` |
| Folder | `<location>/<name>` | `./color-strix` |
| Package ID (Android + iOS) | `<packagePrefix>.<name without hyphens>` | `xyz.logspace.colorstrix` |

Package ID rules (Android/Java best practice): lowercase letters and digits only, no hyphens. If the segment starts with a digit, prefix it with `app` (`2048-run` → `xyz.logspace.app2048run`). If the segment is a Java keyword (`new`, `class`, `void`, ...), add the `app` suffix.

Check that the repo name is free: `gh repo view thelogspace/<name>` must **fail**. If it exists, stop and ask the user.

Show the user a short summary table (name, display name, type, platforms, folder, repo, package ID, Firebase, monetization), get **one** approval, and don't stop again until the end.

## 3. Bootstrap

```bash
mkdir -p "<location>/<name>" && cd "<location>/<name>"
git init -b main
```

Write `.logspace/project.json`. All later skills read the project's settings from here:

```json
{
  "name": "color-strix",
  "displayName": "Color Strix",
  "type": "mobile-app",
  "platforms": ["ios", "android"],
  "packageId": "xyz.logspace.colorstrix",
  "repo": "thelogspace/color-strix",
  "firebase": true,
  "monetization": { "ads": true, "iap": false },
  "createdAt": "YYYY-MM-DD",
  "logspaceSkillsVersion": "<version from plugin.json>"
}
```

## 4. Layers (in order, each with its own commit)

| # | Skill | Commit message |
|---|---|---|
| 1 | Stack skill (see type) | `chore: scaffold <type> project` |
| 2 | `logspace:quality` | `chore: add quality gates (lint, tests, hooks)` |
| 2b | `logspace:token-economy` | `chore: add token-economy setup (.ignore, helpers)` |
| 3 | `logspace:project-map` | `docs: add project map and folder contract` |
| 4 | `logspace:third-party` | `chore: add vetted third-party skills` |
| 5 | `logspace:perf` | `test: add performance budgets and leak tests` |
| 6 | `logspace:game-design` (games: unity-game, web-game, game-like web-3d) | `docs(game): add GDD, level data and validation` |
| 7 | `logspace:i18n` | `feat(i18n): add 13 languages` |
| 8 | `logspace:about` | `feat(about): add about screen and legal drafts` |
| 9 | `logspace:firebase` (if chosen) | `feat: add firebase crashlytics and analytics` |
| 10 | `logspace:monetization` (if chosen) | `feat: add ads / in-app purchase infrastructure` |
| 11 | `logspace:store-compliance` (mobile) | `chore: apply current store requirements` |
| 12 | `logspace:versioning` | `chore: add release automation` |

Formatter / linter ignores: add `.claude/` to `.prettierignore`, the ESLint ignores and `analysis_options.yaml` exclude, so the vendored third-party skills are never reformatted or linted.

After each layer, run `scripts/check.sh` (written by the quality skill). **Don't commit until it passes.** The stack skill's own `scripts/{format,lint,test}.sh` come in layer 1, the shared `check.sh`/`guard.sh` in layer 2. Before layer 2, check with only the stack scripts.

From then on, the plugin's hooks (`hooks/hooks.json`) supervise the project in every session: they're active because `.logspace/project.json` exists. See `logspace:quality` → "Continuous supervision".

## 5. Write CLAUDE.md

Fill `../../shared/templates/CLAUDE.md.tmpl` from `project.json` and write it to the project root as `CLAUDE.md`. Commit: `docs: add CLAUDE.md [skip ci]`. This is the last commit before the first push; `[skip ci]` keeps release-please from opening a release PR for the skeleton.

## 6. Publish

The `logspace:versioning` skill's "Repo setup" section does this: creates the remote repo, pushes, tags `v0.1.0`, creates `develop`, makes it the default branch, and protects the branches.

## 7. Report

Tell the user, in short:
- Folder, repo URL, package ID
- Layers set up, and whether `scripts/check.sh` passes
- What's still pending: e.g. `GoogleService-Info.plist` / `google-services.json` (Firebase), real ad unit IDs, legal links before store release
- Next step: `git switch -c feature/<first-feature>` from `develop`
