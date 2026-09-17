# Frog Shooter Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** A runnable Godot 4.7 top-down shooter where a frog collects staff upgrades and shoots fireballs at chasing insects, with a headless test suite.

**Architecture:** One `Main` scene composes `World` (code-built TileSet and map), `Player`, `Spawner`, `HUD`, plus container nodes for enemies, projectiles and pickups. All cross-scene communication is via signals connected in `main.gd`. SpriteFrames and the TileSet are built in code from the supplied atlases (`scripts/sprite_sheets.gd`, `scripts/world.gd`) rather than hand-written `.tres` files, so frame coordinates live in one testable place.

**Tech Stack:** Godot 4.7.2 (binary at `/usr/bin/godot`), GDScript, custom headless test runner.

**Spec:** `docs/superpowers/specs/2026-09-17-frog-shooter-design.md`

## Global Constraints

- Godot 4.7; run tests with `godot --headless -s tests/run_tests.gd` from the project root; exit code must be 0.
- `godot --headless --import --path .` must complete without errors.
- Viewport 640×360, stretch `canvas_items` / `keep` / `integer`, window 1280×720, nearest filtering, 2D pixel snap.
- Assets stay at `res://Assets/...` (capital A) so the supplied `.import` files and UIDs remain valid.
- Physics layers: 1 player (bit 1), 2 enemy (bit 2), 3 projectile (bit 4), 4 pickup (bit 8), 5 world (bit 16).
- Deviation from spec, agreed here: enemies have collision mask 0 (they fly over the water ring) so they can spawn on ring cells without depenetration glitches. SpriteFrames and TileSet are built in code, not `.tres`.
- Commit after every task with the `Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>` trailer.

---

## File structure

| Path | Responsibility |
|---|---|
| `project.godot` | Settings, input map, layer names |
| `.gitignore` | ignore `.godot/` |
| `Assets/**` | unzipped assets, unchanged |
| `scripts/sprite_sheets.gd` | `SpriteSheets`: frame tables, `frog_frames()`, `enemy_frames()`, `direction_index()` |
| `scripts/world.gd` + `scenes/world.tscn` | `World`: TileSet construction, map fill, cell helpers |
| `scripts/player.gd` + `scenes/player.tscn` | `Player`: movement, facing, health, staff tiers, firing |
| `scripts/fireball.gd` + `scenes/fireball.tscn` | `Fireball`: straight-line projectile |
| `scripts/enemy.gd` + `scenes/enemy.tscn` | `Enemy`: kinds, chase, contact damage |
| `scripts/staff_pickup.gd` + `scenes/staff_pickup.tscn` | `StaffPickup` |
| `scripts/spawner.gd` | `Spawner`: timer, interval decay, kind weighting |
| `scripts/hud.gd` + `scenes/hud.tscn` | `HUD` |
| `scripts/main.gd` + `scenes/main.tscn` | wiring, score, staff progression, game over |
| `tests/test_suite.gd` | `TestSuite` base with assertions |
| `tests/run_tests.gd` | runner |
| `tests/test_*.gd` | one suite per unit |

---

### Task 1: Project skeleton and test runner

**Files:**
- Create: `project.godot`, `.gitignore`, `Assets/` (from zip), `tests/test_suite.gd`, `tests/run_tests.gd`, `tests/test_runner_smoke.gd`

**Interfaces:**
- Produces: `TestSuite` (RefCounted) with `tree: SceneTree`, `assert_true(cond, msg)`, `assert_eq(actual, expected, msg)`, `assert_approx(a, b, msg)`. Runner discovers `tests/test_*.gd`, runs every `test_*` method, exits 1 on failure.

- [ ] **Step 1: Unzip assets and write .gitignore**

```bash
cd /home/jegoh/Documents/repo/godotsutd && unzip -oq Assets.zip && printf '.godot/\n*.tmp\n' > .gitignore
```

- [ ] **Step 2: Write project.godot**

```ini
; Engine configuration file.
config_version=5

[application]

config/name="Frog Shooter"
run/main_scene="res://scenes/main.tscn"
config/features=PackedStringArray("4.7", "GL Compatibility")

[display]

window/size/viewport_width=640
window/size/viewport_height=360
window/size/window_width_override=1280
window/size/window_height_override=720
window/stretch/mode="canvas_items"
window/stretch/aspect="keep"
window/stretch/scale_mode="integer"

[input]

move_left={
"deadzone": 0.5,
"events": [Object(InputEventKey,"resource_local_to_scene":false,"resource_name":"","device":-1,"window_id":0,"alt_pressed":false,"shift_pressed":false,"ctrl_pressed":false,"meta_pressed":false,"pressed":false,"keycode":0,"physical_keycode":65,"key_label":0,"unicode":97,"location":0,"echo":false,"script":null)
, Object(InputEventKey,"resource_local_to_scene":false,"resource_name":"","device":-1,"window_id":0,"alt_pressed":false,"shift_pressed":false,"ctrl_pressed":false,"meta_pressed":false,"pressed":false,"keycode":0,"physical_keycode":4194319,"key_label":0,"unicode":0,"location":0,"echo":false,"script":null)
]
}
move_right={
"deadzone": 0.5,
"events": [Object(InputEventKey,"resource_local_to_scene":false,"resource_name":"","device":-1,"window_id":0,"alt_pressed":false,"shift_pressed":false,"ctrl_pressed":false,"meta_pressed":false,"pressed":false,"keycode":0,"physical_keycode":68,"key_label":0,"unicode":100,"location":0,"echo":false,"script":null)
, Object(InputEventKey,"resource_local_to_scene":false,"resource_name":"","device":-1,"window_id":0,"alt_pressed":false,"shift_pressed":false,"ctrl_pressed":false,"meta_pressed":false,"pressed":false,"keycode":0,"physical_keycode":4194321,"key_label":0,"unicode":0,"location":0,"echo":false,"script":null)
]
}
move_up={
"deadzone": 0.5,
"events": [Object(InputEventKey,"resource_local_to_scene":false,"resource_name":"","device":-1,"window_id":0,"alt_pressed":false,"shift_pressed":false,"ctrl_pressed":false,"meta_pressed":false,"pressed":false,"keycode":0,"physical_keycode":87,"key_label":0,"unicode":119,"location":0,"echo":false,"script":null)
, Object(InputEventKey,"resource_local_to_scene":false,"resource_name":"","device":-1,"window_id":0,"alt_pressed":false,"shift_pressed":false,"ctrl_pressed":false,"meta_pressed":false,"pressed":false,"keycode":0,"physical_keycode":4194320,"key_label":0,"unicode":0,"location":0,"echo":false,"script":null)
]
}
move_down={
"deadzone": 0.5,
"events": [Object(InputEventKey,"resource_local_to_scene":false,"resource_name":"","device":-1,"window_id":0,"alt_pressed":false,"shift_pressed":false,"ctrl_pressed":false,"meta_pressed":false,"pressed":false,"keycode":0,"physical_keycode":83,"key_label":0,"unicode":115,"location":0,"echo":false,"script":null)
, Object(InputEventKey,"resource_local_to_scene":false,"resource_name":"","device":-1,"window_id":0,"alt_pressed":false,"shift_pressed":false,"ctrl_pressed":false,"meta_pressed":false,"pressed":false,"keycode":0,"physical_keycode":4194322,"key_label":0,"unicode":0,"location":0,"echo":false,"script":null)
]
}
fire={
"deadzone": 0.5,
"events": [Object(InputEventKey,"resource_local_to_scene":false,"resource_name":"","device":-1,"window_id":0,"alt_pressed":false,"shift_pressed":false,"ctrl_pressed":false,"meta_pressed":false,"pressed":false,"keycode":0,"physical_keycode":32,"key_label":0,"unicode":32,"location":0,"echo":false,"script":null)
, Object(InputEventMouseButton,"resource_local_to_scene":false,"resource_name":"","device":-1,"window_id":0,"alt_pressed":false,"shift_pressed":false,"ctrl_pressed":false,"meta_pressed":false,"button_mask":1,"position":Vector2(0, 0),"global_position":Vector2(0, 0),"factor":1.0,"button_index":1,"canceled":false,"pressed":true,"double_click":false,"script":null)
]
}
restart={
"deadzone": 0.5,
"events": [Object(InputEventKey,"resource_local_to_scene":false,"resource_name":"","device":-1,"window_id":0,"alt_pressed":false,"shift_pressed":false,"ctrl_pressed":false,"meta_pressed":false,"pressed":false,"keycode":0,"physical_keycode":82,"key_label":0,"unicode":114,"location":0,"echo":false,"script":null)
]
}

[layer_names]

2d_physics/layer_1="player"
2d_physics/layer_2="enemy"
2d_physics/layer_3="projectile"
2d_physics/layer_4="pickup"
2d_physics/layer_5="world"

[rendering]

textures/canvas_textures/default_texture_filter=0
renderer/rendering_method="gl_compatibility"
renderer/rendering_method.mobile="gl_compatibility"
2d/snap/snap_2d_transforms_to_pixel=true
```

