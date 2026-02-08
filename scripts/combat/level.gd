extends Node3D
class_name Level
## Map logic for combat levels.
##
## input handling, game flow
# TODO: Stackable tiles for enemies
# TODO: Make your own units passable
# TODO: camp?
# TODO: Make enemies able to occopy several grid-tiles

#region Signals
signal character_selected(character: Character)
signal character_deselected
signal character_stats_changed(character: Character)
signal party_updated(characters: Array[Character])
#endregion

@onready var combat_vfx : CombatVFXController = $CombatVFXController
@export var level_name :String

var movement_grid: MovementGrid
var terrain: Grid
var occupancy_grid: Grid
var fog_grid: Grid

@onready var battle_log: Label = $BattleLog


@onready var cursor: Sprite3D = $Cursor
@onready var occupancy_overlay: GridMap = %OccupancyOverlay
@onready var ui_overlay: GridMap = %UIOverlay
@onready var movement_weights_grid: GridMap = %MovementWeightsGrid
@onready var fog_overlay: GridMap = $FogOverlay
@onready var turn_transition: CanvasLayer = $TurnTransition/CanvasLayer
@onready var turn_transition_animation_player: AnimationPlayer = $TurnTransition/AnimationPlayer

@onready var player_label: Label = $TurnTransition/CanvasLayer/VBoxContainer/ColorRect3/playerLabel
@onready var enemy_label: Label = $TurnTransition/CanvasLayer/VBoxContainer/ColorRect3/enemyLabel

var move_popup: Control;
var completed_moves :Array[Command];

var characters: Array[Character];

#region Scenes
const GAME_UI = preload("res://scenes/userinterface/InGameUI_WIP.tscn")
const STATS_POPUP = preload("res://scenes/userinterface/pop_up.tscn")
const MOVE_POPUP = preload("res://scenes/userinterface/move_popup.tscn")
const CHEST = preload("res://scenes/grid_items/chest.tscn")
const SIDE_BAR = preload("res://scenes/userinterface/sidebar.tscn")
#const RIBBON: PackedScene = preload("res://scenes/userinterface/ribbon.tscn");
const PLAYER: PackedScene = preload("res://scenes/grid_items/alfred.tscn");
const BIRD_ENEMY: PackedScene  = preload("res://scenes/grid_items/bird.tscn")
const GHOST_ENEMY: PackedScene  = preload("res://scenes/grid_items/Ghost_Enemy.tscn")
#endregion

enum States
{
	PLAYING,
	ANIMATING,
	TRANSITION,
	CHOOSING_ATTACK
};

var state :int = States.PLAYING;
var game_state : GameState;

var is_in_menu: bool = false

#region Camera
var camera_controller : CameraController

@export var minimum_camera_height: float = 3.0
@export var maximum_camera_height: float = 15.0

@export var minimum_camera_x: float = -10.0
@export var maximum_camera_x: float = 100.0
@export var minimum_camera_z: float = -10.0
@export var maximum_camera_z: float = 10.0
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


func animate_diff(a: GameState, b: GameState) -> void:
	for unit_a in a.units:
		var unit_b := b.get_unit(unit_a.state.id)
		if unit_a.state.grid_position != unit_b.state.grid_position:
			animate_move(unit_b)


func animate_move(unit: Character) -> void:
	pass


func show_move_popup(window_pos :Vector2) -> void:
	move_popup.show()
	is_in_menu = true
	move_popup.position = Vector2(window_pos.x + 64, window_pos.y)
	move_popup.move_button.show()


func raycast_to_gridmap(origin: Vector3, direction: Vector3) -> Vector3:
	var space_state: PhysicsDirectSpaceState3D = get_world_3d().direct_space_state
	var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(
		origin,
		origin + direction * 1000.0
		)

	var result: Dictionary = space_state.intersect_ray(query)
	if result:
		return result.position
	return Vector3()


