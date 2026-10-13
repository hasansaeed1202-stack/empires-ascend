# Empires Ascend - Version 0.1 Development Plan

**Issue:** MRN-98 - Design Empires Ascend Version 0.1 Development Plan
**Author:** Game Director (agent 19f813a7-cd33-45d0-8328-2bd7ef496a06)
**Engine:** Godot 4.x | **Target:** Windows PC (.exe)

## Purpose

Version 0.1 establishes the first playable RTS foundation: a small, self-contained skirmish prototype
in Godot for Windows PC. Following the project's development strategy, V0.1 is built as a sequence of
small verified milestones. Each milestone is independently testable and modular; no milestone expands
until its systems are stable.

## Scope constraints

- **PLANNING ONLY.** No game code is written by this task.
- **Original content only.** Nothing copied from Age of Empires, Rise of Nations, Rise of Legends,
  Civilization, or any other game: no assets, factions, maps, characters, music, names, stories, or code.
  All visuals use Godot primitives and free CC0 placeholders; all naming is original.
- **No purchases. No publishing or distribution.**
- **Performance target:** 60 FPS on modest Windows PCs with the V0.1 unit/building scale.

## V0.1 feature coverage map

| V0.1 feature                              | Milestone |
|-------------------------------------------|-----------|
| Godot project foundation & folder arch.   | M1        |
| Main menu & basic game scene              | M4        |
| RTS camera controls                       | M5        |
| Unit selection                            | M5        |
| Unit movement & pathfinding               | M5        |
| Villagers / workers                       | M6        |
| Food, Wood, Stone, Metal resources        | M2        |
| Resource gathering                        | M6        |
| Building placement & construction         | M7        |
| Town Center                               | M8        |
| Houses                                    | M8        |
| Farms                                     | M9        |
| Barracks                                  | M9        |
| Defensive tower                           | M9        |
| Population system                         | M8        |
| Basic melee unit                          | M10       |
| Basic ranged unit                         | M10       |
| Health & damage system                    | M3        |
| Basic combat                              | M10       |
| Simple enemy AI                           | M11       |
| Victory & defeat conditions               | M11       |
| Basic RTS HUD                             | M12       |
| First small Civilization DNA mechanic     | M12       |
| Save/load                                 | M12       |
| Performance for modest Windows PCs        | M13       |

## Milestone 1 - Godot project foundation & folder architecture

**Goal.** Bootstrap the V0.1 Godot project with a clean, modular folder architecture and core
conventions so subsequent milestones add features without rework.

**Systems / features involved.** project.godot configuration; input mappings; collision layers;
modular folder layout; core autoloads (GameManager, ResourceStore stub, SaveSystem stub, Constants);
Git workflow and coding conventions; placeholder-only art; passing default test scene.

**Dependencies.** None.

**Implementation tasks.**
1. Install/configure Godot 4.x; create project.godot with a clear default scene and Windows export
   template configuration.
2. Define folder layout: scripts/ (autoloads, core, gameplay, systems), scenes/, resources/,
   assets/ (art, audio), ui/, tests/, docs/, export/.
3. Create autoloads with thin documented interfaces: GameManager (state/load-save orchestration),
   ResourceStore (initialization + signals), SaveSystem (serialization contract), Constants
   (build costs, stat caps, performance constants).
4. Set up input mappings: camera (pan/zoom/rotate), selection (click + drag box), unit commands
   (move, attack, gather), UI navigation.
5. Configure physics collision layers/masks: Unit, Building, Terrain, Projectile, ResourceNode.
6. Establish Git flow (branch naming, commit convention) and a Godot .gitignore.
7. Write a coding conventions doc: naming, scene hierarchy rules, signal usage, resource ownership.
8. Add the first passing test scene: a quad running at >= 60 FPS to prove the toolchain builds and
   runs.

**Testing requirements.**
- Clean project rebuild from scratch.
- Default scene runs at >= 60 FPS on the target hardware profile.
- All autoloads are accessible from any scene with no errors.
- Windows export template produces an empty executable that launches the game.

