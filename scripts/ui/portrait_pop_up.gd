class_name PortraitPopup
extends Control

enum PopupPosition { LEFT, CENTER, RIGHT }

# Adjust these to sit nicely above your Dialogic box
@export var portrait_size: Vector2 = Vector2(128, 128)
@export var y_position: float = 775.0  # pixels from top; tune this above your dialogue box
@export var side_margin: float = 80.0  # horizontal inset from screen edge for LEFT/RIGHT

@onready var panel: PanelContainer = $PanelContainer
@onready var portrait_rect: TextureRect = $PanelContainer/TextureRect



func _ready() -> void:
	hide()
	portrait_rect.custom_minimum_size = portrait_size
	portrait_rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	portrait_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED


func show_portrait(texture: Texture2D, position: String) -> void:
	print("Function called: show_portrait()")
	portrait_rect.texture = texture
	await get_tree().process_frame
	show()
	_apply_position(position)


func hide_portrait() -> void:
	hide()


func _apply_position(position: String) -> void:
	var screen_width: float = get_viewport_rect().size.x
	var panel_width: float = panel.size.x if panel.size.x > 0 else portrait_size.x + 16.0
	var left_pos: float = screen_width * 0.21
	var right_pos: float = screen_width * 0.65
	
	match position.to_lower():
		"left":
			panel.position = Vector2(left_pos, y_position)
		"right":
			panel.position = Vector2(right_pos, y_position)
		_:
			panel.position = Vector2((screen_width - panel_width) / 2.0, y_position)
