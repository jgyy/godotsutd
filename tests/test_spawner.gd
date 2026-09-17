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
