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

#### signals 

signal character_selected(character: Character)
signal character_deselected
signal enemy_selected(enemy: Character)
signal enemy_deselected

signal character_stats_changed(character: Character)
signal party_updated(characters: Array[Character])





@onready var combat_vfx : CombatVFXController = $CombatVFXController

@export var level_name :String

var terrain_grid : Grid
var path_grid : Grid
var occupancy_grid : Grid
var trigger_grid : Grid
var fog_grid : Grid
var movement_grid : MovementGrid
var movement_weights_grid : Grid

@onready var battle_log: Label = $BattleLog


@onready var cursor: Sprite3D = $Cursor
@onready var terrain_map: GridMap = %TerrainGrid
@onready var occupancy_map: GridMap = %OccupancyOverlay
@onready var movement_map: GridMap = %MovementOverlay
@onready var movement_weights_map: GridMap = %MovementWeightsGrid
@onready var trigger_map: GridMap = %TriggerOverlay
@onready var path_map: GridMap = $PathOverlay
@onready var fog_map: GridMap = $FogOverlay
@onready var turn_transition: CanvasLayer = $TurnTransition/CanvasLayer
@onready var turn_transition_animation_player: AnimationPlayer = $TurnTransition/AnimationPlayer

@onready var player_label: Label = $TurnTransition/CanvasLayer/VBoxContainer/ColorRect3/playerLabel
@onready var enemy_label: Label = $TurnTransition/CanvasLayer/VBoxContainer/ColorRect3/enemyLabel



var selected_unit: Character = null
var selected_enemy_unit: Character = null
var move_popup: Control;
#var stat_popup_player: Control;
#var side_bar_array : Array[SideBar];
#var stat_popup_enemy: Control;
var completed_moves :Array[Command];

var characters: Array[Character];

const GAME_UI = preload("res://scenes/userinterface/InGameUI_WIP.tscn")

const STATS_POPUP = preload("res://scenes/userinterface/pop_up.tscn")
const MOVE_POPUP = preload("res://scenes/userinterface/move_popup.tscn")
const CHEST = preload("res://scenes/grid_items/chest.tscn")
const SIDE_BAR = preload("res://scenes/userinterface/sidebar.tscn")
#const RIBBON: PackedScene = preload("res://scenes/userinterface/ribbon.tscn");
const PLAYER: PackedScene = preload("res://scenes/Characters/alfred.tscn");
const BIRD_ENEMY: PackedScene  = preload("res://scenes/Characters/bird.tscn")
const GHOST_ENEMY: PackedScene  = preload("res://scenes/Characters/Ghost_Enemy.tscn")

var animation_path :Array[Vector3];
var is_animation_just_finished :bool = false;

enum States {
	PLAYING,
	ANIMATING,
	TRANSITION,
	CHOOSING_ATTACK };
var state :int = States.PLAYING;
var game_state : GameState;

var is_in_menu: bool = false
var active_move: Command
var moves_stack: Array

var current_moves: Array[Command]
var is_player_turn: bool = true
var unit_pos: Vector3
var player_code: int = 0
var player_code_done: int = 3
var enemy_code: int = 1
var attack_code: int = 0
var move_code: int = 1

var is_using_ability: bool = false

var is_enemy_turn: bool = false

#region Camera
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
	"Sec'Mat",
	"Unfinished projects",
	"d'ave",
	"mar'k"
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


#fens kinda wonky grid to world transform that might be crap
func grid_to_world(pos: Vector3i) -> Vector3:
	var world:= terrain_map.map_to_local(pos)
	return world


func get_selectable_characters() -> Array[Character]:
	var result: Array[Character] =[]
	for c in characters:
		if not is_instance_valid(c):
			continue
		if c.state.faction != CharacterState.Faction.PLAYER:
			continue
		#if c.state.is_dead:
			#continue
		result.append(c)
	return result


func select_next_character() -> void:
	var list := get_selectable_characters()
	if list.is_empty():
		return

	if selected_unit == null:
		try_select_unit(list[0])
		return
	var index := list.find(selected_unit)
	if index == -1:
		try_select_unit(list[0])
		return

	var next_index := (index + 1) % list.size()
	try_select_unit(list[next_index])


