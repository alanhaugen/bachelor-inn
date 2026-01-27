extends Node3D
class_name Level
## Map logic for combat levels.
##
## All state and animation logic is found here,
## as well as input handling and audio playback.
# TODO: Stackable tiles for enemies
# TODO: Make your own units passable
# TODO: camp?
# TODO: Make enemies able to occopy several grid-tiles

@export var level_name :String

var movement_grid : MovementGrid

@export var camera_speed: float = 5.0
@export var mouse_drag_sensitivity: float = 50.0
@onready var battle_log: Label = $BattleLog

@onready var camera: Camera3D = $Camera3D
@onready var cursor: Sprite3D = $Cursor
@onready var map: GridMap = %TerrainGrid
@onready var units_map: GridMap = %OccupancyOverlay
@onready var movement_map: GridMap = %MovementOverlay
@onready var selected_attack_target_pos: Vector3i = Vector3i() # enemy tile clicked
#@onready var collidable_terrain_layer: GridMap = $CollidableTerrainLayer
@onready var path_arrow: GridMap = $PathOverlay
@onready var turn_transition: CanvasLayer = $TurnTransition/CanvasLayer
@onready var turn_transition_animation_player: AnimationPlayer = $TurnTransition/AnimationPlayer

@onready var player_label: Label = $TurnTransition/CanvasLayer/VBoxContainer/ColorRect3/playerLabel
@onready var enemy_label: Label = $TurnTransition/CanvasLayer/VBoxContainer/ColorRect3/enemyLabel

@export var minimum_camera_height: float = 3.0
@export var maximum_camera_height: float = 15.0

@export var minimum_camera_x: float = -10.0
@export var maximum_camera_x: float = 100.0
@export var minimum_camera_z: float = -10.0
@export var maximum_camera_z: float = 10.0

var planned_destination: Vector3i = Vector3i.ZERO;
var has_planned_destination: bool = false;
var planned_has_attack_from_desti: bool = false;
var planned_attack_target: Vector3i = Vector3i.ZERO
var is_choosing_attack_target: bool = false
var selected_unit: Character = null
var selected_enemy_unit: Character = null
var move_popup: Control;
var unit_popup: Control;
var stat_popup_player: Control;
var side_bar_array : Array[SideBar] = [];
var stat_popup_enemy: Control;
var completed_moves :Array[Command] = [];
var attack_mode_active := false
var popup_options: Array[Command] = [];
var popup_tile_pos: Vector3i

var characters: Array[Character] = [];

const STATS_POPUP = preload("res://scenes/userinterface/pop_up.tscn")
const MOVE_POPUP = preload("res://scenes/userinterface/move_popup.tscn")
const UNIT_POPUP = preload("res://scenes/userinterface/unit_popup.tscn")
const CHEST = preload("res://scenes/grid_items/chest.tscn")
const SIDE_BAR = preload("res://scenes/userinterface/sidebar.tscn")
const RIBBON: PackedScene = preload("res://scenes/userinterface/ribbon.tscn");

var animation_path :Array[Vector3] = [];
var is_animation_just_finished :bool = false;

var is_dragging :bool = false;

enum States {
	PLAYING,
	ANIMATING,
	CHOOSING_ATTACK };
var state :int = States.PLAYING;
var game_state : GameState;

var is_in_menu: bool = false;
var lock_camera: bool = false;
var active_move: Command;
#var moves_stack: Array;
var moves_stack: Array[Command] = [];

var ribbon: Ribbon;

var current_moves: Array[Command];
var is_player_turn: bool = true;
var unit_pos: Vector3;
var player_code: int = 0;
var player_code_done: int = 3;
var enemy_code: int = 1;
var attack_code: int = 0;
var move_code: int = 1;
enum CameraStates {
	FREE, ## player controlled
	FOCUS_UNIT, ## interpolating to a unit
	TRACK_MOVE, ## following a moving unit
	RETURN }; ## interpolating back to saved position
var camera_mode : CameraStates = CameraStates.FREE;
var saved_transform : Transform3D;
var camera_pos : Transform3D;

var monster_names := [
	"Xathog-Ruun",
	"Ylthuun",
	"Thozra’el",
	"Khar’Neth",
	"Ulmaggoth",
	"Sleeper",
	"The Thing",
	"He Who Watches",
	"The Drowned",
	"Crawling Silence",
	"Alien",
	"Zhae’kul-ith",
	"Qor’thaal",
	"Nyss-Vek",
	"Hrr’kath",
	"Vool-Xir",
	"Borrowed Faces",
	"The Unfinished",
	"Echo",
	"Sec'Mat"
]

