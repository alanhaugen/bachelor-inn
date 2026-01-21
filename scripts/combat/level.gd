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

var terrain_grid : Grid
var path_grid : Grid
var occupancy_grid : Grid
var trigger_grid : Grid
var fog_grid : Grid
var movement_grid : MovementGrid

@export var camera_speed: float = 5.0
@export var mouse_drag_sensitivity: float = 50.0
@onready var battle_log: Label = $BattleLog


@onready var cursor: Sprite3D = $Cursor
@onready var terrain_map: GridMap = %TerrainGrid
@onready var occupancy_map: GridMap = %OccupancyOverlay
@onready var movement_map: GridMap = %MovementOverlay
@onready var trigger_map: GridMap = %TriggerOverlay
@onready var path_map: GridMap = $PathOverlay
@onready var fog_map: GridMap = $FogOverlay
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

var selected_unit: Character = null
var selected_enemy_unit: Character = null
var move_popup: Control;
var stat_popup_player: Control;
var side_bar_array : Array[SideBar];
var stat_popup_enemy: Control;
var completed_moves :Array[Command];

var characters: Array[Character];

const STATS_POPUP = preload("res://scenes/userinterface/pop_up.tscn")
const MOVE_POPUP = preload("res://scenes/userinterface/move_popup.tscn")
const CHEST = preload("res://scenes/grid_items/chest.tscn")
const SIDE_BAR = preload("res://scenes/userinterface/sidebar.tscn")
const RIBBON: PackedScene = preload("res://scenes/userinterface/ribbon.tscn");
const PLAYER: PackedScene = preload("res://scenes/grid_items/alfred.tscn");

var animation_path :Array[Vector3];
var is_animation_just_finished :bool = false;

#region Mouse Camera Movement
var is_dragging :bool = false;
var _screen_movement : Vector2 = Vector2(0, 0)
#endregion

enum States {
	PLAYING,
	ANIMATING,
	CHOOSING_ATTACK };
var state :int = States.PLAYING;
var game_state : GameState;

var is_in_menu: bool = false;
var lock_camera: bool = false;
var active_move: Command;
var moves_stack: Array;

var ribbon: Ribbon;

var current_moves: Array[Command];
var is_player_turn: bool = true;
var unit_pos: Vector3;
var player_code: int = 0;
var player_code_done: int = 3;
var enemy_code: int = 1;
var attack_code: int = 0;
var move_code: int = 1;

#region Camera
@onready var camera: Camera3D = $Camera3D
enum CameraStates {
	FREE, ## player controlled
	FOCUS_UNIT, ## interpolating to a unit
	TRACK_MOVE, ## following a moving unit
	RETURN }; ## interpolating back to saved position
var camera_mode : CameraStates = CameraStates.FREE;
var saved_transform : Transform3D;
var camera_controller : CameraController
#endregion

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


func show_move_popup(window_pos :Vector2) -> void:
	move_popup.show();
	is_in_menu = true;
	move_popup.position = Vector2(window_pos.x + 64, window_pos.y);
	if active_move is Attack:
		move_popup.attack_button.show();
	elif (active_move is Wait):
		move_popup.wait_button.show();
	else:
		move_popup.move_button.show();


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
	var ray_origin: Vector3 = camera_controller.project_ray_origin(mouse_pos)
	var ray_direction: Vector3 = camera_controller.project_ray_normal(mouse_pos)
	
	# Cast ray and get intersection point
	var intersection: Vector3 = raycast_to_gridmap(ray_origin, ray_direction)
	if intersection != null:
		# Convert world position to grid coordinates
		var grid_pos: Vector3i = terrain_map.local_to_map(terrain_map.to_local(intersection));
		return grid_pos;
	
	return Vector3i();


func get_tile_name(pos: Vector3) -> String:
	if terrain_map.get_cell_item(pos) == GridMap.INVALID_CELL_ITEM:
		return "null";
	return terrain_map.mesh_library.get_item_name(terrain_map.get_cell_item(pos));