- [ ] **Step 3: Write tests/test_suite.gd**

```gdscript
class_name TestSuite
extends RefCounted

var tree: SceneTree
var failures: Array[String] = []


func assert_true(cond: bool, msg: String) -> void:
	if not cond:
		failures.append(msg)


func assert_eq(actual: Variant, expected: Variant, msg: String = "") -> void:
	if actual != expected:
		failures.append("%s: expected %s, got %s" % [msg, str(expected), str(actual)])


func assert_approx(actual: float, expected: float, msg: String = "") -> void:
	if not is_equal_approx(actual, expected):
		failures.append("%s: expected ~%s, got %s" % [msg, str(expected), str(actual)])
```

- [ ] **Step 4: Write tests/run_tests.gd**

```gdscript
extends SceneTree
## Headless test runner: godot --headless -s tests/run_tests.gd


func _initialize() -> void:
	_run()


func _run() -> void:
	await process_frame
	var total := 0
	var failed := 0
	var dir := DirAccess.open("res://tests")
	var files: Array[String] = []
	for f in dir.get_files():
		if f.begins_with("test_") and f.ends_with(".gd") and f != "test_suite.gd":
			files.append(f)
	files.sort()
	for f in files:
		var script: GDScript = load("res://tests/" + f)
		var suite: TestSuite = script.new()
		suite.tree = self
		for m in script.get_script_method_list():
			if not m.name.begins_with("test_"):
				continue
			total += 1
			suite.failures.clear()
			await suite.call(m.name)
			await process_frame
			if suite.failures.is_empty():
				print("PASS %s.%s" % [f, m.name])
			else:
				failed += 1
				for msg in suite.failures:
					print("FAIL %s.%s: %s" % [f, m.name, msg])
	print("%d tests, %d failed" % [total, failed])
	quit(1 if failed > 0 else 0)
```

- [ ] **Step 5: Write tests/test_runner_smoke.gd**

```gdscript
extends TestSuite


func test_runner_works() -> void:
	assert_eq(1 + 1, 2, "arithmetic")
```

- [ ] **Step 6: Import and run**

Run: `godot --headless --import --path . 2>&1 | grep -i error; godot --headless -s tests/run_tests.gd`
Expected: no error lines; `PASS test_runner_smoke.gd.test_runner_works` and `1 tests, 0 failed`.

- [ ] **Step 7: Commit**

```bash
git add -A && git commit -m "Scaffold Godot project, assets and headless test runner"
```

---

### Task 2: SpriteSheets (frames and facing)

**Files:**
- Create: `scripts/sprite_sheets.gd`, `tests/test_sprite_sheets.gd`

**Interfaces:**
- Produces: `SpriteSheets.DIRECTION_NAMES: Array[String]` (8 entries starting "down" clockwise as listed in spec), `SpriteSheets.direction_index(v: Vector2) -> int`, `SpriteSheets.frog_frames() -> SpriteFrames` (animations `idle`, `walk_<dir>`), `SpriteSheets.enemy_frames(row: int, count: int, fps: float) -> SpriteFrames` (animation `move`).

- [ ] **Step 1: Write the failing test**

```gdscript
extends TestSuite


func test_direction_index_eight_ways() -> void:
	assert_eq(SpriteSheets.direction_index(Vector2.DOWN), 0, "down")
	assert_eq(SpriteSheets.direction_index(Vector2(1, 1)), 1, "down_right")
	assert_eq(SpriteSheets.direction_index(Vector2.RIGHT), 2, "right")
	assert_eq(SpriteSheets.direction_index(Vector2(1, -1)), 3, "up_right")
	assert_eq(SpriteSheets.direction_index(Vector2.UP), 4, "up")
	assert_eq(SpriteSheets.direction_index(Vector2(-1, -1)), 5, "up_left")
	assert_eq(SpriteSheets.direction_index(Vector2.LEFT), 6, "left")
	assert_eq(SpriteSheets.direction_index(Vector2(-1, 1)), 7, "down_left")


func test_frog_frames() -> void:
	var f := SpriteSheets.frog_frames()
	assert_true(f.has_animation("idle"), "idle exists")
	assert_eq(f.get_frame_count("idle"), 5, "idle frames")
	for d in SpriteSheets.DIRECTION_NAMES:
		assert_true(f.has_animation("walk_" + d), "walk_" + d)
		assert_eq(f.get_frame_count("walk_" + d), 4, "walk frames " + d)
	var tex: AtlasTexture = f.get_frame_texture("walk_right", 0)
	assert_eq(tex.region, Rect2(0, 64, 32, 32), "walk_right row 2 frame 0")


func test_enemy_frames() -> void:
	var f := SpriteSheets.enemy_frames(7, 8, 8.0)
	assert_eq(f.get_frame_count("move"), 8, "ladybug frames")
	var tex: AtlasTexture = f.get_frame_texture("move", 3)
	assert_eq(tex.region, Rect2(96, 224, 32, 32), "row 7 frame 3")
```

- [ ] **Step 2: Run to verify it fails**

Run: `godot --headless -s tests/run_tests.gd`
Expected: parse error mentioning `SpriteSheets` not found (runner exits non-zero).

- [ ] **Step 3: Write scripts/sprite_sheets.gd**

```gdscript
class_name SpriteSheets
extends RefCounted
## Builds SpriteFrames from the 32px atlases and maps vectors to 8-way facing.

const CELL := 32
const DIRECTION_NAMES: Array[String] = [
	"down", "down_right", "right", "up_right", "up", "up_left", "left", "down_left",
]
const FROG_IDLE := "res://Assets/Frog/Frog_Idle.png"
const FROG_WALK := "res://Assets/Frog/Frog_Walk.png"
const ENEMIES := "res://Assets/Enemies.png"


static func direction_index(v: Vector2) -> int:
	# angle(): right = 0, down = +90deg. Rows: down=0 then clockwise-on-screen.
	var step := roundi(v.angle() / (PI / 4.0))
	return posmod(2 - step, 8)


static func cell(texture: Texture2D, col: int, row: int) -> AtlasTexture:
	var at := AtlasTexture.new()
	at.atlas = texture
	at.region = Rect2(col * CELL, row * CELL, CELL, CELL)
	return at


static func add_row(frames: SpriteFrames, anim: String, texture: Texture2D, row: int, count: int, fps: float) -> void:
	if not frames.has_animation(anim):
		frames.add_animation(anim)
	frames.set_animation_speed(anim, fps)
	frames.set_animation_loop(anim, true)
	for c in count:
		frames.add_frame(anim, cell(texture, c, row))


static func frog_frames() -> SpriteFrames:
	var frames := SpriteFrames.new()
	frames.remove_animation("default")
	add_row(frames, "idle", load(FROG_IDLE), 0, 5, 6.0)
	var walk: Texture2D = load(FROG_WALK)
	for i in DIRECTION_NAMES.size():
		add_row(frames, "walk_" + DIRECTION_NAMES[i], walk, i, 4, 8.0)
	return frames


static func enemy_frames(row: int, count: int, fps: float) -> SpriteFrames:
	var frames := SpriteFrames.new()
	frames.remove_animation("default")
	add_row(frames, "move", load(ENEMIES), row, count, fps)
	return frames
```