## Old
#func show_move_popup(window_pos :Vector2) -> void:
#	move_popup.show();
#	is_in_menu = true;
#	move_popup.position = Vector2(window_pos.x + 64, window_pos.y);
#	if active_move is Attack:
#		move_popup.attack_button.show();
#	elif (active_move is Wait):
#		move_popup.wait_button.show();
#	else:
#		move_popup.move_button.show();
## new
func show_move_popup(window_pos: Vector2) -> void:
	move_popup.show()
	is_in_menu = true
	#move_popup.position = Vector2(window_pos.x + 64, window_pos.y)
	move_popup.position = Vector2(get_viewport().get_mouse_position())

	move_popup.move_button.hide()
	move_popup.attack_button.hide()
	move_popup.wait_button.hide()

	# wait is always available when unit selected
	move_popup.move_button.show()
	
	if planned_has_attack_from_desti:
		move_popup.attack_button.show()

	#var has_move := false
	#var has_attack := false
	
	#if current_moves != null:
	#	for cmd: Command in current_moves:
	#		if cmd is Move:
	#			has_move = true
	#		elif cmd is Attack:
	#			has_attack = true

	#if has_move:
	#	move_popup.move_button.show()
	#if has_attack:
	#	move_popup.attack_button.show()


func show_unit_popup(window_pos: Vector2) -> void:
	unit_popup.show()
	is_in_menu = true
	unit_popup.position = Vector2(get_viewport().get_mouse_position())

	unit_popup.ability_button.show()
	unit_popup.wait_button.show()
	unit_popup.cancel_button.show()
	
	#if (can_attack_from_destination(current_tile) == true):
	var here := Vector3i(selected_unit.state.grid_position.x, 0, selected_unit.state.grid_position.z)
	unit_popup.attack_button.visible = can_attack_from_destination(here)
	## TODO: Implement ability and wait logic
	

func raycast_to_gridmap(origin: Vector3, direction: Vector3) -> Vector3:
	var space_state: PhysicsDirectSpaceState3D = get_world_3d().direct_space_state;
	var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(
		origin,
		origin + direction * 1000.0
		);

	var result: Dictionary = space_state.intersect_ray(query)
	if result:
		return result.position
	return Vector3();


func get_grid_cell_from_mouse() -> Vector3i:
	var mouse_pos: Vector2 = get_viewport().get_mouse_position();
	var ray_origin: Vector3 = camera.project_ray_origin(mouse_pos)
	var ray_direction: Vector3 = camera.project_ray_normal(mouse_pos)
	
	# Cast ray and get intersection point
	var intersection: Vector3 = raycast_to_gridmap(ray_origin, ray_direction)
	if intersection != null:
		# Convert world position to grid coordinates
		var grid_pos: Vector3i = map.local_to_map(map.to_local(intersection));
		return grid_pos;
	
	return Vector3i();


func get_tile_name(pos: Vector3) -> String:
	if map.get_cell_item(pos) == GridMap.INVALID_CELL_ITEM:
		return "null";
	return map.mesh_library.get_item_name(map.get_cell_item(pos));


# Expanded the function to do some error searching
func get_unit_name(pos : Vector3) -> String:
	var item_id: int = units_map.get_cell_item(pos)
	if item_id == GridMap.INVALID_CELL_ITEM:
		return "null"
		
	if item_id >= units_map.mesh_library.get_item_list().size():
		push_warning("Invalid MeshLibrary item: " + str(item_id) + " at position: " + str(pos))
		return "null"
	
	return units_map.mesh_library.get_item_name(item_id)


## Replaced with show_attack_origins_for_enemy()
#func show_attack_tiles(pos : Vector3i) -> void:
	#path_arrow.clear();
	#var reachable : Array[Vector3i] = [];
	#
	#for move : Move in current_moves:
		#reachable.append(move.end_pos);
	#
	#for tile :Vector3i in MoveGenerator.get_valid_neighbours(pos, reachable):
		#path_arrow.set_cell_item(tile, 0);


func show_attack_origins_for_enemy(enemy_pos: Vector3i) -> void:
	path_arrow.clear()
	
	## enemy_pos is the ATTACK TARGET tile
	selected_attack_target_pos = enemy_pos
	
	## Should now highlight tiles to stand on this turn, and attack from
	## Origins come from Attack.end_pos (the tile attacker stands on)
	for cmd: Command in current_moves:
		if cmd is Attack:
			var atk := cmd as Attack
			if atk.attack_pos == enemy_pos:
				# origins are y=0 already in your data; keep drawing on y=0 overlays
				var origin0 := Vector3i(atk.end_pos.x, 0, atk.end_pos.z)
				path_arrow.set_cell_item(origin0, 0)


