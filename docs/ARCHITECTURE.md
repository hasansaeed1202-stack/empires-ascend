# Foundation architecture

## Directory layout

- `assets/art/` and `assets/audio/`: original or suitably licensed source assets.
- `scenes/`: composed Godot scenes, grouped by feature.
- `scripts/autoloads/`: globally available lifecycle and service boundaries.
- `scripts/core/`: reusable engine-facing controllers and base code.
- `scripts/gameplay/`: future units, buildings, combat, and Civilization DNA logic.
- `scripts/systems/`: future feature services such as selection and assignment.
- `resources/`: future data-driven Godot Resource definitions and instances.
- `ui/`: future UI scenes, scripts, themes, and icons.
- `tests/`: smoke and regression scenes/scripts.
- `docs/`: architecture, conventions, economy, and setup guidance.
- `export/`: ignored local Windows build output.

Empty future-facing folders contain `.gitkeep` placeholders. Milestones should
remove a placeholder when adding real files.

## Boundaries

`GameManager` owns high-level state and will coordinate scene/save operations.
`ResourceStore` owns economy balances without UI or production dependencies.
`SaveSystem` owns versioned serialization without gameplay knowledge.
`Constants` contains stable cross-cutting limits; feature tuning belongs in
data-driven Resources. Gameplay nodes consume these interfaces but do not make
autoloads depend on scenes.

This dependency direction keeps future worker assignment, buildings, combat,
and Civilization DNA independently replaceable and testable.

## Collision layers

| Layer | Name | Intended owner |
| --- | --- | --- |
| 1 | Unit | Mobile units and workers |
| 2 | Building | Placed structures |
| 3 | Terrain | Walkable/static world geometry |
| 4 | Projectile | Combat projectiles |
| 5 | ResourceNode | Gatherable world objects |

## Input contracts

Camera, selection, command, and UI actions are named in `project.godot`.
Milestones should consume action names rather than hard-coded keys. Selection and
unit-command actions are configuration contracts only in this milestone.