- [ ] **Step 4: Run tests**

Run: `godot --headless -s tests/run_tests.gd`
Expected: all PASS, `4 tests, 0 failed`.

- [ ] **Step 5: Commit**

```bash
git add scripts/sprite_sheets.gd tests/test_sprite_sheets.gd && git commit -m "Add SpriteSheets frame builder and 8-way facing"
```

---

### Task 3: World (TileSet and map)

**Files:**
- Create: `scripts/world.gd`, `scenes/world.tscn`, `tests/test_world.gd`

**Interfaces:**
- Produces: `World` (Node2D) with `WIDTH=30`, `HEIGHT=20`, `TILE=32`, `build()`, `is_ring(c: Vector2i) -> bool`, `cell_to_world(c: Vector2i) -> Vector2`, `random_interior_cell(rng) -> Vector2i`, `random_ring_position(rng) -> Vector2`, `random_cell_away_from(pos: Vector2, min_tiles: int, rng) -> Vector2i`, `size_px() -> Vector2`, and child `TileMapLayer` nodes `Ground` and `Decor`.

- [ ] **Step 1: Write the failing test**

```gdscript
extends TestSuite


func _make() -> World:
	var w: World = load("res://scenes/world.tscn").instantiate()
	tree.root.add_child(w)
	w.build()
	return w


func test_map_dimensions_and_ring() -> void:
	var w := _make()
	var ground: TileMapLayer = w.get_node("Ground")
	assert_eq(ground.get_used_cells().size(), World.WIDTH * World.HEIGHT, "all cells filled")
	assert_eq(ground.get_cell_source_id(Vector2i(0, 0)), World.WATER_SOURCE, "corner is water")
	assert_eq(ground.get_cell_source_id(Vector2i(15, 10)), World.GROUND_SOURCE, "centre is ground")
	assert_true(w.is_ring(Vector2i(29, 5)), "right column is ring")
	assert_true(not w.is_ring(Vector2i(1, 1)), "inner cell not ring")
	w.queue_free()


func test_water_has_collision() -> void:
	var w := _make()
	var ground: TileMapLayer = w.get_node("Ground")
	var data := ground.get_cell_tile_data(Vector2i(0, 0))
	assert_eq(data.get_collision_polygons_count(0), 1, "water tile has a collision polygon")
	var grass := ground.get_cell_tile_data(Vector2i(15, 10))
	assert_eq(grass.get_collision_polygons_count(0), 0, "grass has none")
	w.queue_free()


func test_helpers() -> void:
	var w := _make()
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for i in 50:
		var c := w.random_interior_cell(rng)
		assert_true(not w.is_ring(c), "interior cell is not ring")
		var far := w.random_cell_away_from(w.cell_to_world(Vector2i(15, 10)), 6, rng)
		assert_true(far.distance_to(Vector2i(15, 10)) >= 6.0, "far cell is far")
	assert_eq(w.cell_to_world(Vector2i(0, 0)), Vector2(16, 16), "cell centre")
	assert_eq(w.size_px(), Vector2(960, 640), "size")
	var p := w.random_ring_position(rng)
	assert_true(w.is_ring(w.get_node("Ground").local_to_map(p)), "ring position is on ring")
	w.queue_free()
```

- [ ] **Step 2: Run to verify it fails**

Run: `godot --headless -s tests/run_tests.gd`
Expected: failure loading `world.tscn` / `World` not found.

- [ ] **Step 3: Write scenes/world.tscn**

```
[gd_scene load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/world.gd" id="1"]

[node name="World" type="Node2D"]
script = ExtResource("1")

[node name="Ground" type="TileMapLayer" parent="."]

[node name="Decor" type="TileMapLayer" parent="."]
```

- [ ] **Step 4: Write scripts/world.gd**

```gdscript
class_name World
extends Node2D
## Builds the TileSet in code and fills a fixed 30x20 map: water ring, grass, dirt patches, decor.

const WIDTH := 30
const HEIGHT := 20
const TILE := 32

const GROUND_SOURCE := 0
const WATER_SOURCE := 1
const DECOR_SOURCE := 2

const GROUND_PATH := "res://Assets/TileMap/Ground tiles sample.png"
const WATER_PATH := "res://Assets/TileMap/Water sample.png"
const DECOR_PATH := "res://Assets/TileMap/Decorations sample.png"

const GRASS := Vector2i(3, 5)
const DIRT := Vector2i(2, 2)
# Water ring tiles: the water is OUTSIDE, so the top row shows a pond's bottom shore, etc.
const WATER_TOP := Vector2i(2, 3)
const WATER_BOTTOM := Vector2i(2, 0)
const WATER_LEFT := Vector2i(3, 2)
const WATER_RIGHT := Vector2i(0, 2)
const WATER_TL := Vector2i(4, 0)
const WATER_TR := Vector2i(5, 0)
const WATER_BL := Vector2i(4, 1)
const WATER_BR := Vector2i(5, 1)
const DECOR_TILES: Array[Vector2i] = [
	Vector2i(1, 1), Vector2i(2, 1), Vector2i(3, 1), Vector2i(4, 1), Vector2i(3, 0), Vector2i(4, 0),
	Vector2i(3, 7), Vector2i(4, 7), Vector2i(0, 8), Vector2i(1, 8), Vector2i(2, 8), Vector2i(5, 0),
]
const DIRT_PATCHES: Array[Rect2i] = [
	Rect2i(4, 3, 5, 4), Rect2i(19, 4, 6, 3), Rect2i(8, 12, 4, 5), Rect2i(21, 13, 5, 4),
]
const DECOR_COUNT := 40
const MAP_SEED := 1234

@onready var ground: TileMapLayer = $Ground
@onready var decor: TileMapLayer = $Decor


static func build_tileset() -> TileSet:
	var ts := TileSet.new()
	ts.tile_size = Vector2i(TILE, TILE)
	ts.add_physics_layer()
	ts.set_physics_layer_collision_layer(0, 16)
	ts.set_physics_layer_collision_mask(0, 0)
	_add_source(ts, GROUND_SOURCE, GROUND_PATH, false)
	_add_source(ts, WATER_SOURCE, WATER_PATH, true)
	_add_source(ts, DECOR_SOURCE, DECOR_PATH, false)
	return ts


static func _add_source(ts: TileSet, id: int, path: String, solid: bool) -> void:
	var src := TileSetAtlasSource.new()
	src.texture = load(path)
	src.texture_region_size = Vector2i(TILE, TILE)
	var grid := src.get_atlas_grid_size()
	for x in grid.x:
		for y in grid.y:
			var c := Vector2i(x, y)
			src.create_tile(c)
			if solid:
				var data := src.get_tile_data(c, 0)
				data.add_collision_polygon(0)
				var h := TILE / 2.0
				data.set_collision_polygon_points(0, 0, PackedVector2Array([
					Vector2(-h, -h), Vector2(h, -h), Vector2(h, h), Vector2(-h, h),
				]))
	ts.add_source(src, id)


func build() -> void:
	var ts := build_tileset()
	ground.tile_set = ts
	decor.tile_set = ts
	ground.clear()
	decor.clear()
	for x in WIDTH:
		for y in HEIGHT:
			var c := Vector2i(x, y)
			if is_ring(c):
				ground.set_cell(c, WATER_SOURCE, _ring_tile(c))
			else:
				ground.set_cell(c, GROUND_SOURCE, GRASS)
	for patch in DIRT_PATCHES:
		for x in range(patch.position.x, patch.end.x):
			for y in range(patch.position.y, patch.end.y):
				ground.set_cell(Vector2i(x, y), GROUND_SOURCE, DIRT)
	var rng := RandomNumberGenerator.new()
	rng.seed = MAP_SEED
	for i in DECOR_COUNT:
		var c := random_interior_cell(rng)
		if _in_dirt(c):
			continue
		decor.set_cell(c, DECOR_SOURCE, DECOR_TILES[rng.randi_range(0, DECOR_TILES.size() - 1)])


func _ring_tile(c: Vector2i) -> Vector2i:
	var left := c.x == 0
	var right := c.x == WIDTH - 1
	var top := c.y == 0
	var bottom := c.y == HEIGHT - 1
	if top and left:
		return WATER_TL
	if top and right:
		return WATER_TR
	if bottom and left:
		return WATER_BL
	if bottom and right:
		return WATER_BR
	if top:
		return WATER_TOP
	if bottom:
		return WATER_BOTTOM
	if left:
		return WATER_LEFT
	return WATER_RIGHT


func _in_dirt(c: Vector2i) -> bool:
	for patch in DIRT_PATCHES:
		if patch.has_point(c):
			return true
	return false


func is_ring(c: Vector2i) -> bool:
	return c.x == 0 or c.y == 0 or c.x == WIDTH - 1 or c.y == HEIGHT - 1


func cell_to_world(c: Vector2i) -> Vector2:
	return ground.map_to_local(c)


func size_px() -> Vector2:
	return Vector2(WIDTH * TILE, HEIGHT * TILE)


func random_interior_cell(rng: RandomNumberGenerator) -> Vector2i:
	return Vector2i(rng.randi_range(1, WIDTH - 2), rng.randi_range(1, HEIGHT - 2))


func random_cell_away_from(pos: Vector2, min_tiles: int, rng: RandomNumberGenerator) -> Vector2i:
	var origin := ground.local_to_map(pos)
	var best := random_interior_cell(rng)
	for i in 100:
		var c := random_interior_cell(rng)
		if Vector2(c).distance_to(Vector2(origin)) >= float(min_tiles):
			return c
		if Vector2(c).distance_to(Vector2(origin)) > Vector2(best).distance_to(Vector2(origin)):
			best = c
	return best


func random_ring_position(rng: RandomNumberGenerator) -> Vector2:
	var c: Vector2i
	match rng.randi_range(0, 3):
		0:
			c = Vector2i(rng.randi_range(0, WIDTH - 1), 0)
		1:
			c = Vector2i(rng.randi_range(0, WIDTH - 1), HEIGHT - 1)
		2:
			c = Vector2i(0, rng.randi_range(0, HEIGHT - 1))
		_:
			c = Vector2i(WIDTH - 1, rng.randi_range(0, HEIGHT - 1))
	return cell_to_world(c)
```