func show_attack_targets() -> void:
	movement_map.clear()
	path_arrow.clear()

	# Show all attackable target tiles (enemy positions)
	for cmd: Command in current_moves:
		if cmd is Attack:
			var atk: Attack = cmd
			var p := Vector3i(atk.attack_pos.x, 0, atk.attack_pos.z)
			movement_map.set_cell_item(p, 0) # 0 = your attack marker id (choose a constant if you have one)

	attack_mode_active = true;

func can_attack_from_destination(dest: Vector3i) -> bool:
	dest = Vector3i(dest.x, 0, dest.z)
	
	if current_moves == null:
		return false;
	
	for cmd: Command in current_moves:
		if cmd is Attack:
			var atk := cmd as Attack
			var origin := Vector3i(atk.end_pos.x, 0, atk.end_pos.z)
			if origin == dest:
				return true;
	
	return false;


func show_attack_targets_from_destination(dest: Vector3i) -> void:
	movement_map.clear()
	path_arrow.clear()

	dest = Vector3i(dest.x, 0, dest.z)
	
	var count: int = 0
	for cmd: Command in current_moves:
		if cmd is Attack:
			var atk := cmd as Attack
			var origin := Vector3i(atk.end_pos.x, 0, atk.end_pos.z)

			# Only attacks that are valid from this destination
			if origin != dest:
				continue

			# Highlight the target tile (keep the target y as in the command)
			# If your target is on y=1, keep it there for is_enemy checks,
			# but draw highlight on y=0 overlay for clicking.
			var t0 := Vector3i(atk.attack_pos.x, 0, atk.attack_pos.z)
			movement_map.set_cell_item(t0, attack_code) # use your attack marker id
			count += 1
			print("show_attack_targets_from_destination dest=", dest, " targets_shown=", count)



func _on_attack_selected() -> void:
	#if selected_attack_target_pos == Vector3i.ZERO:
	if selected_unit == null:
		return
	
	planned_destination = Vector3i(selected_unit.state.grid_position.x, 0, selected_unit.state.grid_position.z)
	has_planned_destination = true
	
	is_in_menu = false
	is_choosing_attack_target = true
	planned_attack_target = Vector3i.ZERO

	show_attack_targets_from_destination(planned_destination)	
	return
		
	show_attack_origins_for_enemy(selected_attack_target_pos)
	state = States.CHOOSING_ATTACK


func _on_move_selected() -> void: ## TODO: implement move
	## run virtual move
	if selected_unit == null or not has_planned_destination:
		is_in_menu = false
		return

	var start := Vector3i(selected_unit.state.grid_position.x, 0, selected_unit.state.grid_position.z)
	var end := planned_destination

	is_in_menu = false
	movement_map.clear()
	path_arrow.clear()

	moves_stack.clear()
	moves_stack.append(Move.new(start, end))
	create_path(start, end)
	state = States.ANIMATING

	has_planned_destination = false
	return 


func _on_wait_selected() -> void:
	is_in_menu = false;
	return ## TODO: implement wait


func _on_ability_selected() -> void:
	is_in_menu = false;
	return ## use ability here

func _on_cancel_selected() -> void:
	#selected_unit = null; ## deselect unit?
	is_in_menu = false;
	return


