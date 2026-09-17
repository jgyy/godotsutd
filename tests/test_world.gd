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
		assert_true(Vector2(far).distance_to(Vector2(15, 10)) >= 6.0, "far cell is far")
	assert_eq(w.cell_to_world(Vector2i(0, 0)), Vector2(16, 16), "cell centre")
	assert_eq(w.size_px(), Vector2(960, 640), "size")
	var p := w.random_ring_position(rng)
	assert_true(w.is_ring(w.get_node("Ground").local_to_map(p)), "ring position is on ring")
	w.queue_free()