func get_grid_cell_from_mouse() -> Vector3i:
	var mouse_pos: Vector2 = get_viewport().get_mouse_position()
	var ray_origin: Vector3 = camera_controller.project_ray_origin(mouse_pos)
	var ray_dir: Vector3 = camera_controller.project_ray_normal(mouse_pos).normalized()

	var max_distance: float = 100.0
	var step: float = 0.1
	var distance: float = 0.0

	var cell_size: Vector3 = movement_weights_map.cell_size
	var best_cell: Vector3i
	var is_best_cell := false

	while distance < max_distance:
		var check_pos: Vector3 = ray_origin + ray_dir * distance

		# Convert world position to GridMap cell coordinates
		var x: int = int(floor(check_pos.x / cell_size.x))
		var y: int = int(floor(check_pos.y / cell_size.y))
		var z: int = int(floor(check_pos.z / cell_size.z))
		var candidate: Vector3i = Vector3i(x, y, z)

		if movement_weights_map.get_used_cells().has(candidate):
			best_cell = candidate
			is_best_cell = true
			break

		distance += step

	
	if is_best_cell != false:
		return best_cell

	return Vector3i(-999,-999,-999)  # fallback


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
		push_warning("Invalid Unit MeshLibrary item: " + str(item_id) + " at position: " + str(pos))
		return "null"
	
	return occupancy_map.mesh_library.get_item_name(item_id)

func get_trigger_name(pos : Vector3) -> String:
	var trigger_id: int = trigger_map.get_cell_item(pos)
	if trigger_id == GridMap.INVALID_CELL_ITEM:
		return "null"
	
	if trigger_id >= trigger_map.mesh_library.get_item_list().size():
		push_warning("Invalid Trigger MeshLibrary item: " + str(trigger_id) + " at position: " + str(pos))
		return "null"
	
	return trigger_map.mesh_library.get_item_name(trigger_id)

func show_attack_tiles(pos: Vector3i) -> void:
	path_map.clear()

	var reachable: Array[Vector3i] = []

	# Collect all MOVE destinations (possible attack origins)
	for cmd in current_moves:
		if cmd is Move:
			reachable.append(cmd.end_pos)

	# Include standing still as an origin
	reachable.append(selected_unit.state.grid_position)

	# Generate attack tiles
	var tiles := MoveGenerator.get_attack_origins(
		selected_unit,
		game_state,
		pos,
		reachable
	)

	for tile: Vector3i in tiles:
		path_map.set_cell_item(tile, 0)


func _can_handle_input(event: InputEvent) -> bool:
	##old
	#if get_grid_cell_from_mouse() == Vector3i(INF, INF, INF):
		#return false
	if not is_player_turn:
		return false
	
	if state == States.ANIMATING:
		return false

	if is_in_menu:
		return false

	if not (event is InputEventMouseButton):
		return false

	if event.button_index != MOUSE_BUTTON_LEFT:
		return false

	if not event.pressed:
		return false

	if Input.is_action_pressed("enable_dragging"):
		return false
	
	if get_grid_cell_from_mouse() == Vector3i(-999, -999, -999):
		_clear_selection();
		return false

	return true


func _update_cursor(pos: Vector3i) -> void:
	var world_pos := grid_to_world(pos)
	cursor.position = Vector3(world_pos.x, world_pos.y + 0.1, world_pos.z)
	cursor.show()


func _handle_attack_choice(pos: Vector3i) -> void:
	if path_map.get_cell_item(pos) == GridMap.INVALID_CELL_ITEM:
		return

	active_move.end_pos = pos
	moves_stack.append(active_move)

	create_path(
		moves_stack.front().start_pos,
		moves_stack.front().end_pos
	)

	state = States.ANIMATING


func _is_invalid_tile(pos: Vector3i) -> bool:
	return get_tile_name(pos) == "Water"


func can_handle_ui_input() -> bool:
		return(
			is_player_turn
			and state == States.PLAYING
			and not is_in_menu
		)
		
func try_select_unit(unit: Character) -> void:
	if not can_handle_ui_input():
		return
	
	select_unit(unit)
	
func select_unit(unit: Character) -> void:
	# Switching unit
	_clear_selection()

	selected_unit = unit
	unit_pos = unit.state.grid_position
	_update_cursor(unit.state.grid_position)
	emit_signal("character_selected", selected_unit)

	current_moves = MoveGenerator.generate(selected_unit, game_state)
	movement_grid.fill_from_commands(current_moves, game_state)


