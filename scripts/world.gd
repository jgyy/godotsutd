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
	ts.add_source(src, id)  # must precede create_tile so TileData gets the physics layer
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
