<p align="center">
  <img src="assets/logo.svg" width="160" alt="LogSpace Skills logo">
</p>

<h1 align="center">LogSpace Skills</h1>

<p align="center">
  A Claude Code plugin that starts Unity, Flutter, Phaser, Next.js and Three.js projects with one command, then keeps enforcing their rules for the life of the project.
</p>

<p align="center">
  <a href="LICENSE"><img src="https://img.shields.io/badge/license-MIT-blue.svg" alt="MIT License"></a>
</p>

Every project starts from a verified skeleton. Versioning is set up on day one, quality gates are enforced rather than suggested, and 13 languages are ready from the first commit.

## Installation

In Claude Code, as two separate prompts:

```
/plugin marketplace add thelogspace/logspace-skills
/plugin install logspace@logspace
```

[ponytail](https://github.com/DietrichGebert/ponytail) is required. `logspace:init` checks whether it's installed and installs it if it's missing. Each generated project's `.claude/settings.json` lists both plugins, so every teammate who opens the project is offered the install automatically.

**Prerequisites:** `git`, the [GitHub CLI](https://cli.github.com/) (`gh`, authenticated), `jq`, plus the toolchain for your stack (Flutter, Node + pnpm, or Unity 6 LTS with Git LFS).

## Usage

```
/logspace:init
```

It asks for the app name (lowercase kebab-case), type, platforms and location. Then it sets up, in order: the skeleton, quality gates, project map, vetted third-party skills, performance and leak tests, game design (for games), 13 languages, the About screen, Firebase, monetization, store compliance and versioning. Each layer gets its own commit. Finally it creates a private repo under your GitHub organization.

| Type | Stack |
|---|---|
| `unity-game` | Unity 6 LTS, URP mobile, standalone |
| `web-game` | Phaser 4 + Vite + TypeScript, inside a Flutter WebView shell |
| `mobile-app` | Flutter + Riverpod + go_router |
| `website` | Next.js App Router + Tailwind + next-intl |
| `web-3d` | Three.js + Vite (with the Flutter shell if mobile is chosen) |

## Continuous supervision

| Layer | When | What it does |
|---|---|---|
| Plugin hooks | Every session, command, edit and task end | Reminds Claude of the rules; blocks `--no-verify`, force pushes, and direct commits or pushes to `main`/`develop`; formats and lints after every edit; runs `check.sh` before Claude finishes |
| Git hooks | Commit / push | Format, lint, Conventional Commits, tests |
| `scripts/guard.sh` | Every `check.sh` (locally and in CI) | Required files, folder contract, map drift, lint suppressions, focused tests, hardcoded brand values, secrets |
| CI | Every PR | The `check` job must be green to merge |
| `/logspace:audit` | On demand, before a release, on a version warning | Full standards audit, template drift, fix suggestions |
| Monthly CI | 1st of each month | Opens an issue if `targetSdk` is behind the latest Android API |

The hooks only run in projects that contain `.logspace/project.json`; they never touch other projects.

## Token economy

AI agents pay per token, and Unity projects are notorious for burning them: a single scene file can cost tens of thousands of tokens to read. LogSpace projects are set up to avoid that:

| Waste | Guard |
|---|---|
| Reading Unity scenes, prefabs and assets (serialized YAML) | A read guard blocks unbounded reads; `scripts/unity-inspect.sh` summarizes a scene as a GameObject tree and finds script/prefab usages by GUID |
| Reading build output, caches, lock files, generated code | `permissions.deny` in the project settings plus the read guard |
| Search results flooded by `.meta` files, YAML and third-party assets | A per-stack `.ignore` file (Claude Code's Grep/Glob honor it) |
| Verbose command output | A quiet `scripts/check.sh`: one line per passing step, only the relevant lines on failure, full logs in `.logspace/logs/` |
| Adding one string to 13 locale files | `scripts/i18n-add.sh` updates all of them in one call, without reading them |
| Dumping huge files through the shell | The Bash guard blocks `cat` of YAML, lock files and Unity's `Editor.log` |

Bounded reads (with an explicit line limit) are always allowed, so nothing is ever out of reach when it's genuinely needed.

## Skills

| Skill | Purpose |
|---|---|
| `init` | Orchestrator: asks the questions, derives identifiers, sets up each layer in order |
| `quality` | ponytail, the scripts contract, guard, git hooks |
| `versioning` | Repo, `main` + `develop`, branch protection, release-please, CHANGELOG |
| `store-compliance` | Current Google Play / App Store requirements (read from official sources every time) and a monthly CI check |
| `i18n` | 13 languages (including Arabic RTL) and a key-parity test |
| `about` | About screen, privacy policy and terms-of-use drafts |
| `firebase` | Crashlytics and Analytics with dev/prod separation |
| `monetization` | AdMob, Unity Ads, in-app purchases, UMP consent and ATT |
| `audit` | End-to-end standards audit of a project |
| `project-map` | Folder contract (enforced by guard) and the `docs/MAP.md` architecture map |
| `perf` | Performance budgets, memory-leak tests, profiling guides |
| `game-design` | One-page GDD; levels and maps as data; solvability and economy tests; a generated level map |
| `third-party` | Installs vetted third-party skills and updates them in a controlled way |
| `token-economy` | Search filters, read restrictions, quiet output and token-cheap helper scripts |
| `flutter` | Mobile apps and the web-game shell |
| `web-game` | Phaser 4 + Flutter WebView shell with a JS bridge |
| `nextjs` | Websites (App Router, next-intl, Playwright + axe) |
| `threejs` | 3D web apps |
| `unity` | Unity 6 LTS mobile games (URP, batchmode setup, GameCI) |

Every stack skill ships `references/best-practices.md` and `references/pitfalls.md`. Claude follows them on every coding task, and `audit` checks against them.

## Third-party skills

The catalog lives in [`shared/third-party-skills.json`](shared/third-party-skills.json). Each entry was reviewed for stars, license, version fit and content.

| Project type | Skills | Source |
|---|---|---|
| Flutter (app and shell) | `dart-flutter` plugin (official skills + Dart MCP) | [flutter/agent-plugins](https://github.com/flutter/agent-plugins), official |
| Web game | phaser-core, phaser-arcade-physics, game-feel, level-design, save-systems, game-ui-ux | [gamedev-skills/awesome-gamedev-agent-skills](https://github.com/gamedev-skills/awesome-gamedev-agent-skills) |
| Unity | unity-csharp-scripting, scriptableobjects, input-system, physics, build-size, build-pipeline, performance-optimization, plus game design disciplines | same repo |
| 3D web | threejs-fundamentals, performance, loaders, asset-pipeline, materials, lighting, textures, interaction | [CloudAI-X/threejs-skills](https://github.com/CloudAI-X/threejs-skills) |
| Website | react-best-practices, composition-patterns | [vercel-labs/agent-skills](https://github.com/vercel-labs/agent-skills) |
| Unity (optional) | unity-mcp: lets Claude drive the Unity Editor | [CoplayDev/unity-mcp](https://github.com/CoplayDev/unity-mcp) |

Official sources install as plugins. Community skills are pinned to a commit and copied into the project, so an upstream change never reaches your projects until you've reviewed its diff. None of them are bundled in this repository; they're downloaded into each project under their own licenses.

When guidance conflicts, the order of precedence is: LogSpace rules > stack best practices > third-party skills.

## Customizing for your team

Shared values (website, e-mail, social links, languages, package prefix, GitHub organization) live in a single file, [`shared/brand.json`](shared/brand.json). Fork the repo and change that file to use the plugin for your own organization.

## Rules (summary)

- KISS first; SOLID only when there's a real need. Every task runs with ponytail.
- Zero lint errors. Every behavior, business rule and error case gets a test. The 80% coverage target is advisory and never blocks a merge.
- `feature/*` → `develop` (squash) → `main` (merge commit) → release-please creates the tag and CHANGELOG.
- Package IDs follow `<packagePrefix>.<name-without-hyphens>`.
- A truly necessary exception is marked on the same line with `logspace-allow: <reason>`.

## License

[MIT](LICENSE) © LogSpace
