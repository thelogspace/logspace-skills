---
name: project-map
description: Keeps a LogSpace project's folder layout orderly and its architecture map (docs/MAP.md) up to date. Defines the per-stack folder contract (.logspace/structure.json, enforced by guard), the map content (modules, scene/screen flow, data flow, external services, dependency direction, as Mermaid diagrams) and when to update it. Use when adding a feature/scene/module, when moving folders, and for "klasör yapısı", "harita", "mimari diyagram", "proje haritası", "map".
---

# LogSpace Project Map

Two goals: (1) everything is where it should be, enforced; (2) anyone (and Claude) can understand the project in 2 minutes with `docs/MAP.md`.

## 1. Folder contract: `.logspace/structure.json`

Copy the stack's block from `templates/structure.json` into the project. `scripts/guard.sh` enforces it:
- **`sourceRoots`**: source files (`.dart .ts .tsx .js .cs`) can only be under these folders. Root-level config files (`next.config.ts`, `vite.config.ts`) are allowed. A file outside → guard error.
- **`mapMustMention`**: every match of these globs (feature folders, scenes, systems) must be mentioned by name in `docs/MAP.md`. Add a new feature without updating the map → guard error. That way the map never drifts out of date.

Folder rules (all stacks):
- **Feature first, then type.** `features/inventory/` holds the inventory's screen, logic and tests together; no global `widgets/`, `utils/` junk drawer. Shared code goes to `core/` (or `shared/`) only when **two or more** features use it.
- One file, one main type; the file name is the type name (Dart `snake_case.dart`, C# `PascalCase.cs`, TS `kebab-case.ts`).
- Tests mirror the source path: `lib/features/shop/shop_controller.dart` ↔ `test/features/shop/shop_controller_test.dart`.
- Assets are organized by type and then by feature/level: `assets/images/ui/`, `assets/audio/sfx/`, Unity `Art/Characters/Hero/`. Names are lowercase-kebab (web/Flutter) or PascalCase (Unity); no spaces, no Turkish characters.
- Third-party code is isolated: Unity `Assets/ThirdParty/`, web `vendor/`; never mixed with our code.
- Max depth is kept reasonable (≤ 5 levels under the source root); deeper nesting is a sign of over-structure (ponytail).

## 2. Map: `docs/MAP.md`

Fill `templates/MAP.md` when the project is created. Content:

1. **One-line summary** and the project type.
2. **Folder tree** (2–3 levels, one-line purpose for each important folder). Regenerate it with:
   `git ls-files | awk -F/ 'NF>1{p=$1; for(i=2;i<NF && i<=3;i++){p=p"/"$i}; print p}' | sort -u`
3. **Modules / features** table: name, folder, responsibility, depends on.
4. **Flow diagram** (Mermaid `flowchart`): screens (app/website) or scenes (game): Boot → Menu → Game → GameOver, About/Settings.
5. **Data flow**: where state lives (Riverpod providers / ScriptableObjects / stores), what's persisted (save, preferences), which external services are called (Firebase, AdMob, IAP, the bridge).
6. **Dependency direction** (Mermaid): e.g. `features → core`, `Runtime → Logic` (never the other way). This rule is also checked in reviews.
7. **Entry points**: `main.dart`, `src/main.ts`, Unity boot scene, Next.js `app/[locale]/layout.tsx`.
8. **Where to find**: "Where do I add a new screen / level / translation / analytics event?" → short answers.

Games also link `docs/game/` (logspace:game-design): level map, economy.

## 3. When to update

- New feature / scene / system / external service, moved folder, changed dependency direction → update MAP.md **in the same PR**.
- The guard catches what it can mechanically (feature/scene names); the flow and data sections are checked in `ponytail-review` / `logspace:audit`.
- Keep the map short: if a section grows past a screen, move the detail into the feature's own folder (`README.md`) and link to it.
