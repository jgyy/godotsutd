# Frog Shooter — Design Spec

Date: 2026-09-17
Engine: Godot 4.7 (GDScript)

## Goal

A small top-down shooter built entirely from the supplied `Assets.zip`. A frog
walks around a tile field, picks up staffs that let it shoot fireballs, and
survives waves of chasing insects. The deliverable is a runnable, testable
Godot project with one playable scene and a restart loop.

## Assets (verified layouts)

| File | Size | Layout |
|---|---|---|
| `Frog/Frog_Idle.png` | 160×32 | 5 idle frames, 32×32, facing down |
| `Frog/Frog_Walk.png` | 128×256 | 8 rows = directions (down, down-right, right, up-right, up, up-left, left, down-left); 4 columns = hop frames (crouch, crouch, leap, leap) |
| `Enemies.png` | 288×384 | 32×32 cells. Row 0: grasshopper 9 frames. Rows 2–5: dragonfly 2 frames each (colour variants). Row 7: ladybug 8 frames. Row 11: beetle 6 frames (unused). |
| `Staff/staff_wood.png`, `staff_crystal.png`, `staff_mighty.png` | 16×16 | single icons |
| `Staff/fireball.png` | 32×32 | single sprite |
| `TileMap/Ground tiles sample.png` | 288×192 | 32px grass/dirt atlas |
| `TileMap/Water sample.png` | 224×192 | 32px water atlas |
| `TileMap/Decorations sample.png` | 192×352 | 32px decoration atlas |

`frog_green_spritesheet.png` is a master sheet and is not referenced by any
scene. Assets keep their existing `.import` files.

## Project settings

- Viewport 640×360, stretch mode `canvas_items`, aspect `keep`, scale mode
  `integer`. Window starts at 1280×720.
- Default texture filter: nearest. 2D pixel snap on.
- Input actions: `move_left/right/up/down` (WASD + arrows), `fire` (Space,
  left mouse), `restart` (R).
- Physics layers: 1 player, 2 enemy, 3 projectile, 4 pickup, 5 world.

## Directory layout

```
project.godot
assets/            # contents of Assets.zip, unchanged
scenes/
  main.tscn        # World + Player + Spawner + HUD
  player.tscn
  enemy.tscn
  fireball.tscn
  staff_pickup.tscn
  hud.tscn
scripts/           # one .gd per scene, plus world_builder.gd, spawner.gd
resources/
  tileset.tres
  frog_frames.tres        # SpriteFrames
  enemy_frames_*.tres     # one SpriteFrames per enemy kind
tests/
  run_tests.gd     # headless runner
  test_*.gd
```

## Scenes and behaviour

### Main
Root `Node2D`. Children: `World`, `Player`, `Enemies` (container),
`Projectiles` (container), `Pickups` (container), `Spawner`, `HUD`
(CanvasLayer), `Camera2D` follows the player and is limited to the map.
Owns game state: score, current staff tier, game-over flag. Connects to
`Player.died`, `Player.health_changed`, `Enemy.died`, `StaffPickup.collected`.
On `restart` when game over, reloads the current scene.

### World
`TileMapLayer` with `tileset.tres`. `world_builder.gd` fills a 30×20 tile map
at `_ready`: outer 1-tile ring of water (physics layer 5, blocks player and
enemies), grass interior, a few rectangular dirt patches, a scattering of
decoration tiles on a second `TileMapLayer` with no collision. Map data is
deterministic (fixed seed) so tests can assert on it.

### Player
`CharacterBody2D`, collision layer 1, mask 5 (world) — enemy contact is
detected by the enemy's own Area2D, not by body collision.
- Speed 120 px/s. Reads move actions, normalises the vector.
- Facing: quantised to 8 directions from the last non-zero input; defaults
  to down. Selects the walk row. When idle, plays `idle` (the 5-frame strip).
- Health 3. `take_damage(amount)`: ignored while invulnerable; otherwise
  decrement, emit `health_changed(hp)`, start 0.5s invulnerability with a
  modulate flicker; emit `died` and disable processing at 0.