# Expanded the function to do some error searching
func get_unit_name(pos : Vector3) -> String:
	var item_id: int = occupancy_map.get_cell_item(pos)
	if item_id == GridMap.INVALID_CELL_ITEM:
		return "null"
		
	if item_id >= occupancy_map.mesh_library.get_item_list().size():
		push_warning("Invalid MeshLibrary item: " + str(item_id) + " at position: " + str(pos))
		return "null"
	
	return occupancy_map.mesh_library.get_item_name(item_id)


func show_attack_tiles(pos : Vector3i) -> void:
	path_map.clear();
	var reachable : Array[Vector3i] = [];
	
	for move : Move in current_moves:
		reachable.append(move.end_pos);
	
	for tile :Vector3i in MoveGenerator.get_valid_neighbours(pos, reachable):
		path_map.set_cell_item(tile, 0);


func _input(event: InputEvent) -> void:
	if state == States.ANIMATING:
		return;
	if is_in_menu:
		return;
	
	var checkMouseDragging:bool = event is InputEventMouseMotion and is_dragging;
	var checkScreenDragging:bool = false
	#if statement is to fix a runtime bug
	if event is InputEventScreenDrag and event.index >= 1:
		checkScreenDragging = true
	
	if checkMouseDragging or checkScreenDragging:
		#camera lock check is done at screen drag handling elsewhere
		#camera.global_translate(Vector3(-event.relative.x,0,-event.relative.y) / mouse_drag_sensitivity);
		_screen_movement.x += -event.relative.x/mouse_drag_sensitivity
		_screen_movement.y += -event.relative.y/mouse_drag_sensitivity
	
	if event is InputEventMouseButton:
		# Ignore mouse up events
		if lock_camera == false:
			if event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
				Input.mouse_mode = Input.MouseMode.MOUSE_MODE_CAPTURED;
				is_dragging = true;
		if event.pressed == false:
			is_dragging = false;
			Input.mouse_mode = Input.MouseMode.MOUSE_MODE_VISIBLE;
			return;
		
		if is_dragging != false and event.button_index == MOUSE_BUTTON_RIGHT: 
			return;
		if event.button_index != MOUSE_BUTTON_LEFT:
			return;
		
		# Get the tile clicked on
		var pos :Vector3i = get_grid_cell_from_mouse();
		print (pos);
		pos.y = 0;
		
		if state == States.CHOOSING_ATTACK:
			if path_map.get_cell_item(pos) != GridMap.INVALID_CELL_ITEM:
				active_move.end_pos = pos;
				moves_stack.append(active_move);
				
				create_path(moves_stack.front().start_pos, moves_stack.front().end_pos); # a-star used to select how the character moves when move + attack
				state = States.ANIMATING;
			return;
		
		#hide enemy stat display after deselecting them
		if (selected_enemy_unit != null):
			selected_enemy_unit.hide_ui();
			stat_popup_enemy.hide();
			#if selected_unit == null:
			#	stat_popup_player.hide();
		
		if (get_tile_name(pos) == "Water"):
			return
		
		var globalPos: Vector3i = terrain_map.map_to_local(pos)
		cursor.position = Vector3(globalPos.x, cursor.position.y, globalPos.z)
		#map.set_cell(pos, 1);
		#unitsMap.set_cell(pos, 0, Vector2(14,3));
		cursor.show()
		
		var windowPos: Vector2 = Vector2(350,300)
		
		if (get_unit_name(pos) == CharacterStates.Player):
			Tutorial.tutorial_unit_selected()
			unit_pos = pos
			movement_map.clear()
			if (selected_unit == get_unit(pos)):
				active_move = Wait.new(pos)
				show_move_popup(windowPos)
				#show_move_popup(selected_unit.get_unit(pos))
			else:
				if selected_unit != null:
					var character_script: Character = selected_unit
					character_script.hide_ui()
				selected_unit = get_unit(pos)
				ribbon.show()
				ribbon.set_skills(selected_unit.state.skills)
				#ribbon.set_abilities(selected_unit.skills);
				
				current_moves = MoveGenerator.generate(selected_unit, game_state)
				movement_grid.fill_from_commands(current_moves, game_state)
				
				#for command in current_moves:
				#	if command  is Move:
				#		touch(command.end_pos);
				#	if command is Attack:
				#		movement_map.set_cell_item(command.attack_pos, attack_code);
				
				#camera.position.x = selected_unit.position.x;# + 4.5;
				#camera.position.z = selected_unit.position.z + 3.0;#6.5;
				update_stat(selected_unit, stat_popup_player);
		elif (movement_map.get_cell_item(pos) != GridMap.INVALID_CELL_ITEM):
			for i in range(current_moves.size()):
				if current_moves[i] is Attack:
					if current_moves[i].attack_pos == pos:
						active_move = current_moves[i];
				elif current_moves[i].end_pos == pos:
					active_move = current_moves[i];
			
			if active_move is Attack:
				show_attack_tiles(pos);
				state = States.CHOOSING_ATTACK;
			elif active_move is Move:
				moves_stack.append(active_move);
				state = States.ANIMATING;
				create_path(unit_pos, pos); # a-star used for normal character movement
				path_map.clear();
			
			#activeMove.execute();
			
			#unitsMap.set_cell_item(pos, playerCodeDone);
			#unitsMap.set_cell_item(unitPos, -1);
			movement_map.clear();
			#isUnitSelected = false;
		else:
			movement_map.clear();
			path_map.clear();
			
			if selected_unit is Character:
				var character_script: Character = selected_unit;
				character_script.hide_ui();
			
			selected_unit = null;
			
			ribbon.hide();
		
		if (get_unit_name(pos) == CharacterStates.Enemy):
			##select enemy unit for player attack
			selected_enemy_unit = get_unit(pos);
			update_stat(selected_enemy_unit, stat_popup_enemy);
		
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
	Main.camera_controller.camera.make_current()
	camera.clear_current()
	camera = Main.camera_controller.camera
	camera_controller = Main.camera_controller
	camera_controller.setup_minmax_positions(minimum_camera_x, maximum_camera_x, minimum_camera_z, maximum_camera_z)
	camera_controller.springarm_length_maximum = maximum_camera_height
	camera_controller.springarm_length_minimum = minimum_camera_height
	
	cursor.hide()
	trigger_map.hide()
	movement_map.clear()
	occupancy_map.hide()
	path_map.clear()
	fog_map.clear()
	
	terrain_grid = Grid.new(terrain_map)
	occupancy_grid = Grid.new(movement_map)
	trigger_grid = Grid.new(movement_map)
	movement_grid = MovementGrid.new(movement_map)
	path_grid = Grid.new(movement_map)
	fog_grid = Grid.new(fog_map)
	
	ribbon = RIBBON.instantiate();
	add_child(ribbon);
	ribbon.hide();
	
	if (level_name == "first"):
		Dialogic.start(str(level_name) + "Level");
		is_in_menu = true;
	
	Main.battle_log = battle_log;
	
	var units :Array[Vector3i] = occupancy_map.get_used_cells();
	
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
				occupancy_map.set_cell_item(pos, GridMap.INVALID_CELL_ITEM);
		elif (get_unit_name(pos) == "Enemy"):
			new_unit = PLAYER.instantiate()
			
			var data := CharacterData.new()

			var c_state := CharacterState.new()
			c_state.faction = CharacterState.Faction.ENEMY;

			new_unit.data = data
			new_unit.state = c_state
			
			new_unit.data.unit_name = monster_names[randi_range(0, monster_names.size() - 1)];
		elif (get_unit_name(pos) == "Chest"):
			var chest: Node = CHEST.instantiate();
			chest.position = pos * 2;
			chest.position += Vector3(1, 0, 1);
			add_child(chest);
		elif (get_unit_name(pos) == "VictoryTrigger"):
			pass
		else:
			occupancy_map.set_cell_item(pos, GridMap.INVALID_CELL_ITEM);
			
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
	
	stat_popup_player = STATS_POPUP.instantiate()
	stat_popup_player.hide()
	stat_popup_player.scale = Vector2(Main.ui_scale, Main.ui_scale)
	stat_popup_player.position = Vector2(0, -30)

	add_child(stat_popup_player)
	
	stat_popup_enemy = STATS_POPUP.instantiate()
	stat_popup_enemy.hide()
	stat_popup_enemy.scale = Vector2(Main.ui_scale, Main.ui_scale)
	stat_popup_enemy.position = Vector2(get_window().size.x - 155, -30)

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
	path_map.clear()
	movement_grid.fill_from_commands(MoveGenerator.generate(game_state.get_unit(moves_stack.front().start_pos), game_state), game_state)
	
	var path := movement_grid.get_path(start, end)

	for p in path:
		var anim_pos := terrain_map.map_to_local(p)
		anim_pos.y = 0
		animation_path.append(anim_pos)

	selected_unit = get_unit(start)


