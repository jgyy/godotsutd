class_name StaffPickup
extends Area2D
## A staff lying on the ground. Touching it grants that tier.

signal collected(tier: int)

const ICONS := {
	1: "res://Assets/Staff/staff_wood.png",
	2: "res://Assets/Staff/staff_crystal.png",
	3: "res://Assets/Staff/staff_mighty.png",
}

@export_range(1, 3) var tier := 1

var _taken := false


func _ready() -> void:
	$Sprite.texture = load(ICONS[clampi(tier, 1, 3)])
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node) -> void:
	if _taken or not body is Player:
		return
	_taken = true
	collected.emit(tier)
	queue_free()