func _handle_player_click(pos: Vector3i) -> void:
	# Heal execution shortcut
	if selected_unit == null:
		Tutorial.tutorial_unit_selected()

	unit_pos = pos
	movement_map.clear()

	# Same unit clicked again
	if selected_unit == get_unit(pos):
		active_move = Wait.new(pos)
		show_move_popup(get_viewport().get_mouse_position())
		return

	select_unit(get_unit(pos))


func _handle_action_tile_click(pos: Vector3i) -> void:
	active_move = null

	var found_move : Move = null
	var found_attack : Attack = null

	for cmd in current_moves:
		if cmd is Move and cmd.end_pos == pos:
			found_move = cmd
		elif cmd is Attack and cmd.attack_pos == pos:
			found_attack = cmd

	# MOVE HAS PRIORITY
	if found_move != null:
		active_move = found_move

		moves_stack.append(active_move)
		state = States.ANIMATING
		create_path(unit_pos, pos)
		path_map.clear()

	elif found_attack != null:
		active_move = found_attack

		show_attack_tiles(pos)
		state = States.CHOOSING_ATTACK

	movement_map.clear()


func _clear_selection() -> void:
	emit_signal("character_deselected")
	emit_signal("enemy_deselected")
	movement_map.clear()
	path_map.clear()
	selected_unit = null


func _handle_abilities(pos: Vector3i) -> bool:
	if is_using_ability:
		if movement_map.get_cell_item(pos) != GridMap.INVALID_CELL_ITEM:
			for cmd: Heal in current_moves:
				if cmd.end_pos == pos:
					cmd.execute(game_state)
					is_using_ability = false
					selected_unit.state.is_moved = true
					get_unit(pos).update_health_bar()
					movement_map.clear()
					return true
	return false

#_input is always handled first, then UI, then Unhandled input
#(use property mouse_filter: Stop to let ui steal input, use Ignore to not let UI steal input! always remember to change these on UI nodes when they are created)
func _input(event: InputEvent) -> void:
	if event is InputEventKey:
		if event.pressed:
			if event.keycode == KEY_TAB:
				select_next_character()


func _unhandled_input(event: InputEvent) -> void:
	if not _can_handle_input(event):
		return
	
	var pos: Vector3i = get_grid_cell_from_mouse()
	print(pos)
	
	if _handle_abilities(pos):
		return

	_update_cursor(pos)

	# Attack selection phase
	if state == States.CHOOSING_ATTACK:
		_handle_attack_choice(pos)
		return

	if _is_invalid_tile(pos):
		return

	# Player unit clicked
	if get_unit_name(pos) == CharacterStates.Player:
		_handle_player_click(pos)
		return

	# Clicked on movement/attack tile
	if movement_map.get_cell_item(pos) != GridMap.INVALID_CELL_ITEM:
		_handle_action_tile_click(pos)
		return

	# Clicked empty tile
	_clear_selection()

	# Enemy clicked (for info panel)
	if get_unit(pos) and get_unit(pos).state.faction == CharacterState.Faction.ENEMY:
		selected_enemy_unit = get_unit(pos)
		emit_signal("enemy_selected", selected_enemy_unit)
		print("hey an enemy has been selected ")