func _input(event: InputEvent) -> void:
	if state == States.ANIMATING:
		return;
	if is_in_menu:
		return;
	
	if event is InputEventMouseMotion and is_dragging:
		camera.global_translate(Vector3(-event.relative.x,0,-event.relative.y) / mouse_drag_sensitivity);
		Tutorial.tutorial_camera_moved();
	
	if event is InputEventScreenDrag and event.index >= 1:
		camera.global_translate(Vector3(-event.relative.x,0,-event.relative.y) / mouse_drag_sensitivity);
		Tutorial.tutorial_camera_moved();
	
	if event is InputEventMouseButton:
		# Ignore mouse up events
		if lock_camera == false:
			if event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
				Input.mouse_mode = Input.MouseMode.MOUSE_MODE_CAPTURED;
				is_dragging = true;
		if (event.pressed == false):
			is_dragging = false;
			Input.mouse_mode = Input.MouseMode.MOUSE_MODE_VISIBLE;
			return;
		if (event.button_index != MOUSE_BUTTON_LEFT):
			return;
		
		## Get the tile clicked on -- Using two 
		var pos_raw: Vector3i = get_grid_cell_from_mouse() # y may be 1 for units layer
		print(pos_raw)

		var pos: Vector3i = Vector3i(pos_raw.x, 0, pos_raw.z) # overlay/pathing layer
		
		if is_choosing_attack_target:
			## Click on a highlighted target tile?
			if movement_map.get_cell_item(pos) != GridMap.INVALID_CELL_ITEM:
				planned_attack_target = pos
				is_choosing_attack_target = false
				movement_map.clear()
				path_arrow.clear()

				# Commit move+attack chain will go under here.
				print("Planned target selected:", planned_attack_target)
				return
			else:
				is_choosing_attack_target = false
				movement_map.clear()
				path_arrow.clear()
				return
		
		if state == States.CHOOSING_ATTACK:
			#if movement_map.get_cell_item(pos) != GridMap.INVALID_CELL_ITEM:
			#	active_move.end_pos = pos;
			#	moves_stack.append(active_move);
			#if path_arrow.get_cell_item(pos) != GridMap.INVALID_CELL_ITEM:
				
			#	var chosen_attack : Attack = null
			#	for cmd in current_moves:
			#		var atk := cmd as Attack
			#		if atk.attack_pos == selected_attack_target_pos and atk.end_pos == pos:
			#			chosen_attack = atk;
			#			break
			if path_arrow.get_cell_item(pos) != GridMap.INVALID_CELL_ITEM:
				var chosen_attack: Attack = null
				for cmd: Command in current_moves:
					if cmd is Attack:
						var atk := cmd as Attack
						if atk.attack_pos == selected_attack_target_pos and Vector3i(atk.end_pos.x,0,atk.end_pos.z) == pos:
							chosen_attack = atk
							break
						
				if chosen_attack:
					active_move = chosen_attack
					moves_stack.append(active_move)
					create_path(active_move.start_pos, active_move.end_pos)
					state = States.ANIMATING
				#create_path(moves_stack.front().start_pos, moves_stack.front().end_pos); # a-star used to select how the character moves when move + attack
				#state = States.ANIMATING;
			return;
		
		if (selected_enemy_unit != null):
			selected_enemy_unit.hide_ui();
			stat_popup_enemy.hide();
			if selected_unit == null:
				stat_popup_player.hide();
		
		if (get_tile_name(pos) == "Water"):
			return
		
		var globalPos: Vector3i = map.map_to_local(pos)
		cursor.position = Vector3(globalPos.x, cursor.position.y, globalPos.z)
		#map.set_cell(pos, 1);
		#unitsMap.set_cell(pos, 0, Vector2(14,3));
		cursor.show()
		
		var windowPos: Vector2 = Vector2(350,300)
		
		if (get_unit_name(pos) == CharacterStates.Player):
			print("Pressed self/your current unit")
			Tutorial.tutorial_unit_selected()
			unit_pos = pos
			movement_map.clear()
			if selected_unit == get_unit(pos):
				## Pressing own unit char will now open a unit menu
				#active_move = Wait.new(pos)
				planned_destination = Vector3i(pos.x, 0, pos.z)
				has_planned_destination = true
				planned_has_attack_from_desti = can_attack_from_destination(planned_destination)
				print("Attack-from-here setup dest=", planned_destination, " can_attack=", planned_has_attack_from_desti)
				show_unit_popup(get_viewport().get_mouse_position()) ## show_unit_popup
				#show_move_popup(selected_unit.get_unit(pos))
				return;
			else:
				if selected_unit != null:
					var character_script: Character = selected_unit
					character_script.hide_ui()
				selected_unit = get_unit(pos)
				ribbon.show()
				ribbon.set_skills(selected_unit.state.skills)
				#ribbon.set_abilities(selected_unit.skills);
				
				## STEP 1 - Generate moves after clicking friendly unit
				current_moves = MoveGenerator.generate(selected_unit, game_state)
				
				## Print to check if attack moves are generated.
				var atk_total := 0
				var move_total := 0
				for cmd: Command in current_moves:
					if cmd is Attack:
						atk_total += 1
					elif cmd is Move:
						move_total += 1
				print("Generated moves: total=", current_moves.size(), " moves=", move_total, " attacks=", atk_total)
				
				movement_grid.fill_from_commands(current_moves, game_state)
				
				#for command in current_moves:
				#	if command  is Move:
				#		touch(command.end_pos);
				#	if command is Attack:
				#		movement_map.set_cell_item(command.attack_pos, attack_code);
				
				#camera.position.x = selected_unit.position.x;# + 4.5;
				#camera.position.z = selected_unit.position.z + 3.0;#6.5;
				update_stat(selected_unit, stat_popup_player);
		
		elif (movement_map.get_cell_item(pos) != GridMap.INVALID_CELL_ITEM and selected_unit != null):
			## Virtual movement and planning attack.
			planned_destination = Vector3i(pos.x, 0, pos.z)
			has_planned_destination = true
			planned_has_attack_from_desti = can_attack_from_destination(planned_destination);
			 
			show_move_popup(get_viewport().get_mouse_position());
			return;
			#	if current_moves[i] is Attack:
			#		if current_moves[i].attack_pos == pos:
			#			active_move = current_moves[i];
			#	elif current_moves[i].end_pos == pos:
			#		active_move = current_moves[i];
			
			#if active_move is Attack:
			#	#show_attack_tiles(pos); ## replaced with function underneath
			#	show_attack_origins_for_enemy(pos)
			#	return;
				
			#elif active_move is Move:
			#	moves_stack.append(active_move);
			#	state = States.ANIMATING;
			#	create_path(unit_pos, pos); # a-star used for normal character movement
			#	path_arrow.clear();
			#	movement_map.clear();
			#activeMove.execute();
			#unitsMap.set_cell_item(pos, playerCodeDone);
			#unitsMap.set_cell_item(unitPos, -1);
			#isUnitSelected = false;
		else:
			movement_map.clear();
			path_arrow.clear();
			
			if selected_unit is Character:
				var character_script: Character = selected_unit;
				character_script.hide_ui();
			
			selected_unit = null;
			
			ribbon.hide();
		
		if (get_unit_name(pos) == CharacterStates.Enemy):
			
			selected_enemy_unit = get_unit(pos);
			update_stat(selected_enemy_unit, stat_popup_enemy);
			
			#if selected_unit != null and current_moves != null:
			#	selected_attack_target_pos = pos ## failsafe
				
			#var can_attack_this_enemy:= false
			#for cmd: Command in current_moves:
			#	if cmd is Attack:
			#		var atk := cmd as Attack
			#		if atk.attack_pos == pos:
			#			can_attack_this_enemy = true
			#			break
			## Print check
			if selected_unit != null:
				print("ENEMY CLICK BLOCK HIT at pos=", pos, " get_unit_name=", get_unit_name(pos))
				print("selected_unit is null? ", selected_unit == null)
				print("current_moves is null? ", current_moves == null, " size=", (current_moves.size() if current_moves != null else -1))

				var atk_total := 0
				if current_moves != null:
					for cmd in current_moves:
						if cmd is Attack:
							atk_total += 1
				print("atk_total=", atk_total)

				var options: Array[Command] = []
				for cmd: Command in current_moves:
					if cmd is Attack:
						options.append(cmd)
						break;
						
				if options.size() > 0:
					show_move_popup(get_viewport().get_mouse_position())
					## print to check for attack moves
					var atk_vs_this_enemy := 0
					print("Clicked enemy pos=", pos, " enemy grid_position=", selected_enemy_unit.state.grid_position)
					## print to check pos coords
					#for cmd: Command in current_moves:
					#	if cmd is Attack:
					#		var atk := cmd as Attack
					#		print("Attack cmd target=", atk.attack_pos, " origin=", atk.end_pos, " typeof(target)=", typeof(atk.attack_pos))

					for cmd: Command in current_moves:
						if cmd is Attack: 
							var atk:= cmd as Attack
							if atk.attack_pos == pos_raw: # <-- compare on same y-layer
								atk_vs_this_enemy += 1
					print("Enemy click at ", pos_raw, " attack options vs this enemy=", atk_vs_this_enemy)
					#show_move_popup(windowPos, options, pos)
					return;
		
		if (get_unit_name(pos) == CharacterStates.PlayerDone):
			update_stat(get_unit(pos), stat_popup_player);
	#elif event is InputEventMouseMotion:
	#	print("Mouse Motion at: ", event.position)