**Definition of done.**
- Repo contains a clean V0.1 folder structure with project.godot and no stray files.
- Project builds and runs the default scene at >= 60 FPS.
- Autoloads (GameManager, ResourceStore, SaveSystem, Constants) load without errors and expose
  documented interfaces.
- Input mappings, collision layers, Git workflow, and conventions are documented in docs/.
- A Windows export builds an empty .exe.

## Milestone 2 - Resource system (Food, Wood, Stone, Metal)

**Goal.** Deliver a modular, data-driven resource store for the four V0.1 resources.

**Systems / features involved.** ResourceStore singleton (initialization, read/write, change signals);
resource data definitions; value clamping (no negatives); per-entity resource namespaces; HUD accessor
contract.

**Dependencies.** M1 (GameManager, Constants, autoload conventions).

**Implementation tasks.**
1. Finalize ResourceStore interface: add(resource, amount), subtract(resource, amount), get(resource),
   set(resource, amount), try_consume(resource, amount) returning success.
2. Create resources/ data files (one per resource) with base values and types.
3. Implement per-entity storage (player and AI namespaces), isolated from each other.
4. Emit resource_changed and resources_changed signals carrying old/new values.
5. Guard against negative balances and floating-point drift (round to integers).
6. Expose read-only HUD accessors that do not couple the HUD to the store internals.

**Testing requirements.**
- Editor-run test scene exercises add, subtract, set, try_consume and verifies signal payloads.
- Negative-balance guard verified programmatically.
- Rounding verified (float inputs become integers).
- Two namespaces (e.g., player1, player2) verified to not interfere.

**Definition of done.**
- All four resources (Food, Wood, Stone, Metal) load from data files.
- Store enforces non-negative, integer amounts.
- Signals propagate to every listener without memory growth on repeated changes.
- HUD accessors documented and tested as a read-only consumer.

## Milestone 3 - Unit & building data models + health/damage system

**Goal.** Provide abstract, modular entity models for units and buildings with health/damage, cost,
and population.

**Systems / features involved.** Entity base class; Unit and Building subclasses; stats container
(health, max_health, damage, attack_speed, movement_speed, range, build_cost, population_cost,
population_provided); HealthComponent (take_damage, invincibility, death signal); CostComponent;
PopulationComponent.

**Dependencies.** M1 (autoloads, Constants); M2 (ResourceStore).

**Implementation tasks.**
1. Create Entity base: transform, HealthComponent, CostComponent, PopulationComponent, tags, and a
   State enum (idle, moving, attacking, gathering, dying).
2. Build Unit (extends Entity) with movement fields and a command queue.
3. Build Building (extends Entity) with placement fields (placement_cost, population_cost,
   building_type: town_center/house/farm/barracks/tower) and no movement.
4. Implement HealthComponent: take_damage(damage, source, armor), clamped 0 to max, die(),
   on_death signal, brief invincibility frames.
5. Implement CostComponent: validate costs, pay on placement/production, refund on cancel (document
   refund policy).
6. Implement PopulationComponent: track population_cost/provided, emit pop-change signals.
7. Provide data-driven stat presets via resources/ for a sample unit and building.

**Testing requirements.**
- Spawn Unit and Building instances from presets.
- Damage reduces health; health = 0 triggers die() and emits on_death.
- Cost validation rejects placement below cost; population component tracks deltas.

**Definition of done.**
- Unit and Building base classes carry the full stat set (health, damage, cost, population, range,
  speed).
- Health/damage works end-to-end (damage -> die -> signal).
- Stats are data-driven, not hard-coded.
- A test scene spawns instances and exercises damage/death.

## Milestone 4 - Main menu & basic game scene

**Goal.** Provide the player entry point (main menu) and a basic game scene that hosts all later
gameplay systems.

**Systems / features involved.** Main menu (New Game, Quit, settings stub); basic game scene (terrain
plane with collision, empty layers for units/buildings); GameManager scene-lifecycle wiring; placeholder
art.

**Dependencies.** M1 (GameManager).