- [ ] **Step 5: Run tests**

Run: `godot --headless -s tests/run_tests.gd`
Expected: all PASS.

- [ ] **Step 6: Commit**

```bash
git add scripts/world.gd scenes/world.tscn tests/test_world.gd && git commit -m "Add World with code-built TileSet and fixed map"
```

---

### Task 4: Player

**Files:**
- Create: `scripts/player.gd`, `scenes/player.tscn`, `tests/test_player.gd`

**Interfaces:**
- Consumes: `SpriteSheets.frog_frames()`, `SpriteSheets.direction_index()`, `SpriteSheets.DIRECTION_NAMES`.
- Produces: `Player` (CharacterBody2D). Signals `fired(origin: Vector2, direction: Vector2, damage: int)`, `health_changed(hp: int)`, `died()`. Members `hp`, `staff_tier`, `fire_cooldown`, `fire_damage`, `facing`, `facing_index`, `MAX_HP`. Methods `apply_movement(input: Vector2, delta: float)`, `can_fire() -> bool`, `try_fire() -> bool`, `set_staff_tier(tier: int)`, `take_damage(amount: int)`, `is_invulnerable() -> bool`.

- [ ] **Step 1: Write the failing test**

```gdscript
extends TestSuite


func _make() -> Player:
	var p: Player = load("res://scenes/player.tscn").instantiate()
	tree.root.add_child(p)
	p.set_physics_process(false)
	return p


func test_staff_tiers() -> void:
	var p := _make()
	assert_eq(p.staff_tier, 0, "starts unarmed")
	assert_true(not p.can_fire(), "cannot fire at tier 0")
	p.set_staff_tier(1)
	assert_approx(p.fire_cooldown, 0.5, "wood cooldown")
	assert_eq(p.fire_damage, 1, "wood damage")
	p.set_staff_tier(2)
	assert_approx(p.fire_cooldown, 0.35, "crystal cooldown")
	assert_eq(p.fire_damage, 2, "crystal damage")
	p.set_staff_tier(3)
	assert_approx(p.fire_cooldown, 0.2, "mighty cooldown")
	assert_eq(p.fire_damage, 3, "mighty damage")
	p.set_staff_tier(9)
	assert_eq(p.staff_tier, 3, "clamped high")
	p.set_staff_tier(-1)
	assert_eq(p.staff_tier, 0, "clamped low")
	p.queue_free()


func test_fire_and_cooldown() -> void:
	var p := _make()
	p.set_staff_tier(1)
	var got: Array = []
	p.fired.connect(func(o, d, dmg): got.append([o, d, dmg]))
	p.apply_movement(Vector2.RIGHT, 0.0)
	assert_true(p.try_fire(), "first shot fires")
	assert_eq(got.size(), 1, "one signal")
	assert_eq(got[0][1], Vector2.RIGHT, "fires along facing")
	assert_eq(got[0][2], 1, "damage 1")
	assert_true(not p.try_fire(), "second shot blocked by cooldown")
	p.apply_movement(Vector2.ZERO, 0.6)
	assert_true(p.can_fire(), "cooldown elapsed")
	p.queue_free()


func test_facing_and_animation() -> void:
	var p := _make()
	p.apply_movement(Vector2(-1, -1), 0.016)
	assert_eq(p.facing_index, 5, "up_left index")
	assert_eq(p.sprite.animation, "walk_up_left", "walk anim")
	p.apply_movement(Vector2.ZERO, 0.016)
	assert_eq(p.sprite.animation, "idle", "idle when still")
	assert_eq(p.facing_index, 5, "facing kept when idle")
	p.queue_free()


func test_damage_invulnerability_and_death() -> void:
	var p := _make()
	var hps: Array = []
	var died := [false]
	p.health_changed.connect(func(hp): hps.append(hp))
	p.died.connect(func(): died[0] = true)
	p.take_damage(1)
	assert_eq(p.hp, 2, "took one")
	assert_true(p.is_invulnerable(), "invulnerable after hit")
	p.take_damage(1)
	assert_eq(p.hp, 2, "ignored during invulnerability")
	p.apply_movement(Vector2.ZERO, 0.6)
	assert_true(not p.is_invulnerable(), "invulnerability over")
	p.take_damage(1)
	p.apply_movement(Vector2.ZERO, 0.6)
	p.take_damage(1)
	assert_eq(p.hp, 0, "dead")
	assert_true(died[0], "died emitted")
	assert_eq(hps, [2, 1, 0], "health_changed sequence")
	p.queue_free()
```

- [ ] **Step 2: Run to verify it fails**

Run: `godot --headless -s tests/run_tests.gd`
Expected: failure loading `player.tscn`.

- [ ] **Step 3: Write scenes/player.tscn**

```
[gd_scene load_steps=3 format=3]

[ext_resource type="Script" path="res://scripts/player.gd" id="1"]

[sub_resource type="CircleShape2D" id="shape"]
radius = 9.0

[node name="Player" type="CharacterBody2D"]
collision_layer = 1
collision_mask = 16
motion_mode = 1
script = ExtResource("1")

[node name="Sprite" type="AnimatedSprite2D" parent="."]
position = Vector2(0, -4)

[node name="Shape" type="CollisionShape2D" parent="."]
shape = SubResource("shape")
```

- [ ] **Step 4: Write scripts/player.gd**