func update_stat(character: Character, popup: StatPopUp) -> void:
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

func update_side_bar(character: Character, side_bar: SideBar) -> void:
	if character is Character:
		var character_script: Character = character;
		side_bar.icon_texture.texture = character_script.portrait;
		#side_bar.name_label.text = character_script.unit_name;
		side_bar.max_health = character_script.state.max_health;
		side_bar.health = character_script.state.current_health;
		side_bar.max_sanity = max(side_bar.max_sanity, character_script.state.current_sanity);
		side_bar.sanity = character_script.state.current_sanity;

func _ready() -> void:
	cursor.hide()
	movement_map.clear()
	units_map.hide()
	path_arrow.clear()
	
	movement_grid = MovementGrid.new(movement_map);
	
	ribbon = RIBBON.instantiate();
	add_child(ribbon);
	ribbon.hide();
	
	if (level_name == "first"):
		Dialogic.start(str(level_name) + "Level");
		is_in_menu = true;
	
	Main.battle_log = battle_log;
	
	var units :Array[Vector3i] = units_map.get_used_cells();
	
	var characters_placed := 0;
	
	print("Loading new level, number of playable characters: " + str(Main.characters.size()));
	
	for i in units.size():
		var pos: Vector3 = units[i];
		var new_unit: Character = null;
		
		if (get_unit_name(pos) == "Unit"):
			if characters_placed < Main.characters.size():
				new_unit = Main.characters[characters_placed];
				new_unit.state.is_moved = false;
				new_unit.camera = get_viewport().get_camera_3d();
				characters_placed += 1;
				var health := str(new_unit.state.current_health)
				if health == "0":
					health = "fresh unit"
				print("This character exists: " + str(new_unit.data.unit_name) + " health: " + str(health));
			else:
				units_map.set_cell_item(pos, GridMap.INVALID_CELL_ITEM);
		elif (get_unit_name(pos) == "Enemy"):
			#new_unit = ENEMY.instantiate();
			
			var data := CharacterData.new()

			var c_state := CharacterState.new()
			c_state.faction = CharacterState.Faction.ENEMY;

			var _char := Character.new()
			_char.data = data
			_char.state = c_state
			
			new_unit = _char;
			
			new_unit.data.unit_name = monster_names[randi_range(0, monster_names.size() - 1)];
		elif (get_unit_name(pos) == "Chest"):
			var chest: Node = CHEST.instantiate();
			chest.position = pos * 2;
			chest.position += Vector3(1, 0, 1);
			add_child(chest);
		elif (get_unit_name(pos) == "VictoryTrigger"):
			pass
		else:
			units_map.set_cell_item(pos, GridMap.INVALID_CELL_ITEM);
			
		if (new_unit != null):
			#unitArray.append(newUnit);
			new_unit.position = pos * 2;
			new_unit.position += Vector3(1, 0, 1);
			#newUnit = 2;
			if new_unit.get_parent():
				new_unit.reparent(Main.world, false);
			add_child(new_unit);
			characters.append(new_unit);
			
			if new_unit is Character:
				var character_script : Character = new_unit;
				character_script.hide_ui();
				new_unit.state.grid_position = pos;
	
	move_popup = MOVE_POPUP.instantiate()
	move_popup.hide()
	add_child(move_popup)
	
	unit_popup = UNIT_POPUP.instantiate()
	unit_popup.hide()
	add_child(unit_popup)
	
	move_popup.attack_pressed.connect(_on_attack_selected)
	move_popup.move_pressed.connect(_on_move_selected) ## TODO: Complete the func _on_move
	move_popup.wait_pressed.connect(_on_wait_selected) ## TODO: Complete the func _on_wait
	unit_popup.ability_pressed.connect(_on_ability_selected) ## TODO: Complete the func _on_move
	unit_popup.wait_pressed.connect(_on_wait_selected) ## TODO: Complete the func _on_move
	unit_popup.cancel_pressed.connect(_on_cancel_selected) ## TODO: Complete the func _on_move
	unit_popup.attack_pressed.connect(_on_attack_selected) ## TODO: Complete the func
	
	stat_popup_player = STATS_POPUP.instantiate()
	stat_popup_player.hide()
	stat_popup_player.scale = Vector2(Main.ui_scale, Main.ui_scale)
	stat_popup_player.position = Vector2(0, -30)
	#stat_popup_player.position = Vector2(-555, 235);
	#stat_popup_player.set_anchor(SIDE_LEFT, 0);
	#stat_popup_player.offset_bottom = get_window().size.y/(Main.ui_scale);
	add_child(stat_popup_player)
	
	stat_popup_enemy = STATS_POPUP.instantiate()
	stat_popup_enemy.hide()
	stat_popup_enemy.scale = Vector2(Main.ui_scale, Main.ui_scale)
	stat_popup_enemy.position = Vector2(get_window().size.x - 155, -30)
	#stat_popup_enemy.position = Vector2(250, 235);
	#stat_popup_enemy.set_anchor(SIDE_RIGHT, 0);
	add_child(stat_popup_enemy)
	
	for i in range(Main.characters.size()):
		var new_side_bar := SIDE_BAR.instantiate();
		new_side_bar.scale = Vector2(Main.ui_scale, Main.ui_scale);
		if i != 0:
			new_side_bar.position.y += -get_window().size.y/(15/Main.ui_scale)*i;
		side_bar_array.append(new_side_bar);
		add_child(new_side_bar);
		print("made bar");
	
	
	game_state = GameState.from_level(self)
	
	turn_transition_animation_player.play()
	#turn_transition.get_canvas().hide();
	#tiles = map.get_used_cells();