**Implementation tasks.**
1. Create main menu scene: New Game, Quit, title; thin UI scripts wired to GameManager (no HUD yet).
2. Create the basic game scene: collision terrain plane, empty layers for future content, camera
   configured but not yet interactive.
3. GameManager wires Menu -> Game scene and Game -> GameManager ready/pause states.
4. Provide placeholder art (planes, basic shapes) for terrain and UI.
5. Document scene transitions and the expected lifecycle sequence.

**Testing requirements.**
- Start a game from the menu and return to the menu.
- New Game starts a clean scene; Quit closes the window.
- Scene load time measured in editor and export (target < 5 s).

**Definition of done.**
- Main menu is navigable with keyboard and mouse.
- Basic game scene loads and runs without errors or missing-resource warnings.
- GameManager transitions correctly between menu and game states.
- Load-time target met in both editor and export builds.

## Milestone 5 - RTS camera, unit selection, movement & pathfinding

**Goal.** Deliver core RTS controls: camera panning/zooming/rotation, point-and-click unit selection,
movement commands, and pathfinding around obstacles.

**Systems / features involved.** Camera controller; input-to-command router; selection manager; unit
movement controller; pathfinding (NavigationServer2D/NavigationRegion2D with a sample navmesh, or an
A* grid fallback); per-unit command queue.

**Dependencies.** M3 (Unit base, Entity).

**Implementation tasks.**
1. Camera controller: pan via WASD, mouse-edge, and drag; zoom via scroll wheel with min/max clamps;
   right-click centers camera on selected unit.
2. Selection manager: single-click select, drag box multi-select, Shift-click add/remove, right-click
   deselect, plus highlight (outline/glow material).
3. Unit movement: click issues a MoveCommand; path-following at unit speed; stop at obstacles; cancel
   with right-click.
4. Pathfinding: bake a navmesh from collision terrain, or implement A* on a walkable grid; report
   unreachable targets and move the unit as close as possible.
5. Command queue so units process moves sequentially and immediately honor new orders.
6. Editor test area with walls/obstacles to validate pathing.

**Testing requirements.**
- Select one unit, a group, invert selection.
- Move a unit to a point; it follows the path, stops at an obstacle, cancels on a new order.
- Camera zoom range works; edge-panning and center-on-selection are responsive.
- A* returns the shortest valid route; unreachable commands fail visibly.

**Definition of done.**
- Camera pan/zoom/deselect works and stays >= 60 FPS.
- Single and box selection function with clear highlights.
- Units move to command points along valid paths and stop at obstacles.
- Pathfinding handles unreachable targets gracefully.
- Test map with obstacles passes manual checks plus an automated path check.

## Milestone 6 - Villagers/workers & resource gathering

**Goal.** Implement the worker unit (villager) and its gather/return cycle for resource nodes.

**Systems / features involved.** Villager unit type with task states (idle, moving_to_resource,
gathering, returning, delivering); a task/command system; interactable resource nodes with finite
yields; carry/bank mechanics.

**Dependencies.** M2 (ResourceStore); M3 (Unit, Health); M5 (movement, command queue).

**Implementation tasks.**
1. Define Villager: gather capability, movement speed, carry capacity.
2. Task system commands: gather(resource_type, node_id), return_to(town_center), follow, stop.
3. Resource node scenes: Tree (wood), Berry Bush (food), Stone Rock (stone), Metal Ore (metal),
   each exposing remaining_yield.
4. Proximity interaction: villager approaches a node, gathers, depletes it, carries a load, and
   returns to the Town Center.
5. Delivery: Town Center add_resource() on villager arrival; optional node respawn after depletion
   (document the chosen V0.1 behavior).
6. Idle and return-to-base behaviors when the villager has no tasks.

**Testing requirements.**
- Command a villager to gather wood: it reaches the tree, gathers, returns to the Town Center, and
  wood increments.
- Node yield depletes; villager stops gathering and resumes idle/return behavior.
- Two villagers gather concurrently without double-feeding resources.
- Delivery only counts when the villager is within the Town Center.