func reset_all_units() -> void:
	var units :Array[Vector3i] = occupancy_map.get_used_cells();
	for i in units.size():
		var pos :Vector3i = units[i];
		if (occupancy_map.get_cell_item(pos) == player_code_done):
			occupancy_map.set_cell_item(pos, player_code);
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
		camera_controller.focus_camera(selected_unit)
	else:
		camera_controller.free_camera()


func CheckVictoryConditions() -> void:
	var units :Array[Vector3i] = occupancy_map.get_used_cells();
	var numberOfPlayerUnits :int = 0;
	var numberOfEnemyUnits  :int = 0;
	
	for i in units.size():
		var pos :Vector3i = units[i];
		if (occupancy_map.get_cell_item(pos) == player_code || occupancy_map.get_cell_item(pos) == player_code_done):
			numberOfPlayerUnits += 1;
		elif (occupancy_map.get_cell_item(pos) == enemy_code):
			numberOfEnemyUnits += 1;
	
	if (numberOfPlayerUnits == 0):
		get_tree().change_scene_to_file("res://scenes/states/gameover.tscn");
	elif (numberOfEnemyUnits == 0):
		Main.next_level();


func interpolate_to(target_transform:Transform3D, delta:float) -> void:
	#global_transform.origin = global_transform.origin.lerp(
	#	target_transform.origin,
	#	1.0 - exp(-camera_speed * delta)
	#)
	#
	#global_transform.basis = global_transform.basis.slerp(
	#	target_transform.basis,
	#	1.0 - exp(-camera_speed * delta)
	#)
	camera_controller.set_pivot_target_transform(target_transform);