#	units.append(unit);


func get_unit(pos: Vector3i) -> Character:
	for i in range(characters.size()):
		if is_instance_valid(characters[i]):
			if characters[i] is Character:
				var unit: Character = characters[i];
				if unit.state.grid_position == pos:
					return unit;
	return null;


func create_path(start : Vector3i, end : Vector3i) -> void:
	animation_path.clear()
	path_arrow.clear()
	movement_grid.fill_from_commands(MoveGenerator.generate(game_state.get_unit(moves_stack.front().start_pos), game_state), game_state)
	
	var path := movement_grid.get_path(start, end)

	for p in path:
		var anim_pos := map.map_to_local(p)
		anim_pos.y = 0
		animation_path.append(anim_pos)

	selected_unit = get_unit(start)


func reset_all_units() -> void:
	var units :Array[Vector3i] = units_map.get_used_cells();
	for i in units.size():
		var pos :Vector3i = units[i];
		if (units_map.get_cell_item(pos) == player_code_done):
			units_map.set_cell_item(pos, player_code);
		var character: Character = get_unit(pos);
		if character is Character:
			var character_script: Character = character;
			character_script.reset();


func MoveAI() -> void:
	var ai := MinimaxAI.new();
	var current_state := GameState.from_level(self);
	
	if current_state.has_enemy_moves():
		var move : Command = ai.choose_best_move(current_state, 2);
		moves_stack.append(move);
		current_state = current_state.apply_move(move, true);
	
	if (moves_stack.is_empty() == false):
		create_path(moves_stack.front().start_pos, moves_stack.front().end_pos); # a-star for pathfinding AI
		state = States.ANIMATING;