func _ready() -> void:
	camera_controller = Main.camera_controller
	

	cursor.hide()
	trigger_map.hide()
	movement_map.clear()
	movement_weights_map.hide()
	occupancy_map.hide()
	path_map.clear()
	fog_map.clear()

	terrain_grid = Grid.new(terrain_map)
	occupancy_grid = Grid.new(movement_map)
	trigger_grid = Grid.new(movement_map)
	movement_grid = MovementGrid.new(movement_map)
	movement_weights_grid = Grid.new(movement_weights_map)
	path_grid = Grid.new(movement_map)
	fog_grid = Grid.new(fog_map)

	if level_name == "first":
		Dialogic.start(level_name + "Level")
		is_in_menu = true
	elif level_name == "Fen":
		Dialogic.start("Showcase_Intro")
		is_in_menu = true

	Main.battle_log = battle_log

	var units: Array[Vector3i] = occupancy_map.get_used_cells()
	var characters_placed := 0

	print("Loading new level, number of playable characters: ", Main.characters.size())

	for i in range(units.size()):
		var pos: Vector3i = units[i]
		var new_unit: Character = null

		match get_unit_name(pos):
			"00_Unit":
				if characters_placed < Main.characters.size():
					new_unit = Main.characters[characters_placed]
					new_unit.state.is_moved = false
					new_unit.camera = get_viewport().get_camera_3d()
					characters_placed += 1

					var health := new_unit.state.current_health
					print(
						"This character exists: ",
						new_unit.data.unit_name,
						" health: ",
						health if health > 0 else "fresh unit"
					)
				else:
					occupancy_map.set_cell_item(pos, GridMap.INVALID_CELL_ITEM)

			"01_Enemy", "04_EnemyBird", "05_EnemyGhost", "06_EnemyMonster":
				new_unit = (
					BIRD_ENEMY.instantiate() if get_unit_name(pos) == "04_EnemyBird"
					else GHOST_ENEMY.instantiate() if get_unit_name(pos) == "05_EnemyGhost"
					else PLAYER.instantiate()
				)

				var data := CharacterData.new()
				var c_state := CharacterState.new()
				c_state.faction = CharacterState.Faction.ENEMY

				new_unit.data = data
				new_unit.state = c_state
				new_unit.data.unit_name = monster_names.pick_random()

			"02_Chest":
				var chest := CHEST.instantiate()
				chest.position = grid_to_world(pos)
				add_child(chest)


			_:
				occupancy_map.set_cell_item(pos, GridMap.INVALID_CELL_ITEM)

		if new_unit:
			new_unit.position = grid_to_world(pos)

			if new_unit.get_parent() != Main.world:
				Main.world.add_child(new_unit)

			characters.append(new_unit)

			if new_unit is Character:
				new_unit.state.grid_position = pos
				new_unit.sanity_flipped.connect(_on_character_sanity_flipped)

	move_popup = MOVE_POPUP.instantiate()
	move_popup.hide()
	add_child(move_popup)
	
	game_state = GameState.from_level(self)
	
	turn_transition_animation_player.play()
	add_to_group("level")

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
		var anim_pos := grid_to_world(p)
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
		var move : Command = ai.choose_best_move(current_state, 1);
		moves_stack.append(move);
		current_state = current_state.apply_move(move, true);
	
	if (moves_stack.is_empty() == false):
		create_path(moves_stack.front().start_pos, moves_stack.front().end_pos); # a-star for pathfinding AI
		state = States.ANIMATING;
		camera_controller.focus_camera(selected_unit)
	else:
		camera_controller.set_pivot_target_translate(Main.characters.front().position)
		camera_controller.free_camera()


func CheckVictoryConditions() -> void:
	var units :Array[Vector3i] = occupancy_map.get_used_cells();
	var numberOfPlayerUnits :int = 0;
	var numberOfEnemyUnits  :int = 0;
	
	for i in units.size():
		var pos :Vector3i = units[i];
		if (occupancy_map.get_cell_item(pos) == player_code || occupancy_map.get_cell_item(pos) == player_code_done):
			if get_trigger_name(pos) == "00_Victory":
				is_player_turn = true;
				next_level();
				return;
			numberOfPlayerUnits += 1;
			
		elif (occupancy_map.get_cell_item(pos) >= enemy_code):
			numberOfEnemyUnits += 1;
	
	if (numberOfPlayerUnits == 0):
		get_tree().change_scene_to_file("res://scenes/states/gameover.tscn");
	elif (numberOfEnemyUnits == 0):
		is_player_turn = true;
		next_level();
		return;

##Removing unwanted occupants and resetting movement of characters
func next_level() -> void:
	var positions : Array[Vector3i] = occupancy_map.get_used_cells();
	for i in positions.size():
		##occupancy_map 0 == Unit, 3 == UnitDone
		if occupancy_map.get_cell_item(positions[i]) == 3 || occupancy_map.get_cell_item(positions[i]) == 0:
			get_unit(positions[i]).reset();
			get_unit(positions[i]).state.grid_position = Vector3i(0, 0, 0)

		##Remove all other occupants, since they should not be in the next level
		else:
			get_unit(positions[i]).die(false)
	
	Main.next_level()

