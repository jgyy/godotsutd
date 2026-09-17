class_name Fireball
extends Area2D
## Straight-line projectile. Damages the first enemy it touches, dies on world tiles or after LIFETIME.

const SPEED := 260.0
const LIFETIME := 2.0

var direction := Vector2.ZERO
var damage := 1
var _age := 0.0


func setup(origin: Vector2, dir: Vector2, dmg: int) -> void:
	position = origin
	direction = dir.normalized()
	damage = dmg
	rotation = direction.angle()


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	if direction == Vector2.ZERO:
		queue_free()


func _physics_process(delta: float) -> void:
	advance(delta)


func advance(delta: float) -> void:
	position += direction * SPEED * delta
	_age += delta
	if _age >= LIFETIME:
		queue_free()


func _on_body_entered(body: Node) -> void:
	if body is Enemy:
		body.take_damage(damage)
	queue_free()
