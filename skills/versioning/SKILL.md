---
name: versioning
description: Versioning and release flow for LogSpace projects. Creates the private GitHub repo under thelogspace, the main + develop branches and branch protection, the .gitignore, Conventional Commits, SemVer and CHANGELOG (release-please), the main→develop back-merge, and the single source for the mobile version. Use for "repo oluştur", "versiyonlama", "release al", "sürüm çıkar", "changelog", and from the init flow.
---

# LogSpace Versioning

## Model

```
feature/*, fix/*  ──PR──►  develop  ──PR──►  main ──► release-please PR ──► tag vX.Y.Z + GitHub Release
                                       hotfix/* ──PR──► main          main ──auto PR──► develop (back-merge)
```

- **Single version source:** `.release-please-manifest.json`. release-please writes it into the stack's own file (`pubspec.yaml`, `package.json`, Unity `version.txt`).
- **Build number** (Android `versionCode`, iOS `CFBundleVersion`) is never kept in the repo; CI derives it from `github.run_number` (always increasing, never collides).
- Versions start at `0.1.0`. Before the first store release, `1.0.0` is set with a `Release-As: 1.0.0` footer.
- `feat:` → minor, `fix:`/`perf:` → patch, `!` or `BREAKING CHANGE:` → major. (While below 1.0.0, release-please bumps a breaking change to minor.)

## 1. .gitignore

Take the current template from GitHub (it doesn't go stale), then add LogSpace's own lines:

| Type | Template |
|---|---|
| unity-game | `Unity` |
| mobile-app, Flutter shell | `Dart` + `templates/gitignore-flutter-extra` |
| website, web-3d, web-game (web part) | `Node` |

```bash
# Raw file from github/gitignore: no gh, no API rate limit (Unity, Dart, Node)
curl -fsSL https://raw.githubusercontent.com/github/gitignore/main/Unity.gitignore > .gitignore
cat templates/gitignore-common >> .gitignore
```

Unity projects: `.gitattributes` and Git LFS come from the `logspace:unity` skill. Run `git lfs install --local` **before** the first commit.

## 2. Release automation

Copy from `templates/`:

| Template | Target | Note |
|---|---|---|
| `release-please.yml` | `.github/workflows/release-please.yml` | |
| `back-merge.yml` | `.github/workflows/back-merge.yml` | |
| `release-please-config.json` | `release-please-config.json` | set `release-type`: Flutter → `dart`, Node → `node`, Unity → `simple` |
| `release-please-manifest.json` | `.release-please-manifest.json` | |
| `pull_request_template.md` | `.github/pull_request_template.md` | |
| `dependabot.yml` | `.github/dependabot.yml` | keep only the project's ecosystems (`pub`, `npm`, `nuget`, `github-actions`) |

Web-game (Flutter shell + Phaser) monorepo: **one** version for the whole product. Don't split it into two packages: release-please only counts commits inside a package's folder, so `game/` changes would never bump the app version. Use `"release-type": "simple"` for `"."` (writes `version.txt`) with `"extra-files": [{"type": "yaml", "path": "app/pubspec.yaml", "jsonpath": "$.version"}]`, and set `"private": true` in `game/package.json`.

## 3. Repo setup (end of the init flow)

```bash
# 1. remote repo (private) and push
#    The last init commit carries "[skip ci]" (docs: add CLAUDE.md [skip ci]),
#    so release-please doesn't open a 0.2.0 PR for the skeleton commits on the first push.
gh repo create thelogspace/<name> --private --source . --remote origin --push \
  --description "<displayName>, LogSpace <type>"
gh repo edit thelogspace/<name> --add-topic logspace --add-topic <type> \
  --enable-squash-merge --enable-merge-commit --enable-rebase-merge=false \
  --delete-branch-on-merge

# 2. first version: a real GitHub Release (release-please uses this as its starting point)
gh release create v0.1.0 --repo thelogspace/<name> --target main \
  --title "v0.1.0" --notes "Initial skeleton (logspace:init)"

# 3. develop and default branch
git switch -c develop && git push -u origin develop
gh repo edit thelogspace/<name> --default-branch develop
```

Merge types (important for the CHANGELOG):
- `feature/*` → `develop`: **squash**. Each PR becomes a single Conventional Commit; the PR title must match the format.
- `develop` → `main` and the back-merge: **merge commit**. With squash, release-please sees only one commit and the CHANGELOG is empty.

For release-please to open PRs, enable "Allow GitHub Actions to create and approve pull requests" (org or repo Settings → Actions). Check: `gh api repos/thelogspace/<name>/actions/permissions/workflow`; if it's false, set it with `gh api -X PUT ... -F can_approve_pull_request_reviews=true`.

## 4. Branch protection

Apply `templates/branch-protection.json` to `main` and `develop`:

```bash
for b in main develop; do
  gh api -X PUT "repos/thelogspace/<name>/branches/$b/protection" --input templates/branch-protection.json
done
```

The rule: changes only through PRs, the `check` CI job must be green, no force-push or deletion.

**Note:** on the GitHub Free plan, branch protection for **private** repos isn't available (403). In that case, tell the user it requires the GitHub Team plan, and don't stop the flow; the local hooks and CI still work.

## 5. Release (later use)

1. Open a PR `develop` → `main`, titled `chore: release`. Merge it when CI is green, **with a merge commit** (not squash).
2. release-please opens a "chore(main): release x.y.z" PR on `main` (CHANGELOG + version update).
3. Merging it creates the `vX.Y.Z` tag and the GitHub Release.
4. `back-merge.yml` automatically opens the `main` → `develop` PR; merge it.
5. Mobile: run `logspace:store-compliance` **before** the release PR; a failure blocks the release.
