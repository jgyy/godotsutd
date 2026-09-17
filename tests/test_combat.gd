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
