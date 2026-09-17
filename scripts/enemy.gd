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