func grid_to_world(pos: Vector3i) -> Vector3:
	var world := ui_overlay.map_to_local(pos)
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

	#if selected_unit == null:
	#	select_unit(list[0])
	#	return
	#var index := list.find(selected_unit)
	#if index == -1:
	#	select_unit(list[0])
	#	return

	#var next_index := (index + 1) % list.size()
	#select_unit(list[next_index])


func get_grid_cell_from_mouse() -> Vector3i:
	var mouse_pos: Vector2 = get_viewport().get_mouse_position()
	var ray_origin: Vector3 = camera_controller.project_ray_origin(mouse_pos)
	var ray_dir: Vector3 = camera_controller.project_ray_normal(mouse_pos).normalized()

	var max_distance: float = 100.0
	var step: float = 0.1
	var distance: float = 0.0

	var cell_size: Vector3 = movement_weights_grid.cell_size
	var best_cell: Vector3i
	var is_best_cell := false

	while distance < max_distance:
		var check_pos: Vector3 = ray_origin + ray_dir * distance

		# Convert world position to GridMap cell coordinates
		var x: int = int(floor(check_pos.x / cell_size.x))
		var y: int = int(floor(check_pos.y / cell_size.y))
		var z: int = int(floor(check_pos.z / cell_size.z))
		var candidate: Vector3i = Vector3i(x, y, z)

		if movement_weights_grid.get_used_cells().has(candidate):
			best_cell = candidate
			is_best_cell = true
			break

		distance += step

	if is_best_cell != false:
		return best_cell

	return Vector3i(INF,INF,INF)  # fallback


func _can_handle_input(event: InputEvent) -> bool:
	if get_grid_cell_from_mouse() == Vector3i(INF, INF, INF):
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

	return true


func _update_cursor(pos: Vector3i) -> void:
	var world_pos := grid_to_world(pos)
	cursor.position = Vector3(world_pos.x, cursor.position.y, world_pos.z)
	cursor.show()


func select_unit(unit: Character) -> void:
	# Switching unit
	_clear_selection()
	
	_update_cursor(unit.state.grid_position)
	emit_signal("character_selected", unit)

	var current_moves := MoveGenerator.generate(unit, game_state)
	movement_grid.fill_from_commands(current_moves, game_state)


func _handle_player_click(pos: Vector3i) -> void:
	Tutorial.tutorial_unit_selected()
	select_unit(game_state.get_unit(pos))


func _handle_action_tile_click(pos: Vector3i) -> void:
	var found_move : Move = null
	var found_attack : Attack = null

	#for cmd in current_moves:
	#	if cmd is Move and cmd.end_pos == pos:
	#		found_move = cmd
	#	elif cmd is Attack and cmd.attack_pos == pos:
	#		found_attack = cmd

	# MOVE HAS PRIORITY
	#if found_move != null:
	#	active_move = found_move

	#	moves_stack.append(active_move)
	#	state = States.ANIMATING
	#	create_path(unit_pos, pos)
	#	path_map.clear()

	#elif found_attack != null:
	#	active_move = found_attack

	#	show_attack_tiles(pos)
	#	state = States.CHOOSING_ATTACK

	#movement_map.clear()


func _clear_selection() -> void:
	emit_signal("character_deselected")


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

	_update_cursor(pos)

	# Attack selection phase
	#if state == States.CHOOSING_ATTACK:
	#	_handle_attack_choice(pos)
	#	return

	#if _is_invalid_tile(pos):
	#	return

	# Player unit clicked
	#if get_unit_name(pos) == CharacterStates.Player:
	#	_handle_player_click(pos)
	#	return

	# Clicked on movement/attack tile
	#if movement_map.get_cell_item(pos) != GridMap.INVALID_CELL_ITEM:
	#	_handle_action_tile_click(pos)
	#	return

	# Clicked empty tile
	_clear_selection()

	# Enemy clicked (for info panel)
	#if get_unit_name(pos) == CharacterStates.Enemy:
	#	selected_enemy_unit = get_unit(pos)