func CheckVictoryConditions() -> void:
	var units :Array[Vector3i] = units_map.get_used_cells();
	var numberOfPlayerUnits :int = 0;
	var numberOfEnemyUnits  :int = 0;
	
	for i in units.size():
		var pos :Vector3i = units[i];
		if (units_map.get_cell_item(pos) == player_code || units_map.get_cell_item(pos) == player_code_done):
			numberOfPlayerUnits += 1;
		elif (units_map.get_cell_item(pos) == enemy_code):
			numberOfEnemyUnits += 1;
	
	if (numberOfPlayerUnits == 0):
		get_tree().change_scene_to_file("res://scenes/states/gameover.tscn");
	elif (numberOfEnemyUnits == 0):
		Main.next_level();


func interpolate_to(target_transform:Transform3D, delta:float) -> void:
	global_transform.origin = global_transform.origin.lerp(
		target_transform.origin,
		1.0 - exp(-camera_speed * delta)
	)
	
	global_transform.basis = global_transform.basis.slerp(
		target_transform.basis,
		1.0 - exp(-camera_speed * delta)
	)


func _process(delta: float) -> void:
	if (turn_transition_animation_player.is_playing()):
		turn_transition.show()
		return;
		
	for i in Main.characters.size():
		update_side_bar(Main.characters[i], side_bar_array[i]);
		
	turn_transition.hide();
	
	if state == States.PLAYING and selected_unit and is_in_menu == false:
		var pos :Vector3i = get_grid_cell_from_mouse();
		pos.y = 0; ## grid map is at y = 1
		if movement_map.get_cell_item(pos) != GridMap.INVALID_CELL_ITEM:
			path_arrow.clear()
			var points := movement_grid.get_path(selected_unit.state.grid_position, pos)
			for point in points:
				path_arrow.set_cell_item(point, 0)
			#a_star(selected_unit.state.grid_position, pos); # a-star for drawing arrow
			if get_unit(pos) is Character and get_unit(pos).state.is_enemy():
				update_stat(get_unit(pos), stat_popup_enemy);
	
	if camera_mode == CameraStates.FREE:
		saved_transform = global_transform;
	
	if camera_mode == CameraStates.RETURN:
		camera_pos = saved_transform;
	
	interpolate_to(camera_pos, delta);
	
	if lock_camera == false:
		if camera.position.x < maximum_camera_x:
			if Input.is_action_pressed("pan_right"):
				camera.global_translate(Vector3(1,0,0) * camera_speed * delta);
				Tutorial.tutorial_camera_moved();
		if camera.position.x > minimum_camera_x:
			if Input.is_action_pressed("pan_left"):
				camera.global_translate(Vector3(-1,0,0) * camera_speed * delta);
		if camera.position.z > minimum_camera_z:
			if Input.is_action_pressed("pan_up"):
				camera.global_translate(Vector3(0,0,-1) * camera_speed * delta);
		if camera.position.z < maximum_camera_z:
			if Input.is_action_pressed("pan_down"):
				camera.global_translate(Vector3(0,0,1) * camera_speed * delta);
		if Input.is_action_pressed("selected"):
			pass;
	
	if camera.global_position.y > minimum_camera_height:
		if Input.is_action_just_released("zoom_in") or Input.is_action_pressed("zoom_in"):
			camera.global_position -= camera.global_transform.basis.z * camera_speed * 20 * delta;
	if camera.global_position.y < maximum_camera_height:
		if Input.is_action_just_released("zoom_out") or Input.is_action_pressed("zoom_out"):
			camera.global_position += camera.global_transform.basis.z * camera_speed * 20 * delta;
	
	if (is_in_menu):
		return;
	
	if (state == States.PLAYING):
		if (is_animation_just_finished):
			is_animation_just_finished = false;
			turn_transition_animation_player.play();
			enemy_label.hide();
			player_label.show();
		if (is_player_turn):
			is_player_turn = false;
			var units :Array[Vector3i] = units_map.get_used_cells();
			for i in units.size():
				var pos :Vector3i = units[i];
				if (units_map.get_cell_item(pos) == player_code):
					is_player_turn = true;
			if (is_player_turn == false):
				turn_transition_animation_player.play();
				enemy_label.show();
				player_label.hide();
		else:
			reset_all_units();
			MoveAI();
	elif (state == States.ANIMATING):
		# Animations done: stop animating
		if (moves_stack.is_empty()):
			state = States.PLAYING;
			movement_map.clear()
			if (is_player_turn == false):
				is_animation_just_finished = true;
				is_player_turn = true;
		# Done with one move, execute it and start on next
		elif (animation_path.is_empty()):
			active_move = moves_stack.pop_front();
			if get_unit_name(active_move.end_pos) == "VictoryTrigger":
				Dialogic.start(level_name + "LevelVictory")
			active_move.execute(game_state);
			CheckVictoryConditions();
			var code := enemy_code;
			if is_player_turn:
				code = player_code_done;
			units_map.set_cell_item(active_move.start_pos, GridMap.INVALID_CELL_ITEM);
			units_map.set_cell_item(active_move.end_pos, code);
			selected_unit.move_to(active_move.end_pos);
			selected_unit = null;
			completed_moves.append(active_move);
			Tutorial.tutorial_unit_moved();
			
			if is_player_turn == false:
				MoveAI();
			
			if (moves_stack.is_empty() == false):
				create_path(moves_stack.front().start_pos, moves_stack.front().end_pos); # a-star for enemy animation/movement?
			
			if (animation_path.is_empty() == false):
				selected_unit.position = animation_path.pop_front();
		# Process animation
		else:
			var movement_speed := 80.0 # units per second
			var target : Vector3 = animation_path.front()
			var dir : Vector3 = target - selected_unit.position
			var step := movement_speed * delta

			if dir.length() <= step:
				selected_unit.position = target
				animation_path.pop_front()
			else:
				selected_unit.position += dir.normalized() * step
				#camera.position.x = selected_unit.position.x;# + 4.5;
				#camera.position.z = selected_unit.position.z + 3.0;#6.5;
				
				#if (dir.z > 0):
				#	selected_unit.sprite.play_clip("walk_up");
				#elif (dir.z < 0):
				#	selected_unit.sprite.play_clip("walk_down");
				#elif (dir.x > 0):
				#	selected_unit.sprite.play_clip("walk_side");
				#	selected_unit.sprite.flip_h = false;
				#elif (dir.x < 0):
				#	selected_unit.sprite.play_clip("walk_side");
				#	selected_unit.sprite.flip_h = true;
			
			#animated_unit.position.x = animationPath
