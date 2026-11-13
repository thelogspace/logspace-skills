---
name: game-design
description: Game design discipline for LogSpace games (Unity, Phaser, Three.js). Sets up a one-page GDD, levels and economy as data (JSON / ScriptableObjects / Tiled maps), automated level validation (schema, solvability/reachability, difficulty curve, economy simulation), a generated level map (docs/game/levels.md + progression graph), the analytics funnel for tuning, and save versioning. Use when designing or adding levels, maps, mechanics, rewards or difficulty, and for "level", "bölüm", "harita", "tilemap", "zorluk", "ekonomi", "GDD", "oyun tasarımı".
---

# LogSpace Game Design

Goal: game content is **data, not code**; every level is **verified automatically**; the level map and the economy are **visible at a glance**.

Related vendored skills (logspace:third-party): `level-design`, `game-feel`, `save-systems`, `game-ui-ux`. Their concepts are engine-neutral; their code examples are in Godot, so adapt them to our stack.

## 1. GDD (one page): `docs/game/GDD.md`

Fill `templates/GDD.md`. Short and kept current; a 30-page document nobody reads isn't the goal. Sections: pitch, target audience and **age** (if children are included → Families policy, logspace:monetization), core loop (Mermaid), controls, progression, economy, monetization placements, analytics funnel, KPIs (D1/D7 retention, session length, level fail rate), art/audio direction, scope (what's NOT in v1).

## 2. Levels and maps are data

| Stack | Level data | Map / layout |
|---|---|---|
| Unity | `LevelDefinition` ScriptableObject per level in `Assets/_Project/ScriptableObjects/Levels/`; a `LevelCatalog` SO lists them in order | Unity Tilemap (2D) or a prefab per level (3D); scenes only compose |
| Phaser | `game/public/levels/level-001.json` (+ JSON schema `game/src/logic/level-schema.ts`) | **Tiled** maps (`.tmj` JSON) in `game/public/maps/`; layers: `ground`, `collision`, `objects` (spawn, goal, pickups) |
| Three.js | `src/levels/*.json` | glTF scenes; object placements in JSON |

Rules:
- Level IDs are sequential and stable (`level-001`); IDs never change after release (saves and analytics depend on them).
- Each level states: difficulty (1–10), the mechanic it introduces (if any), target time, star thresholds / rewards.
- Tuning values (speed, damage, prices) are in one config, not in level files.
- The parser (pure logic) is shared by the game and the tests.

## 3. Automated validation (tests, blocking)

`templates/level-validation.md` contains the test list per stack. Minimum:
1. **Schema**: every level parses; required fields present; references (sprites, prefabs, tiles) exist.
2. **IDs**: unique, contiguous, match the catalog/order.
3. **Map integrity** (Tiled / Tilemap): the required layers exist; exactly one spawn; at least one goal; nothing spawns inside collision tiles.
4. **Reachability / solvability**: a BFS / solver from the spawn reaches the goal (and every required key/pickup) with the player's real movement rules (jump height, dash distance from the config). Puzzle games: a solver proves at least one solution, within the move limit.
5. **Difficulty curve**: difficulty doesn't drop by more than the allowed "breather" step unless the level is flagged `breather: true`; a new mechanic is introduced at most every N levels.
6. **Economy simulation**: simulate a player earning and spending over the level sequence → the time/levels to unlock each item stays within the GDD targets; no infinite currency loop.

## 4. Level map: `docs/game/levels.md` (generated)

A small script / test (`level-report`) generates it from the data; **never edited by hand**. A golden test compares the generated output with the committed file → if levels change without regenerating the map, the test fails.
Content:
- Table: ID, name, difficulty, new mechanic, target time, rewards.
- Difficulty curve (Mermaid `xychart-beta`): level → difficulty.
- World / unlock graph (Mermaid `flowchart`): worlds, gates, optional levels.

## 5. Tuning with analytics

Funnel events (logspace:firebase): `level_start`, `level_complete`, `level_fail` (with `level_id`, `attempt`, `duration_s`), `item_purchase`, `currency_earn`/`spend`. Review weekly:
- Fail rate > 40% or a sharp drop in "start → complete" → difficulty spike; adjust the data, not the code.
- The level where most players quit → content or difficulty problem.

## 6. Save data

Versioned save from the first release (`version: 1`), migration tests for every schema change, atomic write (temp file + rename), corrupted-save fallback. See the vendored `save-systems` skill.

## 7. Game feel checklist

Input response < 100 ms, hit-stop/shake/tween feedback on important actions, audio for every interaction, haptics (through the shell bridge on web games), readable UI at a glance. Details: vendored `game-feel` and `game-ui-ux`.
