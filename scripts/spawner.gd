class_name Spawner
extends Node
## Emits spawn requests on a shrinking interval at random ring positions.

signal spawn_requested(kind: Enemy.Kind, position: Vector2)

const START_INTERVAL := 2.0
const INTERVAL_STEP := 0.05
const MIN_INTERVAL := 0.6

var world: World
var interval := START_INTERVAL
var rng := RandomNumberGenerator.new()
var _timer: Timer


func _ready() -> void:
	_timer = Timer.new()
	_timer.one_shot = true
	_timer.timeout.connect(_on_timeout)
	add_child(_timer)


static func next_interval(current: float) -> float:
	return maxf(MIN_INTERVAL, current - INTERVAL_STEP)


## roll is in [0, 100): 60% grasshopper, 30% dragonfly, 10% ladybug.
static func pick_kind(roll: float) -> Enemy.Kind:
	if roll < 60.0:
		return Enemy.Kind.GRASSHOPPER
	if roll < 90.0:
		return Enemy.Kind.DRAGONFLY
	return Enemy.Kind.LADYBUG


func start() -> void:
	interval = START_INTERVAL
	_timer.start(interval)


func stop() -> void:
	_timer.stop()


func _on_timeout() -> void:
	spawn_requested.emit(pick_kind(rng.randf() * 100.0), world.random_ring_position(rng))
	interval = next_interval(interval)
	_timer.start(interval)
