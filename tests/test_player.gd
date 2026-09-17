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
	assert_eq(p.sprite.animation, &"walk_up_left", "walk anim")
	p.apply_movement(Vector2.ZERO, 0.016)
	assert_eq(p.sprite.animation, &"idle", "idle when still")
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
