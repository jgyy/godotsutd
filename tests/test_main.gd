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