- Staff tier 0–3. `set_staff_tier(tier)` updates fire cooldown and damage:

  | tier | staff | cooldown (s) | damage |
  |---|---|---|---|
  | 0 | none | — | cannot fire |
  | 1 | wood | 0.50 | 1 |
  | 2 | crystal | 0.35 | 2 |
  | 3 | mighty | 0.20 | 3 |

- On `fire` when tier > 0 and cooldown elapsed: emits `fired(position,
  direction, damage)`; Main instantiates the fireball into `Projectiles`.
  Fire direction is the facing vector.

### Fireball
`Area2D`, layer 3, mask 2 (enemy) and 5 (world). Exported `speed` 260,
`damage`, `direction`. Moves in `_physics_process`. On entering an enemy:
calls `enemy.take_damage(damage)` and frees itself. On entering world tiles:
frees itself. Auto-frees after 2 s.

### Enemy
`CharacterBody2D`, layer 2, mask 5. Exported enum `kind`:

| kind | speed | hp | score | frames |
|---|---|---|---|---|
| grasshopper | 90 | 1 | 10 | row 0, 9 frames |
| dragonfly | 60 | 2 | 20 | row 2, 2 frames |
| ladybug | 35 | 4 | 30 | row 7, 8 frames |

Chases the player each physics tick (straight line via `move_and_slide`).
Sprite flips horizontally when moving left. Child `Area2D` (`Hurtbox`, mask
1) on body-entered player calls `player.take_damage(1)`; overlapping enemies
re-apply damage every 0.5 s while touching. `take_damage(amount)` reduces hp;
at 0 emits `died(score_value)` and frees.

### StaffPickup
`Area2D`, layer 4, mask 1. Exported `tier` (1–3) chooses the icon. On player
entered: emits `collected(tier)` and frees. Main then calls
`player.set_staff_tier(tier)` and, if tier < 3, spawns the next tier at a
random interior tile at least 6 tiles from the player after a 5 s delay.
Wood is spawned at game start near the centre.

### Spawner
`Node` with a `Timer`. Interval starts at 2.0 s and shrinks by 0.05 s per
spawn to a floor of 0.6 s. Each spawn picks a random point on the water ring
(just outside the playable area), picks a kind weighted 60/30/10
(grasshopper/dragonfly/ladybug), and adds an enemy to `Enemies`. Stops when
the player dies.

### HUD
`CanvasLayer`. Top-left: hearts drawn as three `TextureRect`s using a small
generated heart texture (no heart asset exists, so a 7×7 pixel heart is
drawn programmatically into an `ImageTexture` once). Top-right: score label.
Bottom-left: current staff icon (blank at tier 0). Centre: "GAME OVER —
press R" label, hidden until `Player.died`.

## Data flow

Signals only, no autoloads:

```
Player.fired            -> Main spawns Fireball
Player.health_changed   -> HUD.update_hearts
Player.died             -> Main.game_over -> Spawner.stop, HUD.show_game_over
Enemy.died(score)       -> Main.add_score -> HUD.update_score
StaffPickup.collected   -> Main.on_staff -> Player.set_staff_tier, HUD.set_staff, schedule next
```

## Error handling

- Missing SpriteFrames animation names fall back to `idle` with a
  `push_warning`.
- `set_staff_tier` clamps to 0–3.
- Fireball with zero direction is freed immediately (never spawned
  stationary).

## Testing

`tests/run_tests.gd` extends `SceneTree`, runs with
`godot --headless -s tests/run_tests.gd`, instantiates each `test_*.gd`,
calls every `test_` method, prints pass/fail, and quits with exit code 1 on
any failure. Tests:

- Player: staff tier table (cooldown, damage); cannot fire at tier 0;
  `take_damage` ignored during invulnerability; `died` emitted at 0 hp;
  facing quantisation for the 8 directions.
- Enemy: kind table; dies after the expected number of fireball hits.
- Fireball: moves along its direction; frees after lifetime.
- World: map is 30×20, ring is water, interior is not.
- Smoke: `main.tscn` instantiates without errors.

Also required: `godot --headless --import` completes with no errors.

## Out of scope

Menus, audio, saving, multiple levels, the beetle enemy, dragonfly colour
variants, decorations with collision.
