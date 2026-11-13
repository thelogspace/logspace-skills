---
name: token-economy
description: Keeps AI-agent token usage low in LogSpace projects, especially Unity. Sets up the search filter (.ignore), read restrictions, quiet check output, token-cheap helpers (unity-inspect, i18n-add) and the working habits that avoid wasted context. Use from the init flow, when a session gets slow or expensive, and for "token", "maliyet", "context doldu", "çok token yakıyor", "pahalı", "context window".
---

# LogSpace Token Economy

Where the tokens go, in order of cost, and what stops it:

| Waste | Typical cost | Guard |
|---|---|---|
| Reading Unity scenes/prefabs/assets (serialized YAML) | 10k–200k per file | `read-guard` hook blocks unbounded reads > 150 lines → `scripts/unity-inspect.sh` (hierarchy summary, usages by GUID) |
| Reading build output, caches, lock files, generated code | 5k–500k | `permissions.deny` in `.claude/settings.json` + `read-guard` hook |
| Search results flooded by `.meta`, YAML, third-party assets, lock files | 2k–50k per search | `.ignore` (ripgrep reads it: Claude Code Grep/Glob skip these files) |
| Verbose command output (Unity logs, test runners, installs) | 5k–100k per run | quiet `scripts/check.sh` (one line per passing step; errors only); full logs in `.logspace/logs/` |
| Adding a string to 13 locale files by reading each file | ~13 file reads | `scripts/i18n-add.sh <key> '<json>'`: one call, no reads |
| Exploring the codebase from scratch every session | 10k–50k | `docs/MAP.md` first (logspace:project-map) |
| `cat` / `tail` of huge files through the shell | any | `guard-bash` blocks dumping YAML/lock/Editor.log |

The hooks are part of the plugin (they apply to every LogSpace project automatically). This skill installs the per-project files.

## Setup (from the init flow)

1. `templates/ignore/<type>.ignore` → project root as `.ignore`. Files listed there stay **readable**; they're just excluded from search results. For a deliberate search inside them: `rg --no-ignore <pattern> <path>`.
2. `.claude/settings.json` gets the `permissions.deny` list (comes with `logspace:quality/templates/claude-settings.json`).
3. Unity: `logspace:unity/templates/unity-inspect.sh` → `scripts/unity-inspect.sh`.
4. Every stack: `logspace:i18n/templates/i18n-add.sh` → `scripts/i18n-add.sh` (not Unity: Unity strings go through the Localization CSV, see logspace:i18n).
5. `.gitignore`: `.logspace/logs/` (the quiet check's full logs).

## Working habits (also written in CLAUDE.md)

**Reading**
- Start from `docs/MAP.md`, then read only the files the task touches. Don't list or read whole folders "to understand".
- Grep first, then Read with `offset`/`limit` around the hit. Don't re-read a file you just edited or read.
- Unity: never read `.unity` / `.prefab` / `.asset` whole. `scripts/unity-inspect.sh <file>` for structure, `--usages <Script.cs>` for "where is this used", `grep -n` for one field. Change scenes/prefabs through editor scripts or unity-mcp, not by editing YAML.
- Logs: `grep -nE 'error|Exception' <log> | tail -n 40`, never the whole log.

**Running**
- Use `scripts/check.sh` (quiet) instead of raw `flutter test`, `pnpm test`, Unity batchmode. On failure, open only the relevant part of `.logspace/logs/<step>.log`.
- Pipe long commands through `| tail -n 40` or into a file; install commands with quiet flags (`pnpm install --silent`, `flutter pub get > /dev/null`).

**Delegating and sessions**
- Don't spawn subagents for a lookup you can do with one Grep. When exploring broadly, use the Explore agent so the file dumps stay out of the main context.
- One task per session; `/clear` between unrelated tasks; `/compact` when a long task changes phase.
- Use a cheaper model (`/model`) for mechanical work (renames, translations, boilerplate); keep the strongest model for architecture and hard bugs.
- MCP servers (unity-mcp, dart MCP) add tool definitions to the context: enable them for the tasks that need them, keep them off otherwise.

## Measuring

`/cost` (or `/context`) in Claude Code shows where a session's tokens went. If one task keeps burning tokens, look for the pattern in the table above and add a guard or a helper script, rather than accepting the cost.