**Definition of done.**
- Villagers can be spawned and issued gather commands.
- Gathering depletes resource nodes and deposits resources at the Town Center.
- Resource totals update correctly after delivery; no double-counting.
- Villagers return to base and idle sensibly when idle.

## Milestone 7 - Building placement & construction system

**Goal.** Implement building placement with cost, population, and terrain validation, plus a
construction queue.

**Systems / features involved.** BuildingPlacer input with ghost preview and valid/invalid feedback;
placement validation rules; construction queue; placement undo/cancel; construction progress indicator
(stub).

**Dependencies.** M2 (ResourceStore); M3 (Building, Cost, Population); M5 (selection/movement); M4
(game scene).

**Implementation tasks.**
1. BuildingPlacer: on right-click show a ghost with cost and pop cost, a valid-placement outline,
   and a reason for invalid placements (range, cost, population, terrain, distance, overlap).
2. Validation rules: can afford cost, population within cap, buildable terrain, minimum distance from
   other buildings (simple radius for V0.1), no overlap with units or other buildings.
3. Construction queue: queue multiple buildings, build one at a time, show progress, support cancel
   per the documented refund policy.
4. Create the building instance on completion (instant spawn with a brief flash; no animation in V0.1).
5. Provide cancel/undo and invalid-placement feedback paths.

**Testing requirements.**
- Place each V0.1 building; confirm resource deduction.
- Reject placement below cost, above population, on non-buildable terrain, and overlapping buildings.
- Queue at least two buildings; only one constructs at a time.
- Canceling construction exercises the documented refund behavior.

**Definition of done.**
- Building placement preview works with clear valid/invalid feedback.
- Cost and population are enforced; invalid placements cannot be placed.
- The construction queue builds one building at a time with a progress indicator.
- Completed buildings appear on the map and are selectable.

## Milestone 8 - Town Center, population system & Houses

**Goal.** Implement the Town Center (production hub and resource deposit), population caps, and Houses
that expand population capacity.

**Systems / features involved.** PopulationManager singleton; TownCenter (deposit zone, spawn hub);
House (population-cap bonus); population UI accessor contract; spawn enforcement.

**Dependencies.** M2 (ResourceStore); M3 (Building, Cost, Population); M6 (villager delivery path); M7
(building system).

**Implementation tasks.**
1. PopulationManager: current_population, population_cap, can_spawn(), register(), deregister(), and
   pop-change signals.
2. Town Center: resource deposit when a villager arrives, spawn-interface hook, population
   contribution.
3. House: cost, population-cap bonus, placement rule (near the Town Center).
4. Population UI accessor contract (HUD consumers read through it; UI rendered in M12).
5. Enforcement: spawn attempts over the cap are rejected with visible feedback.

**Testing requirements.**
- Spawning a unit at the population cap is rejected.
- Building a House raises the cap and the population readback reflects the change.
- Population tracks unit deaths and removals correctly.

**Definition of done.**
- PopulationManager enforces caps consistently across all spawns.
- Town Center contributes to population and deposits resources.
- House raises the population cap on construction.
- Test scenario verifies cap enforcement and population delta tracking.

## Milestone 9 - Farms, Barracks, defensive tower & unit production

**Goal.** Implement food production (Farm), military production (Barracks), and the defensive tower.

**Systems / features involved.** Farm (periodic food production); Barracks (unit production with costs
and queue); defensive tower (auto-target + projectile); unit production system (cost + population
deduction, queue).

**Dependencies.** M2 (resources); M3 (stats, health); M6 (villager task system, optional worker); M8
(population, Town Center).

**Implementation tasks.**
1. Farm: timer produces food every interval; allow villager assignment or auto-production (document
   the V0.1 choice); production accessor for the HUD.
2. Barracks: buildable unit types (melee, ranged) with resource and population costs and build times.
3. Unit production: pay costs and pop, create the unit instance, add it to the world; queue multiple
   units.
4. Defensive tower: detect targets within radius with line-of-sight each tick; pick highest-priority
   enemy (nearest, then lowest health); fire a projectile.
