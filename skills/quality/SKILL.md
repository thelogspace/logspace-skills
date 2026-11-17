---
name: quality
description: Sets up and enforces the quality gates of a LogSpace project. Checks that ponytail and superpowers are installed and installs them if missing, writes the lint/format/test scripts contract, the guard script, the git hooks (pre-commit, commit-msg, pre-push) and the project's Claude settings; the plugin's own hooks supervise continuously. Use for "kalite", "lint", "test altyapısı", "hook", "ponytail kurulu mu", "superpowers", and from the init flow.
---

# LogSpace Quality Gates

Goal: rules are **enforced**, not hoped for. KISS first, SOLID only for a real need, zero lint errors, a test for every behavior / business rule / error case. The coverage target (`brand.json` → `quality.coverageTarget`) is **advisory**: it's reported, it never fails.

## Continuous supervision (where it comes from)

| Layer | Source | Runs |
|---|---|---|
| Claude hooks | **plugin** `hooks/hooks.json`. Not copied into the project; the plugin update reaches every project | SessionStart: rules + state warnings · PreToolUse(Bash): blocks `--no-verify`, force push, direct commit/push to main/develop · PostToolUse: format+lint · Stop: `check.sh` |
| git hooks | project `.githooks/` | pre-commit: format+lint · commit-msg: Conventional Commits · pre-push: `check.sh` |
| guard | project `scripts/guard.sh` | inside every `check.sh`, so locally and in CI on every PR |
| CI | stack skill's `ci.yml` | `scripts/check.sh` in the `check` job on every PR |
| Audit | `logspace:audit` | on demand / before a release / when the version differs |

The plugin hooks are active only in projects where `.logspace/project.json` exists; they don't touch other projects.

## 1. ponytail

```bash
grep -qs ponytail ~/.claude/plugins/installed_plugins.json || claude plugin list 2>/dev/null | grep -qi ponytail
```

If it isn't installed (only from the official source):

```bash
claude plugin marketplace add DietrichGebert/ponytail
claude plugin install ponytail@ponytail
```

If the CLI commands aren't available, ask the user to type `/plugin marketplace add DietrichGebert/ponytail` and then `/plugin install ponytail@ponytail` in the prompt.

## 1a. superpowers (work discipline)

[obra/superpowers](https://github.com/obra/superpowers) (MIT) supplies the *process*: brainstorm → plan → test-first → verify before claiming done. ponytail supplies the *size*: the smallest change. They're used together; how they fit LogSpace's rules is written in the project's `CLAUDE.md` ("Work discipline").

```bash
grep -qs superpowers ~/.claude/plugins/installed_plugins.json || claude plugin list 2>/dev/null | grep -qi superpowers
```

If it isn't installed (from Anthropic's official marketplace, which Claude Code already knows):

```bash
claude plugin install superpowers@claude-plugins-official
```

If the CLI command isn't available, ask the user to type `/plugin install superpowers@claude-plugins-official` in the prompt. After installing, the session must be restarted for its hooks to load.

## 2. Scripts contract

Every stack skill writes these three scripts (stack-specific commands):

| Script | Duty | Exit code |
|---|---|---|
| `scripts/format.sh [files...]` | Formats the given files (all files if none given). With `--check`, only checks. | non-zero if `--check` finds an unformatted file |
| `scripts/lint.sh` | Static analysis; **warnings count as errors**. Must be fast (it runs after every edit). | non-zero on any finding |
| `scripts/test.sh` | All tests with coverage; writes the line coverage percent (number only) to `coverage/percent.txt`. | non-zero if a test fails |

This skill copies the generic files on top of them:

| Template | Target |
|---|---|
| `templates/check.sh` | `scripts/check.sh` |
| `templates/guard.sh` | `scripts/guard.sh` |
| `templates/setup.sh` | `scripts/setup.sh` |
| `templates/githooks/*` | `.githooks/` |
| `templates/claude-settings.json` | `.claude/settings.json` (merge if it exists) |

`.claude/settings.json` lists ponytail, superpowers and logspace (and sets `SUPERPOWERS_DISABLE_TELEMETRY=1`, so the brainstorming companion doesn't load a remote logo); whoever opens the project is offered the install automatically, and the supervision hooks come with it.

```bash
chmod +x scripts/*.sh .githooks/*
git config core.hooksPath .githooks
```

Replace `target=80` in `check.sh` with `quality.coverageTarget` from `brand.json`.

## 3. Exceptions

If a lint rule or a guard rule truly has to be skipped, put `logspace-allow: <reason>` on the same line. These exceptions are listed in the PR review and in `logspace:audit`. An exception without a reason fails the guard.

## 4. Test rules (every stack)

- Code and tests are written together; a bug fix starts with a test that reproduces the bug.
- For every public behavior: happy path + edge cases + error cases.
- Logic is kept separate from the UI/engine so it can be tested (pure functions / plain classes).
- Mock only at external boundaries (network, store, SDK); don't mock your own code.
- No flaky tests: control time and randomness (inject clock, seed).
- Test names state the behavior: `returns empty list when inventory has no items`.

## 5. Verify

The skeleton must pass `scripts/check.sh` with **zero errors**. If coverage is below the target, only a warning is printed.
