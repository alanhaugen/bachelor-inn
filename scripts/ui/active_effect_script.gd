extends Control

func set_visuals(e: Dictionary) -> void:
	$ActiveEffectIcon.texture = e.get("icon", null)
	$ActiveEffectLabel.text = str(e.get("rounds", 0))
	tooltip_text = str(e.get("tooltip", ""))