5. Simple projectile system: moving entity with collision that applies damage on hit.

**Testing requirements.**
- Farms produce food at the configured interval.
- Barracks trains melee and ranged units; costs and population are deducted.
- The tower detects and fires on an enemy unit entering range; the projectile deals damage.
- Over-population blocks production.

**Definition of done.**
- Farms generate food over time (as documented).
- Barracks produces melee and ranged units on demand through a queue.
- The defensive tower auto-engages enemies in range and deals damage.
- Production queues and resource/pop enforcement all function correctly.

## Milestone 10 - Basic melee & ranged units & basic combat

**Goal.** Implement the two V0.1 unit types and their combat behaviors.

**Systems / features involved.** MeleeUnit (short range, swing timer, stop-to-attack); RangedUnit
(long range, projectile, pause-while-shooting); target selection (nearest/lowest-health, unit-vs-building
priority); attack cooldowns; damage application; death; units damaging buildings.

**Dependencies.** M3 (stats, health); M5 (movement); M8/M9 (production, Town Center, barracks).

**Implementation tasks.**
1. MeleeUnit: attack state/animation stub, short attack range, stop when attacking, area stub around
   the unit.
2. RangedUnit: projectile attack, long attack range, maintain distance, pause movement on fire.
3. Attack state machine: find the nearest valid enemy (unit or building), enforce cooldowns, apply
   damage.
4. Target priority: injured > nearest; document whether units prefer enemy units or buildings at equal
   priority.
5. Combat demo arena: spawn unit pairs, log damage through death; no HUD numbers in V0.1.

**Testing requirements.**
- A melee unit stops and swings at an enemy; damage applies.
- A ranged unit stops/pauses and fires; the projectile deals damage.
- Both unit types damage buildings.
- Units switch targets when a target dies.

**Definition of done.**
- Melee and ranged units attack independently and correctly.
- Combat resolves through damage -> health -> death.
- Units re-target when targets die.
- The demo arena verifies a fight from spawn to death.

## Milestone 11 - Simple enemy AI & victory/defeat conditions

**Goal.** Implement a simple enemy AI and the V0.1 win/loss conditions.

**Systems / features involved.** EnemyAI state machine (idle -> scout/explore -> gather -> build ->
attack); simple AI pathfinding; enemy faction manager; victory condition (destroy all enemy units and
buildings); defeat condition (player Town Center destroyed, or all player units eliminated).

**Dependencies.** M2 (resources); M3; M8; M10 (units, combat); M7/M9 (buildings, production).

**Implementation tasks.**
1. EnemyAI manager: controls one enemy faction with starting resources, villager spawn, building
   spawn, and unit spawn.
2. State machine with timers: early scouts explore, then build Town Center and House, gather food,
   build a Barracks, spawn attack groups.
3. Attack logic: groups of units move to the nearest player unit/building and engage; retry when the
   path is blocked.
4. Victory screen: all enemy entities eliminated, with a restart option.
5. Defeat screen: player Town Center destroyed (or all player units eliminated), with restart.
6. Debug logging for AI state transitions.

**Testing requirements.**
- The enemy progresses through all states within target times.
- The enemy attacks player units and buildings; the player can win by eliminating all enemies.
- The player loses when the Town Center is destroyed.
- AI retries blocked attacks instead of getting stuck.

**Definition of done.**
- Enemy AI progresses through scout -> gather -> build -> attack.
- Victory and defeat screens trigger from the documented conditions.
- The AI does not get permanently stuck; retry logic works.
- A test scenario confirms a defended player can beat the AI and an unbalanced scenario ends in
  defeat.

## Milestone 12 - Basic RTS HUD, Civilization DNA mechanic, save/load

**Goal.** Add the basic RTS HUD, the first Civilization DNA decision mechanic, and practical save/load.

**Systems / features involved.** HUD (resource row, population, selected-unit panel); CivilizationDNA
tracker (behavior metrics + a single branching decision point); SaveSystem full-state serialization
with a slot UI (one save slot for V0.1).

