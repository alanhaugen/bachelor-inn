extends Control

@onready var top: ColorRect = $Top
@onready var bottom: ColorRect = $Bottom
@onready var left: ColorRect = $Left
@onready var right: ColorRect = $Right

var overlay_color := Color(0, 0, 0, 0.7)

func highlight(target: Control) -> void:
	var padding := 10.0
	var global_rect: Rect2 = target.get_global_rect().grow(padding)
	
	var offset := global_position
	var rect := Rect2(global_rect.position - offset, global_rect.size)
	var screen := get_rect()
	
	top.color = overlay_color
	top.position = Vector2.ZERO
	top.size = Vector2(screen.size.x, rect.position.y)
	
	bottom.color = overlay_color
	bottom.position = Vector2(0, rect.position.y + rect.size.y)
	bottom.size = Vector2(screen.size.x, screen.size.y - rect.position.y - rect.size.y)
	
	left.color = overlay_color
	left.position = Vector2(0, rect.position.y)
	left.size = Vector2(rect.position.x, rect.size.y)
	
	right.color = overlay_color
	right.position = Vector2(rect.position.x + rect.size.x, rect.position.y)
	right.size = Vector2(screen.size.x - rect.position.x - rect.size.x, rect.size.y)
	show()
	
func clear() -> void:
	hide()