```gdscript
class_name Player
extends CharacterBody2D
## The frog: 8-way movement, staff-tiered firing, hearts with invulnerability window.

signal fired(origin: Vector2, direction: Vector2, damage: int)
signal health_changed(hp: int)
signal died

const SPEED := 120.0
const MAX_HP := 3
const INVULN_TIME := 0.5
const MAX_TIER := 3
## tier -> [cooldown seconds, damage]
const STAFF_STATS := {
	1: [0.5, 1],
	2: [0.35, 2],
	3: [0.2, 3],
}

var hp := MAX_HP
var staff_tier := 0
var fire_cooldown := 0.0
var fire_damage := 0
var facing := Vector2.DOWN
var facing_index := 0
var _cooldown_left := 0.0
var _invuln_left := 0.0

@onready var sprite: AnimatedSprite2D = $Sprite


func _ready() -> void:
	sprite.sprite_frames = SpriteSheets.frog_frames()
	_play("idle")


func _physics_process(delta: float) -> void:
	var input := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	apply_movement(input, delta)
	if Input.is_action_pressed("fire"):
		try_fire()


func apply_movement(input: Vector2, delta: float) -> void:
	velocity = input * SPEED
	if input != Vector2.ZERO:
		facing = input.normalized()
		facing_index = SpriteSheets.direction_index(facing)
		_play("walk_" + SpriteSheets.DIRECTION_NAMES[facing_index])
	else:
		_play("idle")
	if is_inside_tree():
		move_and_slide()
	_cooldown_left = maxf(0.0, _cooldown_left - delta)
	_tick_invulnerability(delta)


func can_fire() -> bool:
	return hp > 0 and staff_tier > 0 and _cooldown_left <= 0.0


func try_fire() -> bool:
	if not can_fire():
		return false
	_cooldown_left = fire_cooldown
	fired.emit(global_position, facing, fire_damage)
	return true


func set_staff_tier(tier: int) -> void:
	staff_tier = clampi(tier, 0, MAX_TIER)
	if staff_tier == 0:
		fire_cooldown = 0.0
		fire_damage = 0
	else:
		fire_cooldown = STAFF_STATS[staff_tier][0]
		fire_damage = STAFF_STATS[staff_tier][1]


func take_damage(amount: int) -> void:
	if hp <= 0 or is_invulnerable():
		return
	hp = maxi(0, hp - amount)
	health_changed.emit(hp)
	if hp == 0:
		velocity = Vector2.ZERO
		set_physics_process(false)
		_play("idle")
		died.emit()
		return
	_invuln_left = INVULN_TIME


func is_invulnerable() -> bool:
	return _invuln_left > 0.0


func _tick_invulnerability(delta: float) -> void:
	if _invuln_left <= 0.0:
		return
	_invuln_left = maxf(0.0, _invuln_left - delta)
	var flicker := _invuln_left > 0.0 and fmod(_invuln_left, 0.1) < 0.05
	sprite.modulate.a = 0.35 if flicker else 1.0


func _play(anim: String) -> void:
	if sprite.animation == anim and sprite.is_playing():
		return
	if not sprite.sprite_frames.has_animation(anim):
		push_warning("Player: missing animation %s" % anim)
		anim = "idle"
	sprite.play(anim)
```

- [ ] **Step 5: Run tests**

Run: `godot --headless -s tests/run_tests.gd`
Expected: all PASS.

- [ ] **Step 6: Commit**

```bash
git add scripts/player.gd scenes/player.tscn tests/test_player.gd && git commit -m "Add Player with 8-way movement, staff tiers and health"
```

---

### Task 5: Fireball and Enemy

**Files:**
- Create: `scripts/fireball.gd`, `scenes/fireball.tscn`, `scripts/enemy.gd`, `scenes/enemy.tscn`, `tests/test_combat.gd`

**Interfaces:**
- Consumes: `SpriteSheets.enemy_frames()`, `Player.take_damage()`.
- Produces: `Fireball` (Area2D) with `setup(origin: Vector2, direction: Vector2, damage: int)`, `advance(delta)`, `SPEED`, `LIFETIME`. `Enemy` (CharacterBody2D) with `enum Kind {GRASSHOPPER, DRAGONFLY, LADYBUG}`, `STATS`, `@export kind`, `target: Node2D`, `hp`, `speed`, `score_value`, `apply_kind(k)`, `chase(delta)`, `take_damage(amount)`, signal `died(score_value: int)`.

- [ ] **Step 1: Write the failing test**

```gdscript
extends TestSuite


func _fireball() -> Fireball:
	var f: Fireball = load("res://scenes/fireball.tscn").instantiate()
	return f


func _enemy(kind: Enemy.Kind) -> Enemy:
	var e: Enemy = load("res://scenes/enemy.tscn").instantiate()
	e.kind = kind
	tree.root.add_child(e)
	e.set_physics_process(false)
	return e


func test_fireball_moves_and_expires() -> void:
	var f := _fireball()
	f.setup(Vector2(100, 100), Vector2.RIGHT, 2)
	tree.root.add_child(f)
	f.set_physics_process(false)
	f.advance(0.5)
	assert_eq(f.position, Vector2(100 + Fireball.SPEED * 0.5, 100), "moved right")
	assert_eq(f.damage, 2, "damage kept")
	f.advance(Fireball.LIFETIME)
	assert_true(f.is_queued_for_deletion(), "expired")


func test_fireball_zero_direction_is_freed() -> void:
	var f := _fireball()
	f.setup(Vector2.ZERO, Vector2.ZERO, 1)
	tree.root.add_child(f)
	assert_true(f.is_queued_for_deletion(), "freed on zero direction")


func test_enemy_kind_table() -> void:
	var g := _enemy(Enemy.Kind.GRASSHOPPER)
	assert_eq([g.speed, g.hp, g.score_value], [90.0, 1, 10], "grasshopper")
	var d := _enemy(Enemy.Kind.DRAGONFLY)
	assert_eq([d.speed, d.hp, d.score_value], [60.0, 2, 20], "dragonfly")
	var l := _enemy(Enemy.Kind.LADYBUG)
	assert_eq([l.speed, l.hp, l.score_value], [35.0, 4, 30], "ladybug")
	assert_eq(l.sprite.sprite_frames.get_frame_count("move"), 8, "ladybug anim frames")
	for e in [g, d, l]:
		e.queue_free()


func test_enemy_dies_after_expected_hits() -> void:
	var l := _enemy(Enemy.Kind.LADYBUG)
	var got := [-1]
	l.died.connect(func(v): got[0] = v)
	l.take_damage(2)
	assert_eq(l.hp, 2, "half health")
	assert_true(not l.is_queued_for_deletion(), "still alive")
	l.take_damage(2)
	assert_eq(got[0], 30, "died with score")
	assert_true(l.is_queued_for_deletion(), "freed")


func test_enemy_chases_target() -> void:
	var e := _enemy(Enemy.Kind.GRASSHOPPER)
	var t := Node2D.new()
	t.position = Vector2(200, 0)
	tree.root.add_child(t)
	e.position = Vector2.ZERO
	e.target = t
	e.chase(0.1)
	assert_true(e.position.x > 0.0, "moved toward target")
	assert_true(e.sprite.flip_h, "flipped when moving right")
	e.queue_free()
	t.queue_free()
```

- [ ] **Step 2: Run to verify it fails**

Run: `godot --headless -s tests/run_tests.gd`
Expected: failures loading the two scenes.

- [ ] **Step 3: Write scenes/fireball.tscn**

```
[gd_scene load_steps=4 format=3]

[ext_resource type="Script" path="res://scripts/fireball.gd" id="1"]
[ext_resource type="Texture2D" path="res://Assets/Staff/fireball.png" id="2"]

[sub_resource type="CircleShape2D" id="shape"]
radius = 6.0

[node name="Fireball" type="Area2D"]
collision_layer = 4
collision_mask = 18
script = ExtResource("1")

[node name="Sprite" type="Sprite2D" parent="."]
texture = ExtResource("2")

[node name="Shape" type="CollisionShape2D" parent="."]
shape = SubResource("shape")
```