**Dependencies.** M2 (resources); M3; M5; M8; M10; M11.

**Implementation tasks.**
1. HUD: resource row that updates on ResourceStore signals; population label; selected-unit panel
   showing name, health bar, and unit type.
2. CivilizationDNA tracker: metrics collector subscribed to gather/build/training signals; a trait
   store; a decision-point controller that fires once after a behavior threshold and offers two
   mutually exclusive paths, each setting a persistent trait with a small, documented mechanical
   effect (for example, a 5% bonus to one resource category, applied only in V0.1).
3. SaveSystem: serialize game state (resources, population, units, buildings, DNA trait, positions),
   one save slot with a slot UI, load, and verify the loaded state matches.
4. Save/load round-trip QA with units, buildings, resources, and the DNA trait preserved.
5. Basic polish: consistent units/spacings, readable fonts, no visual overlap, sound stubs.

**Testing requirements.**
- The HUD reflects current resources and population in real time.
- A save at any point and a subsequent load restore identical state.
- The DNA decision point fires once at threshold and locks the alternate path.
- The performance budget from M13 is re-measured before final sign-off.

**Definition of done.**
- The HUD displays all V0.1 resources, population, and the selected unit's health.
- Save/load round-trips without data loss.
- The DNA decision point fires once and records the player's branch.
- All V0.1 features function together in one playable skirmish session.

## Milestone 13 - Performance tuning for modest Windows PCs

**Goal.** Verify and tune performance so V0.1 runs at >= 60 FPS on modest Windows hardware at the
intended unit/building scale.

**Systems / features involved.** Profiling baseline (unit/building counts, FPS, memory, draw calls);
optimizations: instance meshes, navmesh simplification, culling, batched UI updates, signal throttling;
regression test.

**Dependencies.** All previous milestones.

**Implementation tasks.**
1. Establish baseline metrics at target scale (e.g., 40 units, 15 buildings, 5 towers); record the
   modest hardware profile (document CPU/GPU/RAM).
2. Profile CPU (pathfinding, AI updates) and GPU (draw calls, shaders).
3. Apply optimizations: shared/instance meshes for units and buildings, navmesh simplification, per-tick
   AI update caps, signal throttling, UI batching.
4. Re-test and confirm >= 60 FPS sustained on the modest profile; document any remaining limits.
5. Add a performance regression test scene with a fixed unit/building count and an FPS gate.

**Testing requirements.**
- >= 60 FPS at target scale on the modest hardware profile.
- Memory and CPU stable over a 5-minute session (no leaks).
- Pathfinding and AI remain correct after optimization.

**Definition of done.**
- V0.1 achieves >= 60 FPS at target scale on the modest hardware profile.
- Baseline and regression test scene are added to tests/.
- Performance notes are documented in docs/.

## Recommended first milestone & specialist agent

**Implement first: Milestone 1 (Godot project foundation & folder architecture).**

Rationale: it is dependency-free bootstrap work; every later milestone depends on its autoloads, input
mappings, collision layers, conventions, and toolchain. A clean foundation prevents rework and keeps
each subsequent milestone fast and testable.

**Recommended specialist development agent: a Godot/engine-setup specialist (core systems developer).**

Role focus: Godot 4.x project configuration, autoload/scene architecture, input systems, collision
layers, and modular folder conventions. This agent delivers the V0.1 project structure, core autoloads,
and a passing default test build, after which gameplay specialists take over Milestones 2 and later.

## Non-goals for Version 0.1

Kept deliberately out of scope to remain testable: multiple civilizations or factions; fog of war,
exploration, or mapping; technology trees, research, or era evolution; cavalry, siege weapons, or
formations; diplomacy or trade; multiplayer; polished art, music, or sound.

## Copyright & licensing constraints

- All content must be original or CC0/free.
- Do not copy Age of Empires, Rise of Nations, Rise of Legends, Civilization, or any other game's
  assets, factions, maps, stories, music, names, or code.
- No purchases. No publishing or distribution.
