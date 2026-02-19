extends Control
class_name ui_controller

@onready var CharacterPreviewScene: PackedScene = preload("res://scenes/userinterface/CharacterPreview.tscn")
@onready var preview_container := %Characters_VBOX
@onready var player_stats: PlayerStatsUI = %Player_Stats
@onready var enemy_stats: EnemyStatsUI = %Enemy_Stats
var previews: Dictionary[Character, CharacterPreview] = {}



#build all stats into a dictionary for use in the sub UI items
func build_character_stats(character: Character) -> Dictionary:
	return {
		"portrait": character.portrait,
		"name": character.data.unit_name,

		"health": character.state.current_health,
		"max_health": character.state.max_health,
		"sanity": character.state.current_sanity,
		"max_sanity": character.state.max_sanity,

		"strength": character.data.strength,
		"mind": character.data.mind,
		"speed": character.data.speed,
		"focus": character.data.focus,
		"endurance": character.data.endurance,

		"level": character.state.current_level,
		"type": "%s %s" % [
			CharacterData.Speciality.keys()[character.data.speciality],
			CharacterData.Personality.keys()[character.data.personality]
		]
	}

func build_enemy_Stats(character: Character) -> Dictionary:
	return {
		"portrait": character.portrait,
		"name": character.data.unit_name,
		"health": character.state.current_health,
		"max_health": character.state.max_health,
	}

#Update the player stats to send it to the Player_Stats, gets set in its own script
#func update_playerStats(character: Character, popup: StatPopUp) -> void:
	#popup.apply_stats(build_character_stats(character))
	#popup.show();


func _ready() -> void:
	#var level := get_tree().get_first_node_in_group("level")
	add_to_group("ui_controller")




func _clear_previews() -> void:
	print("cleared previews")
	for p: Character in previews.values():
		if is_instance_valid(p):
			p.queue_free()
	previews.clear()
	
	for child in preview_container.get_children():
		child.queue_free()
		
		
		
func _on_preview_selected(character: Character) -> void:
	var level := get_tree().get_first_node_in_group("level")
	if level:
		level.try_select_unit(character) 


func _connect_to_level(level: Node) -> void:
	if level == null:
		push_error("UIController: Level not found in group 'level'")
		print("UIController: Level not found in group 'level'")
		return
	print("ui connected to level")
	_clear_previews()
	level.character_selected.connect(_on_character_selected)
	level.character_deselected.connect(_on_character_deselected)
	level.character_stats_changed.connect(_on_character_stats_changed)
	level.party_updated.connect(_on_party_updated)
	level.enemy_selected.connect(_on_enemy_selected)
	#level.enemy_deselected.connect(_on_enemy_deselected)
	_on_party_updated(level.characters)
#adds character preview scene to Vbox
func add_character_preview(character: Character) -> void:
	if previews.has(character):
		return
	if character.state.faction == CharacterState.Faction.ENEMY:
		return
		
	var preview := CharacterPreviewScene.instantiate()
	preview_container.add_child(preview)
	preview.preview_selected.connect(_on_preview_selected)
	
	preview.call_deferred(
		"apply_stats",
		build_character_stats(character),
		character
	)
	
	previews[character] = preview

func _on_character_selected(character: Character) -> void:
	player_stats.apply_stats(build_character_stats(character))
	player_stats.show()

	for c: Character in previews.keys():
		##This is a quickfix, instead the character should be removed from the dictionary when its 
		##corresponding character dies
		if (c == null):
			continue;
		previews[c].is_selected = (c == character)
		
func _on_enemy_selected(enemy: Character) -> void:
	enemy_stats.apply_stats(build_enemy_Stats(enemy), enemy)
	enemy_stats.show()
	print("a enemy has been selected")

#func _on_enemy_deselected() -> void:
	#enemy_stats.hide()
	
func _on_character_deselected() -> void:
	#player_stats.hide()

	for preview: CharacterPreview in previews.values():
		preview.is_selected = false
		

func _on_character_stats_changed(character: Character) -> void:
	
	if character.state.current_health <= 0 \
	or character.state.faction != CharacterState.Faction.PLAYER:
		remove_character_preview(character)
		return
	
	if previews.has(character):
		previews[character].apply_stats(build_character_stats(character), character)
	
	if player_stats.visible:
		player_stats.apply_stats(build_character_stats(character))
	
	if enemy_stats.visible and character.state.faction == CharacterState.Faction.ENEMY:
		enemy_stats.apply_stats(build_enemy_Stats(character), character)


func _on_party_updated(characters: Array[Character]) -> void:
	print("UI party_updated count:", characters.size())
	for character in characters:
		##If statement in case an enemy dies during playtie, which then makes them null.
		##Instead we should be moving the null value out of the array.
		if (character == null) :
			continue;
		add_character_preview(character)
	for c: Character in previews.keys():
		if not characters.has(c):
			remove_character_preview(c)

func remove_character_preview(character: Character) -> void:
	if previews.has(character):
		var preview: CharacterPreview = previews[character]
		preview.queue_free()
		previews.erase(character)
		
	if enemy_stats.current_enemy == character:
		enemy_stats.hide()
	
