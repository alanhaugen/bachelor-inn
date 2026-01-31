extends Control

#@export var SelectedCharacterStatus: PackedScene
@export var CharacterPreview: PackedScene

#i should get the struct here and distribute the "stats" to all the assets in the UI, enemy_Stats comes later! 
#also maybe i dont need to add player stats as a child, only change its contents, 
#Scale/Player_Stats $Player_Stats is it, 



func _add_CharacterPreview(_in_preview: PackedScene) -> void:
	print("adding child")
	
	#here i should add the packed scene of the character preview to Scale/Characters_VBOX, for each existing character in the scene
