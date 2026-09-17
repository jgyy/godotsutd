class_name HUD
extends CanvasLayer
## Hearts, score, current staff icon and the game-over banner.

const HEART_ROWS := ["0110110", "1111111", "1111111", "0111110", "0011100", "0001000", "0000000"]
const HEART_SIZE := 21
const HEART_COLOR := Color(0.9, 0.15, 0.2)
const EMPTY_HEART := Color(0.25, 0.25, 0.25, 0.6)

@onready var hearts: HBoxContainer = $Hearts
@onready var score_label: Label = $Score
@onready var staff_icon: TextureRect = $StaffIcon
@onready var game_over_label: Label = $GameOver


static func make_heart_texture() -> ImageTexture:
	var img := Image.create(7, 7, false, Image.FORMAT_RGBA8)
	for y in 7:
		for x in 7:
			img.set_pixel(x, y, Color.WHITE if HEART_ROWS[y][x] == "1" else Color(0, 0, 0, 0))
	return ImageTexture.create_from_image(img)


func _ready() -> void:
	var tex := make_heart_texture()
	for i in Player.MAX_HP:
		var tr := TextureRect.new()
		tr.texture = tex
		tr.custom_minimum_size = Vector2(HEART_SIZE, HEART_SIZE)
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.stretch_mode = TextureRect.STRETCH_SCALE
		tr.modulate = HEART_COLOR
		hearts.add_child(tr)
	set_hearts(Player.MAX_HP)
	set_score(0)
	set_staff(0)
	game_over_label.visible = false


func set_hearts(hp: int) -> void:
	for i in hearts.get_child_count():
		hearts.get_child(i).modulate = HEART_COLOR if i < hp else EMPTY_HEART


func set_score(value: int) -> void:
	score_label.text = "Score: %d" % value


func set_staff(tier: int) -> void:
	staff_icon.texture = load(StaffPickup.ICONS[tier]) if StaffPickup.ICONS.has(tier) else null


func show_game_over() -> void:
	game_over_label.visible = true
