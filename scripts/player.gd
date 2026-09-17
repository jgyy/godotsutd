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
## Container whose children are Enemy nodes; auto-fire aims at the nearest one.
var enemies: Node
var _cooldown_left := 0.0
var _invuln_left := 0.0

@onready var sprite: AnimatedSprite2D = $Sprite


func _ready() -> void:
	sprite.sprite_frames = SpriteSheets.frog_frames()
	_play("idle")


func _physics_process(delta: float) -> void:
	var input := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	apply_movement(input, delta)
	auto_fire()


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


## Fires along facing (kept for tests and manual use).
func try_fire() -> bool:
	return try_fire_toward(facing)


func try_fire_toward(direction: Vector2) -> bool:
	if not can_fire() or direction == Vector2.ZERO:
		return false
	_cooldown_left = fire_cooldown
	fired.emit(global_position, direction.normalized(), fire_damage)
	return true


func nearest_enemy() -> Node2D:
	if enemies == null:
		return null
	var best: Node2D = null
	var best_d := INF
	for e in enemies.get_children():
		if not e is Node2D or e.is_queued_for_deletion():
			continue
		var d: float = global_position.distance_squared_to(e.global_position)
		if d < best_d:
			best_d = d
			best = e
	return best


## Shoots at the nearest enemy when armed and off cooldown. Returns true if a shot fired.
func auto_fire() -> bool:
	if not can_fire():
		return false
	var target := nearest_enemy()
	if target == null:
		return false
	return try_fire_toward(target.global_position - global_position)


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
