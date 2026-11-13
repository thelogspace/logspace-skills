# Level validation tests per stack

All of them are ordinary tests in `scripts/test.sh`, so they block CI. The level logic (parser, solver, simulation) is pure code shared by the game and the tests.

## Phaser / Three.js (Vitest)

```ts
// game/tests/levels/levels.test.ts
import { describe, expect, it } from 'vitest';
import { loadAllLevels, loadMap } from '../../src/logic/levels';
import { isReachable } from '../../src/logic/reachability';
import { simulateEconomy } from '../../src/logic/economy';
import config from '../../src/logic/config';

const levels = loadAllLevels(); // reads public/levels/*.json synchronously in tests

describe.each(levels)('$id', (level) => {
  it('matches the schema and references existing assets', () => {
    expect(level.errors).toEqual([]);
  });
  it('has exactly one spawn and at least one goal', () => {
    const map = loadMap(level.map);
    expect(map.objects.filter((o) => o.type === 'spawn')).toHaveLength(1);
    expect(map.objects.some((o) => o.type === 'goal')).toBe(true);
  });
  it('the goal and every required pickup are reachable with real movement rules', () => {
    const map = loadMap(level.map);
    expect(isReachable(map, config.player)).toEqual({ ok: true, unreachable: [] });
  });
});

it('level IDs are unique and contiguous', () => {
  expect(levels.map((l) => l.id)).toEqual(levels.map((_, i) => `level-${String(i + 1).padStart(3, '0')}`));
});

it('difficulty never drops more than one step unless flagged as a breather', () => {
  levels.slice(1).forEach((l, i) => {
    if (!l.breather) expect(l.difficulty).toBeGreaterThanOrEqual(levels[i]!.difficulty - 1);
  });
});

it('economy: first unlock within the GDD target, no infinite currency', () => {
  const result = simulateEconomy(levels, config.economy);
  expect(result.levelOfFirstUnlock).toBeLessThanOrEqual(config.economy.targets.firstUnlockByLevel);
  expect(result.maxBalance).toBeLessThan(config.economy.targets.maxBalance);
});

it('docs/game/levels.md is up to date (golden)', () => {
  expect(renderLevelReport(levels)).toEqual(readFileSync('../docs/game/levels.md', 'utf8'));
});
```

## Unity (EditMode, NUnit)

```csharp
public class LevelCatalogTests
{
    static LevelDefinition[] Levels => AssetDatabase.FindAssets("t:LevelDefinition")
        .Select(g => AssetDatabase.LoadAssetAtPath<LevelDefinition>(AssetDatabase.GUIDToAssetPath(g)))
        .OrderBy(l => l.Id).ToArray();

    [Test] public void Ids_AreUniqueAndContiguous() { ... }
    [Test] public void EveryLevel_HasNoMissingReferences() { ... }      // prefabs, tiles, sprites not null
    [Test] public void EveryLevel_GoalIsReachable() { ... }             // pure C# BFS in Game.Logic over the level grid
    [Test] public void Difficulty_DropsOnlyOnBreathers() { ... }
    [Test] public void Economy_FirstUnlockWithinTarget() { ... }        // simulation in Game.Logic
    [Test] public void LevelsReport_IsUpToDate() { ... }                // golden compare with docs/game/levels.md
}
```

For Tilemap-based levels: read the tiles into a plain grid (`bool[,] walkable`) in an Editor helper, then run the pure `Game.Logic` reachability on it.

## Reachability with real movement rules

Model the player's real abilities from the config (not guessed):
- Grid / top-down: BFS over walkable cells.
- Platformer: BFS over "standable" cells with edges for walk, jump (max height / distance from `config.player.jump`), fall; keys/doors as state (`position + keys held`) to catch soft-locks.
- Puzzle: a bounded solver (BFS/IDA*) proving a solution within the move limit; also record the minimum moves (useful for star thresholds).
