extends Control

#@export var SelectedCharacterStatus: PackedScene
@export var CharacterPreview: PackedScene
#var level.gd (holds all the data i need, i probably should only get the dictionary from it when stats like
#selected character or hp change, 

#from level.gd:
func update_playerStats(character: Character, popup: StatPopUp) -> void:
	if character is Character:
		var character_script: Character = character;
		character_script.show_ui();
		#character_script.print_stats();
		if popup is StatPopUp:
			var stat_script: StatPopUp = popup;
			stat_script.icon_texture.texture = character_script.portrait
			stat_script.name_label.text = character_script.data.unit_name
			stat_script.max_health = character_script.state.max_health
			stat_script.health = character_script.state.current_health
			stat_script.max_sanity = character_script.state.max_sanity
			stat_script.sanity = character_script.state.current_sanity
			
			stat_script.strength = character_script.data.strength
			stat_script.mind = character_script.data.mind
			stat_script.speed = character_script.data.speed
			stat_script.focus = character_script.data.focus
			stat_script.endurance = character_script.data.endurance
			
			stat_script.level = "Level: " + str(character_script.state.current_level);
			
			stat_script._set_type(CharacterData.Speciality.keys()[character_script.data.speciality] + " " + CharacterData.Personality.keys()[character_script.data.personality]);
			
			popup.show();


func update_characterpreview(character: Character, side_bar: SideBar) -> void:
	if character is Character:
		var character_script: Character = character;
		side_bar.icon_texture.texture = character_script.portrait;
		#side_bar.name_label.text = character_script.unit_name;
		side_bar.max_health = character_script.state.max_health;
		side_bar.health = character_script.state.current_health;
		side_bar.max_sanity = max(side_bar.max_sanity, character_script.state.current_sanity);
		side_bar.sanity = character_script.state.current_sanity;


#i should get the dict here and distribute the "stats" to all the assets in the UI, enemy_Stats comes later! 
#also maybe i dont need to add player stats as a child, only change its contents, 
#Scale/Player_Stats $Player_Stats is it, 



func _add_CharacterPreview(_in_preview: PackedScene) -> void:
	print("adding child")
	
	#here i should add the packed scene of the character preview to Scale/Characters_VBOX, for each existing character in the scene