- [ ] **Step 4: Write scripts/fireball.gd**

```gdscript
class_name Fireball
extends Area2D
## Straight-line projectile. Damages the first enemy it touches, dies on world tiles or after LIFETIME.

const SPEED := 260.0
const LIFETIME := 2.0

var direction := Vector2.ZERO
var damage := 1
var _age := 0.0


func setup(origin: Vector2, dir: Vector2, dmg: int) -> void:
	position = origin
	direction = dir.normalized()
	damage = dmg
	rotation = direction.angle()


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	if direction == Vector2.ZERO:
		queue_free()


func _physics_process(delta: float) -> void:
	advance(delta)


func advance(delta: float) -> void:
	position += direction * SPEED * delta
	_age += delta
	if _age >= LIFETIME:
		queue_free()


func _on_body_entered(body: Node) -> void:
	if body is Enemy:
		body.take_damage(damage)
	queue_free()
```

- [ ] **Step 5: Write scenes/enemy.tscn**

```
[gd_scene load_steps=4 format=3]

[ext_resource type="Script" path="res://scripts/enemy.gd" id="1"]

[sub_resource type="CircleShape2D" id="body_shape"]
radius = 8.0

[sub_resource type="CircleShape2D" id="hurt_shape"]
radius = 10.0

[node name="Enemy" type="CharacterBody2D"]
collision_layer = 2
collision_mask = 0
motion_mode = 1
script = ExtResource("1")

[node name="Sprite" type="AnimatedSprite2D" parent="."]

[node name="Shape" type="CollisionShape2D" parent="."]
shape = SubResource("body_shape")

[node name="Hurtbox" type="Area2D" parent="."]
collision_layer = 0
collision_mask = 1

[node name="Shape" type="CollisionShape2D" parent="Hurtbox"]
shape = SubResource("hurt_shape")
```

- [ ] **Step 6: Write scripts/enemy.gd**

```gdscript
class_name Enemy
extends CharacterBody2D
## An insect that chases its target and damages the player on contact.

signal died(score_value: int)

enum Kind { GRASSHOPPER, DRAGONFLY, LADYBUG }

const STATS := {
	Kind.GRASSHOPPER: {"speed": 90.0, "hp": 1, "score": 10, "row": 0, "frames": 9, "fps": 12.0},
	Kind.DRAGONFLY: {"speed": 60.0, "hp": 2, "score": 20, "row": 2, "frames": 2, "fps": 8.0},
	Kind.LADYBUG: {"speed": 35.0, "hp": 4, "score": 30, "row": 7, "frames": 8, "fps": 8.0},
}
const CONTACT_DAMAGE := 1
const CONTACT_INTERVAL := 0.5

@export var kind: Kind = Kind.GRASSHOPPER

var target: Node2D
var hp := 1
var speed := 0.0
var score_value := 0
var _contact_left := 0.0

@onready var sprite: AnimatedSprite2D = $Sprite
@onready var hurtbox: Area2D = $Hurtbox


func _ready() -> void:
	apply_kind(kind)
	sprite.play("move")


func apply_kind(k: Kind) -> void:
	kind = k
	var s: Dictionary = STATS[k]
	hp = s.hp
	speed = s.speed
	score_value = s.score
	sprite.sprite_frames = SpriteSheets.enemy_frames(s.row, s.frames, s.fps)


func _physics_process(delta: float) -> void:
	if is_instance_valid(target):
		chase(delta)
	_contact_left = maxf(0.0, _contact_left - delta)
	if _contact_left <= 0.0:
		for body in hurtbox.get_overlapping_bodies():
			if body is Player:
				body.take_damage(CONTACT_DAMAGE)
				_contact_left = CONTACT_INTERVAL
				break


func chase(delta: float) -> void:
	var dir := (target.global_position - global_position).normalized()
	velocity = dir * speed
	# Enemy art faces left by default.
	if absf(velocity.x) > 0.01:
		sprite.flip_h = velocity.x > 0.0
	if is_inside_tree():
		move_and_slide()
	else:
		position += velocity * delta


func take_damage(amount: int) -> void:
	if hp <= 0:
		return
	hp -= amount
	if hp <= 0:
		died.emit(score_value)
		queue_free()
```

- [ ] **Step 7: Run tests**

Run: `godot --headless -s tests/run_tests.gd`
Expected: all PASS. Note: `move_and_slide` moves by `velocity * physics_delta`, independent of the `delta` argument; the chase test only asserts direction.

- [ ] **Step 8: Commit**

```bash
git add scripts/fireball.gd scenes/fireball.tscn scripts/enemy.gd scenes/enemy.tscn tests/test_combat.gd && git commit -m "Add Fireball projectile and Enemy kinds"
```

---

### Task 6: StaffPickup and Spawner

**Files:**
- Create: `scripts/staff_pickup.gd`, `scenes/staff_pickup.tscn`, `scripts/spawner.gd`, `tests/test_spawner.gd`

**Interfaces:**
- Consumes: `World.random_ring_position(rng)`, `Enemy.Kind`.
- Produces: `StaffPickup` (Area2D) with `@export tier`, `ICONS`, signal `collected(tier: int)`. `Spawner` (Node) with `world: World`, `interval`, `start()`, `stop()`, `next_interval(current) -> float` (static), `pick_kind(roll: float) -> Enemy.Kind` (static), signal `spawn_requested(kind: Enemy.Kind, position: Vector2)`.

- [ ] **Step 1: Write the failing test**

```gdscript
extends TestSuite


func test_interval_decays_to_floor() -> void:
	assert_approx(Spawner.next_interval(2.0), 1.95, "first decay")
	assert_approx(Spawner.next_interval(0.62), 0.6, "clamped to floor")
	assert_approx(Spawner.next_interval(0.6), 0.6, "stays at floor")


func test_kind_weights() -> void:
	assert_eq(Spawner.pick_kind(0.0), Enemy.Kind.GRASSHOPPER, "0")
	assert_eq(Spawner.pick_kind(59.9), Enemy.Kind.GRASSHOPPER, "59.9")
	assert_eq(Spawner.pick_kind(60.0), Enemy.Kind.DRAGONFLY, "60")
	assert_eq(Spawner.pick_kind(89.9), Enemy.Kind.DRAGONFLY, "89.9")
	assert_eq(Spawner.pick_kind(90.0), Enemy.Kind.LADYBUG, "90")
	assert_eq(Spawner.pick_kind(99.9), Enemy.Kind.LADYBUG, "99.9")


func test_timeout_emits_and_reschedules() -> void:
	var w: World = load("res://scenes/world.tscn").instantiate()
	tree.root.add_child(w)
	w.build()
	var s := Spawner.new()
	s.world = w
	tree.root.add_child(s)
	var got: Array = []
	s.spawn_requested.connect(func(k, p): got.append([k, p]))
	s.start()
	s._on_timeout()
	assert_eq(got.size(), 1, "one spawn")
	assert_true(w.is_ring(w.ground.local_to_map(got[0][1])), "spawned on ring")
	assert_approx(s.interval, 1.95, "interval decayed")
	s.stop()
	s.queue_free()
	w.queue_free()


func test_staff_pickup_icon() -> void:
	var p: StaffPickup = load("res://scenes/staff_pickup.tscn").instantiate()
	p.tier = 2
	tree.root.add_child(p)
	assert_eq(p.get_node("Sprite").texture.resource_path, StaffPickup.ICONS[2], "crystal icon")
	p.queue_free()
```

- [ ] **Step 2: Run to verify it fails**

Run: `godot --headless -s tests/run_tests.gd`
Expected: `Spawner`/`StaffPickup` not found.

- [ ] **Step 3: Write scenes/staff_pickup.tscn**

```
[gd_scene load_steps=3 format=3]

[ext_resource type="Script" path="res://scripts/staff_pickup.gd" id="1"]

[sub_resource type="CircleShape2D" id="shape"]
radius = 10.0

[node name="StaffPickup" type="Area2D"]
collision_layer = 8
collision_mask = 1
script = ExtResource("1")

[node name="Sprite" type="Sprite2D" parent="."]

[node name="Shape" type="CollisionShape2D" parent="."]
shape = SubResource("shape")
```

