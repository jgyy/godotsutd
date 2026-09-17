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
