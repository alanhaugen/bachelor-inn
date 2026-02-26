extends Resource
class_name SaveGame

const SAVE_GAME_PATH := "user://noblenights_saves.tres";


const ALFRED: PackedScene = preload("res://scenes/grid_items/alfred.tscn");
const LUCY: PackedScene = preload("res://scenes/grid_items/Char_Lucy.tscn");

const CHARACTER_SCENES := {
	"Alfred" : ALFRED,
	"Lucy" : LUCY
}

## Use this to detect old player save files and update them 
@export var version := 1;
@export var map_name := "first";


func is_savefile_existing() -> bool:
	return FileAccess.file_exists(SAVE_GAME_PATH);


func create_new_from_state(slot:int, level: int, state: GameState) -> void:
	var units: Array[Character]
	
	for unit in state.units:
		units.append(unit.save())
	
	# TODO: Save into correct slot
	# TODO: Make sure it does not overwrite other files
	var _save := {
		"level": level,
		"units": units
	}
	
	# TODO: Save to file
	#var json_string: String = JSON.stringify(saves);
	#save_file.store_string(json_string);
	#save_file.close();


func create_new_save_data() -> void:
	var save_file: Object = FileAccess.open(SAVE_GAME_PATH, FileAccess.WRITE);
	
	var data1 := CharacterData.new()
	data1.unit_name = "Alfred"
	data1.speciality = CharacterData.Speciality.Scholar
	data1.mind = 6
	data1.focus = 5

	var state1 := CharacterState.new()
	state1.weapon = WeaponRegistry.get_weapon("scepter_basic")
	state1.skills = [
					SkillRegistry.get_skill("haste_basic"),
					SkillRegistry.get_skill("fireball_basic")
					]
	
	var char1 := Character.new()
	char1.data = data1
	char1.state = state1
	char1.scene_id = "Alfred"	#Scene id er den scena som skal loades for denne karakteren!! du må definere Packed scene som en constant øverst
	
	var data2 := CharacterData.new()
	data2.unit_name = "Lucy"
	data2.speciality = CharacterData.Speciality.Militia
	data2.strength = 10

	var state2 := CharacterState.new()
	state2.weapon = WeaponRegistry.get_weapon("sword_basic")
	#state2.skills = [SkillRegistry.get_skill("defence_basic")]
	state2.skills = [
					SkillRegistry.get_skill("defence_basic"),
					SkillRegistry.get_skill("trap_basic")
					]

	var char2 := Character.new()
	char2.data = data2
	char2.state = state2
	char2.scene_id = "Lucy"	 #Scene id er den scena som skal loades for denne karakteren!! du må definere Packed scene som en constant øverst
	
	var units := [
		char1.save(), 
		char2.save()
	];
	
	var saves := {
		"Noble Nights Save format": version,
		"Slot 1":
		{
			"level": 0,
			"units": units
		},
		"Slot 2":
		{
			"level": 1,
			"units": units
		},
		"Slot 3":
		{
			"level": 2,
			"units": units
		},
	}
	
	#is the VAR necessary????? nope. but it is more readable
	var json_string: String = JSON.stringify(saves);
	save_file.store_string(json_string);
	save_file.close();


func write(_save_slot: int) -> void:
	var save_file: Object = FileAccess.open(SAVE_GAME_PATH, FileAccess.WRITE)
	
	if !is_instance_valid(Main.level):
		push_error("Main level does not exist");
		return;
	
	var moves: Array[Move] = Main.level.moves;
	for move: Move in moves:
		# Check the node has a save function.
		if !move.has_method("save"):
			print("node '%s' is missing a save() function, skipped" % move.name)
			continue

		# Call the node's save function.
		var move_data: String = move.call("save")

		# Store the save dictionary as a new line in the save file.
		save_file.store_line(JSON.stringify(move_data));
	save_file.close();


func read(save_slot: int) -> bool:
	if not FileAccess.file_exists(SAVE_GAME_PATH):
		return false

	var file := FileAccess.open(SAVE_GAME_PATH, FileAccess.READ)
	var json_string := file.get_as_text()
	file.close()

	var json := JSON.new()
	if json.parse(json_string) != OK:
		push_error("JSON parse error")
		return false

	var save : Dictionary = json.data

	var slot_key := "Slot " + str(save_slot + 1)
	if not save.has(slot_key):
		return false

	var slot : Dictionary = save[slot_key]

	if not slot.has("level") or not slot.has("units"):
		return false

	var level : int = slot["level"]
	var units : Array = slot["units"]

	Main.characters.clear()

	for unit_dict : Dictionary in units:
		
		var scene_id : String = unit_dict.get("scene")
		var packed_scene : PackedScene = CHARACTER_SCENES.get(scene_id)
		var character := packed_scene.instantiate();

		# --- DATA ---
		var data := CharacterData.new()
		var data_dict : Dictionary = unit_dict["data"]

		data.unit_name = data_dict["unit_name"]
		data.speciality = data_dict["speciality"]
		data.personality = data_dict["personality"]
		data.strength = data_dict["strength"]
		data.mind = data_dict["mind"]
		data.speed = data_dict["speed"]
		data.focus = data_dict["focus"]
		data.endurance = data_dict["endurance"]


		# --- STATE ---
		var state := CharacterState.new()
		var state_dict : Dictionary = unit_dict["state"]

		var gp : Array = state_dict["grid_position"]
		state.grid_position = Vector3i(gp[0], gp[1], gp[2])

		state.faction = state_dict["faction"]
		state.experience = state_dict["experience"]
		state.level = state_dict["level"]
		state.current_health = state_dict["current_health"]
		state.current_sanity = state_dict["current_sanity"]
		state.weapon = WeaponRegistry.get_weapon(state_dict["weapon_id"])
		state.skills.clear()
		var ids: Array = state_dict.get("skill_ids", [])
		for id_any: String in ids:
			var id: String = str(id_any)
			var s: Skill = SkillRegistry.get_skill(id)
			if s != null:
				state.skills.append(s)
		
		character.data = data
		character.state = state
		
		print("DEBUG LOADED unit:", data.unit_name, " skills:", state.skills.size(), " ids:", state_dict.get("skill_ids", []))
		print("LOADED ", data.unit_name, " skill_ids=", state_dict.get("skill_ids", []))
		print("RESOLVED ", data.unit_name, " skills=", state.skills.map(func(s: Skill) -> String: return s.skill_id if s else "NULL"))
		
		Main.characters.append(character)

	Main.load_level(Main.levels[level])
	return true