- [ ] **Step 4: Write scripts/staff_pickup.gd**

```gdscript
class_name StaffPickup
extends Area2D
## A staff lying on the ground. Touching it grants that tier.

signal collected(tier: int)

const ICONS := {
	1: "res://Assets/Staff/staff_wood.png",
	2: "res://Assets/Staff/staff_crystal.png",
	3: "res://Assets/Staff/staff_mighty.png",
}

@export_range(1, 3) var tier := 1

var _taken := false


func _ready() -> void:
	$Sprite.texture = load(ICONS[clampi(tier, 1, 3)])
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node) -> void:
	if _taken or not body is Player:
		return
	_taken = true
	collected.emit(tier)
	queue_free()
```

- [ ] **Step 5: Write scripts/spawner.gd**

```gdscript
class_name Spawner
extends Node
## Emits spawn requests on a shrinking interval at random ring positions.

signal spawn_requested(kind: Enemy.Kind, position: Vector2)

const START_INTERVAL := 2.0
const INTERVAL_STEP := 0.05
const MIN_INTERVAL := 0.6

var world: World
var interval := START_INTERVAL
var rng := RandomNumberGenerator.new()
var _timer: Timer


func _ready() -> void:
	_timer = Timer.new()
	_timer.one_shot = true
	_timer.timeout.connect(_on_timeout)
	add_child(_timer)


static func next_interval(current: float) -> float:
	return maxf(MIN_INTERVAL, current - INTERVAL_STEP)


## roll is in [0, 100): 60% grasshopper, 30% dragonfly, 10% ladybug.
static func pick_kind(roll: float) -> Enemy.Kind:
	if roll < 60.0:
		return Enemy.Kind.GRASSHOPPER
	if roll < 90.0:
		return Enemy.Kind.DRAGONFLY
	return Enemy.Kind.LADYBUG


func start() -> void:
	interval = START_INTERVAL
	_timer.start(interval)


func stop() -> void:
	_timer.stop()


func _on_timeout() -> void:
	spawn_requested.emit(pick_kind(rng.randf() * 100.0), world.random_ring_position(rng))
	interval = next_interval(interval)
	_timer.start(interval)
```

- [ ] **Step 6: Run tests**

Run: `godot --headless -s tests/run_tests.gd`
Expected: all PASS.

- [ ] **Step 7: Commit**

```bash
git add scripts/staff_pickup.gd scenes/staff_pickup.tscn scripts/spawner.gd tests/test_spawner.gd && git commit -m "Add StaffPickup and Spawner"
```

---

### Task 7: HUD, Main scene and wiring

**Files:**
- Create: `scripts/hud.gd`, `scenes/hud.tscn`, `scripts/main.gd`, `scenes/main.tscn`, `tests/test_main.gd`

**Interfaces:**
- Consumes: everything above.
- Produces: `HUD` (CanvasLayer) with `set_hearts(hp)`, `set_score(v)`, `set_staff(tier)`, `show_game_over()`, static `make_heart_texture()`. `Main` with `score`, `game_over`, and handlers `_on_player_fired`, `_spawn_enemy`, `_on_enemy_died`, `_spawn_staff`, `_on_staff_collected`, `_on_player_died`.

- [ ] **Step 1: Write the failing test**

```gdscript
extends TestSuite


func _make() -> Node2D:
	var m: Node2D = load("res://scenes/main.tscn").instantiate()
	tree.root.add_child(m)
	return m


func test_main_boots_with_world_player_and_wood_staff() -> void:
	var m := _make()
	var ground: TileMapLayer = m.get_node("World/Ground")
	assert_eq(ground.get_used_cells().size(), 600, "world built")
	var player: Player = m.get_node("Player")
	assert_true(not m.get_node("World").is_ring(ground.local_to_map(player.position)), "player inside")
	assert_eq(m.get_node("Pickups").get_child_count(), 1, "wood staff placed")
	assert_eq(m.get_node("Pickups").get_child(0).tier, 1, "it is wood")
	m.queue_free()


func test_fired_signal_spawns_fireball() -> void:
	var m := _make()
	var player: Player = m.get_node("Player")
	player.set_staff_tier(1)
	player.try_fire()
	assert_eq(m.get_node("Projectiles").get_child_count(), 1, "fireball spawned")
	m.queue_free()


func test_enemy_death_adds_score_and_staff_progression() -> void:
	var m := _make()
	m._spawn_enemy(Enemy.Kind.LADYBUG, Vector2(64, 64))
	var e: Enemy = m.get_node("Enemies").get_child(0)
	e.take_damage(99)
	assert_eq(m.score, 30, "score added")
	assert_eq(m.get_node("HUD/Score").text, "Score: 30", "hud score")
	m._on_staff_collected(1)
	assert_eq(m.get_node("Player").staff_tier, 1, "player armed")
	assert_eq(m._next_staff_tier, 2, "crystal scheduled")
	m._on_staff_collected(3)
	assert_eq(m._next_staff_tier, 0, "nothing after mighty")
	m.queue_free()


func test_player_death_sets_game_over() -> void:
	var m := _make()
	var player: Player = m.get_node("Player")
	for i in 3:
		player.take_damage(1)
		player.apply_movement(Vector2.ZERO, 1.0)
	assert_true(m.game_over, "game over flag")
	assert_true(m.get_node("HUD/GameOver").visible, "game over label shown")
	m.queue_free()


func test_heart_texture() -> void:
	var t := HUD.make_heart_texture()
	assert_eq(t.get_size(), Vector2(7, 7), "7x7 heart")
```

- [ ] **Step 2: Run to verify it fails**

Run: `godot --headless -s tests/run_tests.gd`
Expected: failure loading `main.tscn`.

- [ ] **Step 3: Write scenes/hud.tscn**

```
[gd_scene load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/hud.gd" id="1"]

[node name="HUD" type="CanvasLayer"]
script = ExtResource("1")

[node name="Hearts" type="HBoxContainer" parent="."]
offset_left = 8.0
offset_top = 8.0
offset_right = 80.0
offset_bottom = 29.0

[node name="Score" type="Label" parent="."]
anchors_preset = 1
anchor_left = 1.0
anchor_right = 1.0
offset_left = -160.0
offset_top = 8.0
offset_right = -8.0
offset_bottom = 31.0
grow_horizontal = 0
horizontal_alignment = 2
text = "Score: 0"

[node name="StaffIcon" type="TextureRect" parent="."]
anchors_preset = 2
anchor_top = 1.0
anchor_bottom = 1.0
offset_left = 8.0
offset_top = -40.0
offset_right = 40.0
offset_bottom = -8.0
grow_vertical = 0
expand_mode = 1
stretch_mode = 5

[node name="GameOver" type="Label" parent="."]
visible = false
anchors_preset = 8
anchor_left = 0.5
anchor_top = 0.5
anchor_right = 0.5
anchor_bottom = 0.5
offset_left = -120.0
offset_top = -12.0
offset_right = 120.0
offset_bottom = 12.0
grow_horizontal = 2
grow_vertical = 2
text = "GAME OVER - press R"
horizontal_alignment = 1
vertical_alignment = 1
```

- [ ] **Step 4: Write scripts/hud.gd**

