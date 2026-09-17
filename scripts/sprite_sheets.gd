class_name SpriteSheets
extends RefCounted
## Builds SpriteFrames from the 32px atlases and maps vectors to 8-way facing.

const CELL := 32
const DIRECTION_NAMES: Array[String] = [
	"down", "down_right", "right", "up_right", "up", "up_left", "left", "down_left",
]
const FROG_IDLE := "res://Assets/Frog/Frog_Idle.png"
const FROG_WALK := "res://Assets/Frog/Frog_Walk.png"
const ENEMIES := "res://Assets/Enemies.png"


static func direction_index(v: Vector2) -> int:
	# angle(): right = 0, down = +90deg. Rows: down=0 then clockwise-on-screen.
	var step := roundi(v.angle() / (PI / 4.0))
	return posmod(2 - step, 8)


static func cell(texture: Texture2D, col: int, row: int) -> AtlasTexture:
	var at := AtlasTexture.new()
	at.atlas = texture
	at.region = Rect2(col * CELL, row * CELL, CELL, CELL)
	return at


static func add_row(frames: SpriteFrames, anim: String, texture: Texture2D, row: int, count: int, fps: float) -> void:
	if not frames.has_animation(anim):
		frames.add_animation(anim)
	frames.set_animation_speed(anim, fps)
	frames.set_animation_loop(anim, true)
	for c in count:
		frames.add_frame(anim, cell(texture, c, row))


static func frog_frames() -> SpriteFrames:
	var frames := SpriteFrames.new()
	frames.remove_animation("default")
	add_row(frames, "idle", load(FROG_IDLE), 0, 5, 6.0)
	var walk: Texture2D = load(FROG_WALK)
	for i in DIRECTION_NAMES.size():
		add_row(frames, "walk_" + DIRECTION_NAMES[i], walk, i, 4, 8.0)
	return frames


static func enemy_frames(row: int, count: int, fps: float) -> SpriteFrames:
	var frames := SpriteFrames.new()
	frames.remove_animation("default")
	add_row(frames, "move", load(ENEMIES), row, count, fps)
	return frames