func _on_character_sanity_flipped(character: Character) -> void:
	print("heyaaa, we just flipped sanity")
	emit_signal("character_stats_changed", character)
	#characters.erase(character)
	
	

func interpolate_to(target_transform:Transform3D, delta:float) -> void:
	camera_controller.set_pivot_target_transform(target_transform)


func _process(delta: float) -> void:
	_process_old(delta)
	return
	
	# FUTURE:
	match state:
		States.PLAYING:
			process_playing(delta)
		States.ANIMATING:
			process_animating(delta)
		States.TRANSITION:
			process_transition(delta)


func process_playing(delta: float) -> void:
	pass


func process_animating(delta: float) -> void:
	pass


func process_transition(delta: float) -> void:
	pass


func get_screen_position(sprite: Sprite3D) -> Vector2:
	var camera := get_viewport().get_camera_3d()
	if not camera:
		return Vector2.ZERO

	if camera.is_position_behind(sprite.global_position):
		return Vector2(-9999, -9999) # or hide UI

	return camera.unproject_position(sprite.global_position)


func _process_old(delta: float) -> void:
	if (turn_transition_animation_player.is_playing()):
		turn_transition.show()
		camera_controller.lock_camera()
		return;
	if(!combat_vfx.is_finished()):
		return
	#for i in Main.characters.size():
		#update_side_bar(Main.characters[i], side_bar_array[i]);
		
	turn_transition.hide();
	camera_controller.unlock_camera()
	
	if state == States.PLAYING and selected_unit and is_in_menu == false:
		var pos :Vector3i = get_grid_cell_from_mouse();
		if movement_map.get_cell_item(pos) != GridMap.INVALID_CELL_ITEM:
			path_map.clear()
			var points := movement_grid.get_path(selected_unit.state.grid_position, pos)
			for point in points:
				path_map.set_cell_item(point, 0)
			#a_star(selected_unit.state.grid_position, pos); # a-star for drawing arrow
			#if get_unit(pos) is Character and get_unit(pos).state.is_enemy():
			#	update_stat(get_unit(pos), stat_popup_enemy);
	
	if (is_in_menu):
		return;
	
	CheckVictoryConditions();
	
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
		# Done with one move, execute it and start on next
		elif (animation_path.is_empty()):
			active_move = moves_stack.pop_front();
			#if get_trigger_name(active_move.end_pos) == "Victory":
				#next_level();
				##Dialogic.start(level_name + "LevelVictory")



			active_move.prepare(game_state)
			await combat_vfx.play_attack(active_move.result)
			active_move.apply_damage(game_state)
			
			#looks like this is end of player turn! 
			if is_player_turn:
				active_move = Wait.new(active_move.end_pos)
				show_move_popup(get_screen_position(selected_unit.sprite))
				for character in characters:
					if characters == null: 
						return
					emit_signal("character_stats_changed", character)
			
			var code := enemy_code;
			if is_player_turn:
				code = player_code_done;
			occupancy_map.set_cell_item(active_move.start_pos, GridMap.INVALID_CELL_ITEM);
			occupancy_map.set_cell_item(active_move.end_pos, code);
			selected_unit.move_to(active_move.end_pos);
			selected_unit.pause_anim()
			camera_controller.free_camera()
			_clear_selection()

			completed_moves.append(active_move);
			Tutorial.tutorial_unit_moved();
			
			if is_player_turn == false:
				MoveAI(); # called after an enemy is done moving
				for character in Main.characters:
					if characters == null: 
						return
					emit_signal("character_stats_changed", character)

			
			if (moves_stack.is_empty() == false):
				#called after any enemy except the final enemy is done moving
				create_path(moves_stack.front().start_pos, moves_stack.front().end_pos); # a-star for enemy animation/movement?
			
			if (animation_path.is_empty() == false):
				#called after any enemy except the final enemy is done moving
				selected_unit.position = animation_path.pop_front();
		# Process animation
		else:
			var movement_speed := 8.0 # units per second
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
				
				if (dir.z > 0):
					selected_unit.play(selected_unit.run_down_animation)
				elif (dir.z < 0):
					selected_unit.play(selected_unit.run_up_animation)
				elif (dir.x > 0):
					selected_unit.play(selected_unit.run_right_animation)
				elif (dir.x < 0):
					selected_unit.play(selected_unit.run_left_animation)