```gdscript
class_name HUD
extends CanvasLayer
## Hearts, score, current staff icon and the game-over banner.

const HEART_ROWS := ["0110110", "1111111", "1111111", "0111110", "0011100", "0001000", "0000000"]
const HEART_SIZE := 21
const HEART_COLOR := Color(0.9, 0.15, 0.2)
const EMPTY_HEART := Color(0.25, 0.25, 0.25, 0.6)

@onready var hearts: HBoxContainer = $Hearts
@onready var score_label: Label = $Score
@onready var staff_icon: TextureRect = $StaffIcon
@onready var game_over_label: Label = $GameOver


static func make_heart_texture() -> ImageTexture:
	var img := Image.create(7, 7, false, Image.FORMAT_RGBA8)
	for y in 7:
		for x in 7:
			img.set_pixel(x, y, Color.WHITE if HEART_ROWS[y][x] == "1" else Color(0, 0, 0, 0))
	return ImageTexture.create_from_image(img)


func _ready() -> void:
	var tex := make_heart_texture()
	for i in Player.MAX_HP:
		var tr := TextureRect.new()
		tr.texture = tex
		tr.custom_minimum_size = Vector2(HEART_SIZE, HEART_SIZE)
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.stretch_mode = TextureRect.STRETCH_SCALE
		tr.modulate = HEART_COLOR
		hearts.add_child(tr)
	set_hearts(Player.MAX_HP)
	set_score(0)
	set_staff(0)
	game_over_label.visible = false


func set_hearts(hp: int) -> void:
	for i in hearts.get_child_count():
		hearts.get_child(i).modulate = HEART_COLOR if i < hp else EMPTY_HEART


func set_score(value: int) -> void:
	score_label.text = "Score: %d" % value


func set_staff(tier: int) -> void:
	staff_icon.texture = load(StaffPickup.ICONS[tier]) if StaffPickup.ICONS.has(tier) else null


func show_game_over() -> void:
	game_over_label.visible = true
```

- [ ] **Step 5: Write scenes/main.tscn**

```
[gd_scene load_steps=5 format=3]

[ext_resource type="Script" path="res://scripts/main.gd" id="1"]
[ext_resource type="PackedScene" path="res://scenes/world.tscn" id="2"]
[ext_resource type="PackedScene" path="res://scenes/player.tscn" id="3"]
[ext_resource type="PackedScene" path="res://scenes/hud.tscn" id="4"]

[node name="Main" type="Node2D"]
script = ExtResource("1")

[node name="World" parent="." instance=ExtResource("2")]

[node name="Pickups" type="Node2D" parent="."]

[node name="Enemies" type="Node2D" parent="."]

[node name="Projectiles" type="Node2D" parent="."]

[node name="Player" parent="." instance=ExtResource("3")]

[node name="Camera" type="Camera2D" parent="Player"]
position_smoothing_enabled = true
position_smoothing_speed = 8.0

[node name="Spawner" type="Node" parent="."]
script = ExtResource("5")

[node name="HUD" parent="." instance=ExtResource("4")]
```

Note: add `[ext_resource type="Script" path="res://scripts/spawner.gd" id="5"]` under the other ext_resources and bump `load_steps` to 6.

- [ ] **Step 6: Write scripts/main.gd**

```gdscript
extends Node2D
## Wires World, Player, Spawner and HUD together; owns score, staff progression and game over.

const FIREBALL_SCENE := preload("res://scenes/fireball.tscn")
const ENEMY_SCENE := preload("res://scenes/enemy.tscn")
const STAFF_SCENE := preload("res://scenes/staff_pickup.tscn")
const STAFF_RESPAWN_DELAY := 5.0
const STAFF_MIN_DISTANCE_TILES := 6

var score := 0
var game_over := false
var rng := RandomNumberGenerator.new()
var _next_staff_tier := 0
var _staff_delay := 0.0

@onready var world: World = $World
@onready var player: Player = $Player
@onready var enemies: Node2D = $Enemies
@onready var projectiles: Node2D = $Projectiles
@onready var pickups: Node2D = $Pickups
@onready var spawner: Spawner = $Spawner
@onready var hud: HUD = $HUD
@onready var camera: Camera2D = $Player/Camera


func _ready() -> void:
	world.build()
	spawner.world = world
	var centre := Vector2i(World.WIDTH / 2, World.HEIGHT / 2)
	player.position = world.cell_to_world(centre)
	camera.limit_left = 0
	camera.limit_top = 0
	camera.limit_right = int(world.size_px().x)
	camera.limit_bottom = int(world.size_px().y)
	player.fired.connect(_on_player_fired)
	player.health_changed.connect(hud.set_hearts)
	player.died.connect(_on_player_died)
	spawner.spawn_requested.connect(_spawn_enemy)
	hud.set_hearts(player.hp)
	hud.set_score(score)
	hud.set_staff(player.staff_tier)
	_spawn_staff(1, world.cell_to_world(centre + Vector2i(3, 0)))
	spawner.start()


func _process(delta: float) -> void:
	if game_over or _next_staff_tier == 0:
		return
	_staff_delay -= delta
	if _staff_delay <= 0.0:
		var cell := world.random_cell_away_from(player.position, STAFF_MIN_DISTANCE_TILES, rng)
		_spawn_staff(_next_staff_tier, world.cell_to_world(cell))
		_next_staff_tier = 0


func _unhandled_input(event: InputEvent) -> void:
	if game_over and event.is_action_pressed("restart"):
		get_tree().reload_current_scene()


func _on_player_fired(origin: Vector2, direction: Vector2, damage: int) -> void:
	var f: Fireball = FIREBALL_SCENE.instantiate()
	f.setup(origin, direction, damage)
	projectiles.add_child(f)


func _spawn_enemy(kind: Enemy.Kind, pos: Vector2) -> void:
	var e: Enemy = ENEMY_SCENE.instantiate()
	e.kind = kind
	e.position = pos
	e.target = player
	e.died.connect(_on_enemy_died)
	enemies.add_child(e)


func _on_enemy_died(value: int) -> void:
	score += value
	hud.set_score(score)


func _spawn_staff(tier: int, pos: Vector2) -> void:
	var s: StaffPickup = STAFF_SCENE.instantiate()
	s.tier = tier
	s.position = pos
	s.collected.connect(_on_staff_collected)
	pickups.add_child(s)


func _on_staff_collected(tier: int) -> void:
	player.set_staff_tier(tier)
	hud.set_staff(tier)
	if tier < Player.MAX_TIER:
		_next_staff_tier = tier + 1
		_staff_delay = STAFF_RESPAWN_DELAY
	else:
		_next_staff_tier = 0


func _on_player_died() -> void:
	game_over = true
	spawner.stop()
	hud.show_game_over()
	for e in enemies.get_children():
		e.set_physics_process(false)
```

- [ ] **Step 7: Run tests and import**

Run: `godot --headless --import --path . 2>&1 | grep -iE "error|warn"; godot --headless -s tests/run_tests.gd`
Expected: no errors; all PASS.

- [ ] **Step 8: Run the game briefly headless to catch runtime errors**

Run: `timeout 5 godot --headless --path . 2>&1 | grep -iE "error|script" ; echo done`
Expected: no script errors (the process is killed by timeout, which is fine).

- [ ] **Step 9: Commit**

```bash
git add -A && git commit -m "Add HUD and Main scene wiring; game is playable"
```

---

### Task 8: README and final verification

**Files:**
- Create: `README.md`

- [ ] **Step 1: Write README.md**

```markdown
# Frog Shooter

A small top-down shooter made in Godot 4.7 from the supplied pixel-art assets.

## Play
Open the folder in Godot 4.7 and press F5, or run `godot --path .`

- Move: WASD / arrow keys (8 directions)
- Fire: Space or left mouse (needs a staff)
- Restart after game over: R

Pick up the wooden staff to start shooting. Crystal and mighty staffs appear
later and raise fire rate and damage. Grasshoppers are fast and fragile,
dragonflies are medium, ladybugs are slow and tough.

## Tests
`godot --headless -s tests/run_tests.gd`

## Layout
- `Assets/` supplied art
- `scenes/`, `scripts/` one pair per game object
- `tests/` headless suites, `tests/run_tests.gd` is the runner
```

- [ ] **Step 2: Full verification**

Run: `godot --headless --import --path . 2>&1 | grep -i error; godot --headless -s tests/run_tests.gd | tail -3`
Expected: no errors; `N tests, 0 failed`.

- [ ] **Step 3: Commit and push**

```bash
git add README.md && git commit -m "Add README" && git push
```