func _process(delta: float) -> void:
	if (turn_transition_animation_player.is_playing()):
		turn_transition.show()
		_screen_movement = Vector2.ZERO
		return;
		
	for i in Main.characters.size():
		update_side_bar(Main.characters[i], side_bar_array[i]);
		
	turn_transition.hide();
	
	if state == States.PLAYING and selected_unit and is_in_menu == false:
		var pos :Vector3i = get_grid_cell_from_mouse();
		pos.y = 0;
		if movement_map.get_cell_item(pos) != GridMap.INVALID_CELL_ITEM:
			path_map.clear()
			var points := movement_grid.get_path(selected_unit.state.grid_position, pos)
			for point in points:
				path_map.set_cell_item(point, 0)
			#a_star(selected_unit.state.grid_position, pos); # a-star for drawing arrow
			if get_unit(pos) is Character and get_unit(pos).state.is_enemy():
				update_stat(get_unit(pos), stat_popup_enemy);
	
	if lock_camera == false:
		var tutorial_camera_moved : bool = false;
		if Input.is_action_pressed("pan_right"):
			#camera.global_translate(Vector3(1,0,0) * camera_speed * delta);
			_screen_movement.x += camera_speed * delta
		if Input.is_action_pressed("pan_left"):
			#camera.global_translate(Vector3(-1,0,0) * camera_speed * delta);
			_screen_movement.x -= camera_speed * delta
		if Input.is_action_pressed("pan_up"):
			#camera.global_translate(Vector3(0,0,-1) * camera_speed * delta);
			_screen_movement.y -= camera_speed * delta
		if Input.is_action_pressed("pan_down"):
			#camera.global_translate(Vector3(0,0,1) * camera_speed * delta);
			_screen_movement.y += camera_speed * delta
		
		camera_controller.add_pivot_translate(Vector3(_screen_movement.x, 0, _screen_movement.y))
		#camera_controller.add_pivot_target_translate(Vector3(_screen_movement.x, 0, _screen_movement.y))
		
		
		#camera.global_translate(Vector3(_screen_movement.x, 0, _screen_movement.y))
		

		
		
		if(_screen_movement != Vector2.ZERO):
			Tutorial.tutorial_camera_moved();
		if Input.is_action_pressed("selected"):
			pass;
	_screen_movement = Vector2.ZERO
	
	if camera.global_position.y > minimum_camera_height:
		if Input.is_action_just_released("zoom_in") or Input.is_action_pressed("zoom_in"):
			#camera.global_position -= camera.global_transform.basis.z * camera_speed * 20 * delta;
			camera_controller.add_springarm_target_length(-camera_speed * 20 * delta)
	if camera.global_position.y < maximum_camera_height:
		if Input.is_action_just_released("zoom_out") or Input.is_action_pressed("zoom_out"):
			#camera.global_position += camera.global_transform.basis.z * camera_speed * 20 * delta;
			camera_controller.add_springarm_target_length(camera_speed * 20 * delta)
	
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
			var units :Array[Vector3i] = occupancy_map.get_used_cells();
			for i in units.size():
				var pos :Vector3i = units[i];
				if (occupancy_map.get_cell_item(pos) == player_code):
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
				#camera_controller.free_camera()
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
			occupancy_map.set_cell_item(active_move.start_pos, GridMap.INVALID_CELL_ITEM);
			occupancy_map.set_cell_item(active_move.end_pos, code);
			selected_unit.move_to(active_move.end_pos);
			selected_unit.pause_anim()
			selected_unit = null;
			completed_moves.append(active_move);
			Tutorial.tutorial_unit_moved();
			
			if is_player_turn == false:
				MoveAI(); # called after an enemy is done moving
			
			if (moves_stack.is_empty() == false):
				#called after any enemy except the final enemy is done moving
				create_path(moves_stack.front().start_pos, moves_stack.front().end_pos); # a-star for enemy animation/movement?
			
			if (animation_path.is_empty() == false):
				#called after any enemy except the final enemy is done moving
				selected_unit.position = animation_path.pop_front();
		# Process animation
		else:
			
			var movement_speed := 10.0 # units per second
			var target : Vector3 = animation_path.front()
			var dir : Vector3 = target - selected_unit.position
			var step := movement_speed * delta
			
			#if the unit is very close to their next footstep in animation
			if dir.length() <= step:
				selected_unit.position = target
				animation_path.pop_front()
			#if the unit is more than a footstep away from the animation target
			#position: move closer and move back to the if statement above
			else:
				selected_unit.position += dir.normalized() * step
				#camera.position.x = selected_unit.position.x;# + 4.5;
				#camera.position.z = selected_unit.position.z + 3.0;#6.5;
				
				if (dir.z > 0):
					selected_unit.play(selected_unit.run_down_animation)
				elif (dir.z < 0):
					selected_unit.play(selected_unit.run_up_animation)
				elif (dir.x > 0):
					selected_unit.play(selected_unit.run_left_animation)
					selected_unit.sprite.flip_h = true
				elif (dir.x < 0):
					selected_unit.play(selected_unit.run_left_animation)
					selected_unit.sprite.flip_h = false
			
			#if(animation_path.is_empty()):
			#	if(!is_player_turn):
			#		camera_controller.free_camera()
			#animated_unit.position.x = animationPath