func get_unit_name(pos : Vector3) -> String:
	var item_id: int = occupancy_overlay.get_cell_item(pos)
	if item_id == GridMap.INVALID_CELL_ITEM:
		return "null"
		
	if item_id >= occupancy_overlay.mesh_library.get_item_list().size():
		push_warning("Invalid MeshLibrary item: " + str(item_id) + " at position: " + str(pos))
		return "null"
	
	return occupancy_overlay.mesh_library.get_item_name(item_id)


func _ready() -> void:
	camera_controller = Main.camera_controller
	camera_controller.make_current()
	camera_controller.setup_minmax_positions(
		minimum_camera_x,
		maximum_camera_x,
		minimum_camera_z,
		maximum_camera_z
	)
	camera_controller.springarm_length_maximum = maximum_camera_height
	camera_controller.springarm_length_minimum = minimum_camera_height
	camera_controller.free_camera()

	cursor.hide()
	movement_weights_grid.hide()
	occupancy_overlay.hide()

	occupancy_grid = Grid.new(ui_overlay)
	fog_grid = Grid.new(fog_overlay)
	
	if level_name == "first":
		Dialogic.start(level_name + "Level")
		is_in_menu = true
	elif level_name == "Fen":
		Dialogic.start("Showcase_Intro")
		is_in_menu = true

	Main.battle_log = battle_log

	var units: Array[Vector3i] = occupancy_overlay.get_used_cells()
	var characters_placed := 0

	print("Loading new level, number of playable characters: ", Main.characters.size())

	for i in range(units.size()):
		var pos: Vector3i = units[i]
		var new_unit: Character = null

		match get_unit_name(pos):
			"Unit":
				if characters_placed < Main.characters.size():
					new_unit = Main.characters[characters_placed]
					new_unit.state.phase = CharacterState.UnitPhase.READY
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
					occupancy_overlay.set_cell_item(pos, GridMap.INVALID_CELL_ITEM)

			"Enemy", "EnemyBird", "EnemyGhost":
				new_unit = (
					BIRD_ENEMY.instantiate() if get_unit_name(pos) == "EnemyBird"
					else GHOST_ENEMY.instantiate() if get_unit_name(pos) == "EnemyGhost"
					else PLAYER.instantiate()
				)

				var data := CharacterData.new()
				var c_state := CharacterState.new()
				c_state.faction = CharacterState.Faction.ENEMY

				new_unit.data = data
				new_unit.state = c_state
				new_unit.data.unit_name = monster_names.pick_random()

			"Chest":
				var chest := CHEST.instantiate()
				chest.position = grid_to_world(pos)
				add_child(chest)

			"VictoryTrigger":
				pass

			_:
				occupancy_overlay.set_cell_item(pos, GridMap.INVALID_CELL_ITEM)

		if new_unit:
			new_unit.position = grid_to_world(pos)

			if new_unit.get_parent() != Main.world:
				Main.world.add_child(new_unit)

			characters.append(new_unit)

			if new_unit is Character:
				new_unit.state.grid_position = pos

	move_popup = MOVE_POPUP.instantiate()
	move_popup.hide()
	add_child(move_popup)

	game_state = GameState.from_level(self)

	turn_transition_animation_player.play()

	add_to_group("level")
	emit_signal("party_updated", characters)


func MoveAI() -> void:
	var ai := MinimaxAI.new();
	var current_state := GameState.from_level(self);
	
	if current_state.has_enemy_moves():
		var move : Command = ai.choose_best_move(current_state, 2);
		current_state = current_state.apply_move(move, true);


func CheckVictoryConditions() -> void:
	if game_state.get_legal_moves().is_empty():
		if game_state.is_current_player_enemy:
			get_tree().change_scene_to_file("res://scenes/states/gameover.tscn")
		else:
			get_tree().change_scene_to_file("res://scenes/states/victory.tscn")


func interpolate_to(target_transform:Transform3D, delta:float) -> void:
	camera_controller.set_pivot_target_transform(target_transform)


func _process(delta: float) -> void:
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
