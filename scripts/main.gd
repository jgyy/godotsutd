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
