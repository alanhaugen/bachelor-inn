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
signal ability_used
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
@onready var ui_overlay: GridMap = %TerrainGrid
@onready var occupancy_overlay: GridMap = %OccupancyOverlay
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
var active_skill: Skill = null
var skill_caster: Character = null ## The one using ability
var is_choosing_skill_target: bool = false
var valid_skill_target_tiles: Dictionary = {} ## For abilities/spells
var move_popup: MovePopup;
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
const PLAYER: PackedScene = preload("res://scenes/Characters/alfred.tscn");
const BIRD_ENEMY: PackedScene  = preload("res://scenes/Characters/bird.tscn")
const GHOST_ENEMY: PackedScene  = preload("res://scenes/Characters/Ghost_Enemy.tscn")
const HORROR_ENEMY: PackedScene = preload("res://scenes/Characters/Horror_Scene.tscn")
const CORRUPTED_PLAYER_RED: PackedScene = preload("res://scenes/Characters/Char_Corrupted_Player_Orange.tscn")

var animation_path :Array[Vector3];
var is_animation_just_finished :bool = false;

const States = CampaignState.LevelState

var state: States:
	get: return Main.campaign.level_state
	set(v): Main.campaign.level_state = v

var is_player_turn: bool:
	get: return Main.campaign.is_player_turn
	set(v): Main.campaign.is_player_turn = v

var game_state: GameState

var is_in_menu: bool = false
var active_move: Command
var moves_stack: Array[Command]
var _is_processing_move: bool = false

var current_moves: Array[Command]
var unit_pos: Vector3
var player_code: int = 0
var player_code_done: int = 3
var enemy_code: int = 1
var attack_code: int = 0
var move_code: int = 1

var is_enemy_turn: bool = false
var skill_target_code: int = 0

#region Camera
var camera_controller : CameraController
const post_enemy_move_wait : float = 0.1
const post_enemy_attack_wait : float = 0.4
const pre_enemy_turn_wait : float = 0.2
var wait_timer : float = 0.0
@onready var timer : Timer = $Timer
var wait_for_camera : bool = false
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
	"mar'k",
	"Cringe Memory",
]


func animate_diff(a: GameState, b: GameState) -> void:
	for unit_a in a.units:
		var unit_b := b.get_unit(unit_a.state.id)
		if unit_a.state.grid_position != unit_b.state.grid_position:
			animate_move(unit_b)


func animate_move(unit: Character) -> void:
	# Start movement animation for the unit to its new position
	var start := unit.state.grid_position # This is old pos if unit_b has new pos? 
	# Wait, unit_b in animate_diff is the unit from state b.
	# If I want to animate from a to b, I need the positions.
	pass


func show_move_popup(window_pos :Vector2) -> void:
	move_popup.show()
	is_in_menu = true
	move_popup.position = Vector2(window_pos.x + 64, window_pos.y)
	
	if selected_unit:
		move_popup.add_abilities(selected_unit)
	
	if active_move is Wait:
		move_popup.get_node(^"VBoxContainer/PassButton").show()
		move_popup.get_node(^"VBoxContainer/UndoButton").show()
	else:
		#move_popup.get_node(^"VBoxContainer/MoveButton").show()
		move_popup.get_node(^"VBoxContainer/WaitButton").show()
		move_popup.get_node(^"VBoxContainer/UndoButton").show()
		
		# Show attack button if there is an enemy in range from current position
		if selected_unit and selected_unit.state.weapon:
			var min_r := selected_unit.state.weapon.min_range
			var max_r := selected_unit.state.weapon.max_range
			if MoveGenerator._has_enemy_in_range_from_origin(selected_unit.state.grid_position, min_r, max_r, selected_unit, game_state):
				move_popup.get_node(^"VBoxContainer/AttackButton").show()
			else:
				move_popup.get_node(^"VBoxContainer/AttackButton").hide()
		else:
			move_popup.get_node(^"VBoxContainer/AttackButton").hide()


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
	var world:= ui_overlay.map_to_local(pos)
	return world


func get_selectable_characters() -> Array[Character]:
	var result: Array[Character] =[]
	for c in characters:
		if not is_instance_valid(c):
			continue
		if c.state.faction != CharacterState.Faction.PLAYER:
			continue
		if c.state.is_ability_used:
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

	return Vector3i(2147483647, 2147483647, 2147483647)  # fallback


func get_tile_name(pos: Vector3) -> String:
	if ui_overlay.get_cell_item(pos) == GridMap.INVALID_CELL_ITEM:
		return "null";
	return ui_overlay.mesh_library.get_item_name(ui_overlay.get_cell_item(pos));


# Expanded the function to do some error searching
func get_unit_name(pos : Vector3) -> String:
	var item_id: int = occupancy_overlay.get_cell_item(pos)
	if item_id == GridMap.INVALID_CELL_ITEM:
		return "null"
		
	if item_id >= occupancy_overlay.mesh_library.get_item_list().size():
		push_warning("Invalid Unit MeshLibrary item: " + str(item_id) + " at position: " + str(pos))
		return "null"
	
	return occupancy_overlay.mesh_library.get_item_name(item_id)

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
	if get_grid_cell_from_mouse() == Vector3i(2147483647, 2147483647, 2147483647):
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
	cursor.position = Vector3(world_pos.x, world_pos.y + 0.1, world_pos.z)
	cursor.show()

func _handle_skill(pos : Vector3i) -> void:
	# Normalize to same plane your maps/skills use
	##TODO make _handle_skill use height
	#var p := Vector3i(pos.x, 0, pos.z)
	
	var p := Vector3i(pos)
	var target: Character = get_unit(p)
		
	print("SKILL CLICK p=", p,
			" in_valid=", valid_skill_target_tiles.has(p),
			" target=", target)

	if not valid_skill_target_tiles.has(p) or target == null or not _is_valid_target(target, active_skill, skill_caster):
		_exit_skill_target_mode()
		return

	print("Casting ", active_skill.skill_id, " from ", skill_caster.data.unit_name, " to ", target.data.unit_name)
	#THIS IS WHERE IT SHOULD TELL VFX CONTROLLER THAT IT SHOULD SPAWN THE SKILLS VFX AT TARGET

	## Impact damage (Fireball)
	if active_skill.effect_mods != null and active_skill.effect_mods.has("damage"):
		target.apply_damage(int(active_skill.effect_mods["damage"]), false, skill_caster, active_skill.skill_name)
		
	## Take all the stuff and compile a list of the results as AttackResult! 
	var result: AttackResult = AttackResult.new()
	result.aggressor = skill_caster
	result.victim = target
	result.vfx_scene =  active_skill.Vfx_Scene
	if active_skill.effect_mods != null and active_skill.effect_mods.has("damage"): 
		result.damage = active_skill.effect_mods.get("damage", null)
	
	combat_vfx.play_skill(result)
	
	## DoT's
	target.state.apply_skill_effect(active_skill)
	emit_signal("character_stats_changed", target)
	
	var used_action := active_skill.uses_action
	var caster := skill_caster
	if used_action:
		caster.state.is_ability_used = true
		# cast a signal to Ribbon here to gray out ability bar
		print("emitting ability_used signal")
		emit_signal("ability_used")
		#print("Flag set, is_ability_used: ", caster.state.is_ability_used)

	_exit_skill_target_mode()
	print("is_ability_used after exit: ", caster.state.is_ability_used)

func _handle_attack_choice(pos: Vector3i) -> void:
	if path_map.get_cell_item(pos) == GridMap.INVALID_CELL_ITEM:
		return

	active_move.end_pos = pos
	moves_stack.append(active_move)

	# Start the animation sequence
	state = States.ANIMATING

func initiate_attack_selection() -> void:
	is_in_menu = false
	path_map.clear()
	movement_map.clear()
	
	var unit := selected_unit
	if not unit: 
		print("[DEBUG_LOG] initiate_attack_selection: No unit selected!")
		return
	
	var reachable: Array[Vector3i] = []
	if not unit.state.is_moved:
		for cmd in current_moves:
			if cmd is Move:
				reachable.append(cmd.end_pos)
	
	# Include current position as a reachable origin for attack range calculation
	var range_tiles := MoveGenerator.get_attack_range_tiles(unit, game_state, reachable)
	
	# Highlight ONLY tiles with enemies
	var found_targets := false
	for t in range_tiles:
		var target_unit := game_state.get_unit(t)
		if target_unit and target_unit.state.faction != unit.state.faction and target_unit.state.faction != CharacterState.Faction.NEUTRAL:
			path_map.set_cell_item(t, 0) # Highlighting the enemy tile
			found_targets = true
	
	if not found_targets:
		print("[DEBUG_LOG] No enemies in range.")
		# If no enemies, maybe we should go back? 
		# But the UI button shouldn't have been shown if no enemies.
	
	state = States.CHOOSING_ENEMY

func _handle_enemy_choice(pos: Vector3i) -> void:
	if path_map.get_cell_item(pos) == GridMap.INVALID_CELL_ITEM:
		return

	var victim := game_state.get_unit(pos)
	if not victim:
		return

	# If the unit already moved, execute the attack immediately from current position
	if selected_unit.state.is_moved:
		active_move = Attack.new(selected_unit.state.grid_position, pos, selected_unit.state.grid_position)
		moves_stack.clear()
		moves_stack.append(active_move)
		state = States.ANIMATING
		path_map.clear()
		return

	# Otherwise, we allow choosing an origin tile (the "attack move" logic)
	# Set an active move for the attack to hold the target
	active_move = Attack.new(selected_unit.state.grid_position, pos, selected_unit.state.grid_position)
	path_map.clear()
	show_attack_tiles(pos)
	state = States.CHOOSING_ATTACK


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
	_update_cursor(unit.state.grid_position)
	emit_signal("character_selected", unit)

	current_moves = MoveGenerator.generate(unit, game_state)
	movement_grid.fill_from_commands(current_moves, game_state)
	
	var reachable: Array[Vector3i] = []
	for cmd in current_moves:
		if cmd is Move:
			reachable.append(cmd.end_pos)
	
	var range_tiles := MoveGenerator.get_attack_range_tiles(unit, game_state, reachable)
	movement_grid.fill_range(range_tiles)
	
	unit_pos = unit.state.grid_position


func _handle_player_click(pos: Vector3i) -> void:
	Tutorial.tutorial_unit_selected()
	select_unit(game_state.get_unit(pos))


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

		moves_stack.clear()
		moves_stack.append(active_move)
		state = CampaignState.LevelState.ANIMATING
		# We don't need to call create_path here, it will be called in _start_next_move_animation
		path_map.clear()

	elif found_attack != null:
		active_move = found_attack
		moves_stack.clear()

		show_attack_tiles(pos)
		state = States.CHOOSING_ATTACK

	movement_map.clear()


func _clear_selection() -> void:
	emit_signal("character_deselected")
	emit_signal("enemy_deselected")
	movement_map.clear()
	path_map.clear()
	selected_unit = null

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
	if state == States.CHOOSING_ATTACK:
		_handle_attack_choice(pos)
		# Clear moves_stack here after it's been used or before it's used?
		# Actually _handle_attack_choice appends to it.
		return

	if state == States.CHOOSING_ENEMY:
		_handle_enemy_choice(pos)
		return

	if _is_invalid_tile(pos):
		return

	# Clicked on movement/attack tile
	if movement_map.get_cell_item(pos) != GridMap.INVALID_CELL_ITEM:
		_handle_action_tile_click(pos)
		return

	# Player unit clicked
	if get_unit_name(pos) == CharacterStates.Player:
		var clicked_unit := game_state.get_unit(pos)
		if clicked_unit:
			if clicked_unit.state.is_ability_used:
				return
			if clicked_unit.state.is_moved and selected_unit != clicked_unit:
				# Allow re-selecting the ALREADY selected unit even if it moved (to see attack origins)
				# but don't allow selecting a DIFFERENT unit that has already moved.
				return
		_handle_player_click(pos)
		return

	# Clicked empty tile
	_clear_selection()

	# Enemy clicked (for info panel)
	var unit_type := get_unit_name(pos)
	if unit_type.contains("Enemy") or unit_type.contains("Character") or unit_type.contains("Chest"):
		selected_enemy_unit = get_unit(pos)
		if selected_enemy_unit:
			enemy_selected.emit(selected_enemy_unit)




func _setup_environment() -> void:
	camera_controller = Main.camera_controller
	
	cursor.hide()
	trigger_map.hide()
	movement_map.clear()
	movement_weights_map.hide()
	occupancy_overlay.hide()
	path_map.clear()
	fog_map.clear()

	terrain_grid = Grid.new(ui_overlay)
	occupancy_grid = Grid.new(movement_map)
	trigger_grid = Grid.new(movement_map)
	movement_grid = MovementGrid.new(movement_map)
	movement_weights_grid = Grid.new(movement_weights_map)
	path_grid = Grid.new(movement_map)
	fog_grid = Grid.new(fog_map)

	if (level_name == "first"):
		Dialogic.start(str(level_name) + "Level")
		is_in_menu = true
	elif (level_name == "fen"):
		Dialogic.start("Showcase_Intro")
		is_in_menu = true

	Main.battle_log = battle_log


func _spawn_players(layout : Layout) -> void:
	var characters_placed := 0
	for pos: Vector3i in layout.player_spawn_points:
		if characters_placed < Main.characters.size():
			var new_unit: Character = Main.characters[characters_placed]
			new_unit.state.is_moved = false
			new_unit.camera = get_viewport().get_camera_3d()
			characters_placed += 1

			new_unit.position = grid_to_world(pos)
			if new_unit.get_parent() != Main.world:
				Main.world.add_child(new_unit)

			characters.append(new_unit)
			new_unit.state.grid_position = pos
			new_unit.sanity_flipped.connect(_on_character_sanity_flipped)
		else:
			occupancy_overlay.set_cell_item(pos, GridMap.INVALID_CELL_ITEM)


func _spawn_enemies(layout : Layout) -> void:
	for pos: Vector3i in layout.enemy_spawn_points:
		var unit_type := get_unit_name(pos)
		spawn_enemy(pos, unit_type, true)


func _spawn_chests(layout : Layout) -> void:
	for pos: Vector3i in layout.chest_spawn_points:
		spawn_enemy(pos, "02_Chest", true)


func _parse_layout() -> Layout:
	var layout := Layout.new()
	var units: Array[Vector3i] = occupancy_overlay.get_used_cells()
	
	for pos: Vector3i in units:
		var unit_type : String = get_unit_name(pos)
		if unit_type == "00_Unit":
			layout.player_spawn_points.append(pos)
		elif unit_type == "02_Chest":
			layout.chest_spawn_points.append(pos)
		elif unit_type.contains("Enemy") or unit_type.contains("Character") or unit_type.contains("Chest"):
			layout.enemy_spawn_points.append(pos)
	
	return layout


func _spawn_from_layout(layout : Layout) -> void:
	_spawn_players(layout)
	_spawn_enemies(layout)
	_spawn_chests(layout)


func _initialize_game_state() -> void:
	move_popup = MOVE_POPUP.instantiate()
	move_popup.hide()
	add_child(move_popup)
	
	Main.campaign.game_status = CampaignState.GameStatus.PLAYING
	Main.campaign.level_state = States.PLAYING
	
	Main.campaign.level_state_changed.connect(_on_level_state_changed)
	Main.campaign.turn_changed.connect(_on_turn_changed)

	game_state = GameState.from_level(self)
	
	turn_transition_animation_player.play()
	add_to_group("level")


func _ready() -> void:
	_setup_environment()
	var layout : Layout = _parse_layout()
	_spawn_from_layout(layout)
	_initialize_game_state()

func spawn_enemy(pos : Vector3i, unit_id : String, _on_ready : bool = false) -> Character:
	var new_enemy: Character = null

	match unit_id:
		"01_Enemy":
			new_enemy = PLAYER.instantiate()
			
			var data := CharacterData.new()
			var c_state := CharacterState.new()
			c_state.faction = CharacterState.Faction.ENEMY
			
			new_enemy.data = data
			new_enemy.state = c_state
			new_enemy.data.unit_name = monster_names.pick_random()

		"02_Chest":
			var chest := CHEST.instantiate()
			chest.position = grid_to_world(pos)
			add_child(chest)

		"04_EnemyBird":
			new_enemy = BIRD_ENEMY.instantiate()
			var data := CharacterData.new()
			data.speed += 4;
			var c_state := CharacterState.new()
			c_state.faction = CharacterState.Faction.ENEMY
			
			new_enemy.data = data
			new_enemy.state = c_state
			new_enemy.data.unit_name = monster_names.pick_random()

		"05_EnemyGhost":
			new_enemy = GHOST_ENEMY.instantiate()
			var data := CharacterData.new()
			var c_state := CharacterState.new()
			c_state.faction = CharacterState.Faction.ENEMY
			
			new_enemy.data = data
			new_enemy.state = c_state
			new_enemy.data.unit_name = monster_names.pick_random()

		"06_EnemyMonster":
			new_enemy = HORROR_ENEMY.instantiate()
			var data := CharacterData.new()
			data.endurance += 6;
			data.strength += 6;
			var c_state := CharacterState.new()
			c_state.faction = CharacterState.Faction.ENEMY
			
			new_enemy.data = data
			new_enemy.state = c_state
			new_enemy.data.unit_name = monster_names.pick_random()
			
		"07_InsaneCharacter":
			new_enemy = CORRUPTED_PLAYER_RED.instantiate()
			var data := CharacterData.new()
			data.endurance += 6;
			data.strength += 6;
			var c_state := CharacterState.new()
			c_state.faction = CharacterState.Faction.ENEMY
			
			new_enemy.data = data
			new_enemy.state = c_state
			new_enemy.data.unit_name = monster_names.pick_random()
			
		_:
			occupancy_overlay.set_cell_item(pos, GridMap.INVALID_CELL_ITEM)

	if new_enemy:
		new_enemy.position = grid_to_world(pos)

		if new_enemy.get_parent() != Main.world:
			Main.world.add_child(new_enemy)

		characters.append(new_enemy)
		if(!_on_ready):
			game_state.units.append(new_enemy)
			occupancy_overlay.set_cell_item(pos, 6)

		if new_enemy is Character:
			new_enemy.state.grid_position = pos
			new_enemy.sanity_flipped.connect(_on_character_sanity_flipped)
	return new_enemy

func get_unit(pos: Vector3i) -> Character:
	for i in range(characters.size()):
		if is_instance_valid(characters[i]):
			if characters[i] is Character:
				var unit: Character = characters[i];
				if unit.state.grid_position == pos:
					return unit;
	return null;


func create_path(start: Vector3i, end: Vector3i) -> void:
	animation_path.clear()
	path_map.clear()
	
	# Identify the moving unit at the start position
	var mover: Character = game_state.get_unit(start)
	if mover == null:
		selected_unit = null
		return
	
	# Build movement grid for this unit in the current simulation snapshot
	var possible_moves: Array[Command] = MoveGenerator.generate(mover, game_state)
	movement_grid.fill_from_commands(possible_moves, game_state)
	
	# Compute grid path and convert to world-space waypoints for animation
	var path: Array[Vector3i] = movement_grid.get_path(start, end)
	for p in path:
		animation_path.append(grid_to_world(p))
	
	# Cache the unit for animation helpers
	selected_unit = mover




func reset_all_units() -> void:
	print("[AI_DEBUG] reset_all_units() called")
	var units :Array[Vector3i] = occupancy_overlay.get_used_cells();
	for i in units.size():
		var pos :Vector3i = units[i];
		if (occupancy_overlay.get_cell_item(pos) == player_code_done):
			occupancy_overlay.set_cell_item(pos, player_code);
		var character: Character = get_unit(pos);
		if character is Character:
			var character_script: Character = character;
			print("[AI_DEBUG] Resetting unit '", character_script.data.unit_name, "' at ", pos)
			character_script.reset();
		



func MoveSingleAI() -> void:
	MoveAI()

func _on_turn_changed(is_player: bool) -> void:
	_clear_selection()

	if is_player:
		print("[AI_DEBUG] === Player Turn Starting ===")
		tick_all_units_end_round()
		reset_all_units()
		for c in characters:
			if c: emit_signal("character_stats_changed", c)

		camera_controller.free_camera()
		var pivot: Character = get_selectable_characters().front()
		if pivot:
			camera_controller.set_pivot_target_translate(pivot.position)
	else:
		# Enemy turn specific setup
		print("[AI_DEBUG] === Enemy Turn Starting ===")
		# BUG FIX: Also reset units at the start of enemy turn
		reset_all_units()
		for c in characters:
			if c: emit_signal("character_stats_changed", c)

	state = States.TRANSITION

func CheckVictoryConditions() -> void:
	var player_alive := false
	var enemy_alive := false
	
	for character in characters:
		if is_instance_valid(character) and character.state and character.state.is_alive:
			if character.state.is_enemy():
				enemy_alive = true
			else:
				player_alive = true
				
	if not player_alive:
		get_tree().change_scene_to_file("res://scenes/states/gameover.tscn")
	elif not enemy_alive:
		get_tree().change_scene_to_file("res://scenes/states/victory.tscn")


func MoveAI() -> void:
	print("[AI_DEBUG] === MoveAI() called ===")
	var ai := MinimaxAI.new()
	var current_simulation := GameState.from_level(self)

	var current_enemy: Character = null
	print("[AI_DEBUG] Searching for next enemy to act...")
	for unit in characters:
		if unit and is_instance_valid(unit) and unit.state.is_enemy():
			print("[AI_DEBUG] Enemy '", unit.data.unit_name, "' at ", unit.state.grid_position, ": moved=", unit.state.is_moved, ", ability_used=", unit.state.is_ability_used)
			# BUG FIX: Check both flags - enemy can still act if only one flag is set
			if not unit.state.is_moved or not unit.state.is_ability_used:
				current_enemy = unit
				print("[AI_DEBUG] Selected enemy: ", unit.data.unit_name, " at ", unit.state.grid_position)
				break

	if current_enemy != null:
		var pos := NullablePosition.new(current_enemy.state.grid_position)
		print("[AI_DEBUG] Checking if enemy has legal moves...")
		if current_simulation.has_enemy_moves(pos):
			print("[AI_DEBUG] Enemy has moves, choosing best move...")
			var move : Command = ai.choose_best_move(current_simulation, 2, current_enemy)
			if move != null:
				print("[AI_DEBUG] AI chose move: ", move.get_class(), " from ", move.start_pos, " to ", move.end_pos)
				moves_stack.append(move)
			else:
				print("[AI_DEBUG] WARNING: has_enemy_moves returned true but choose_best_move returned null!")
				# Force end turn for this enemy if it can't find a move but thought it had one
				current_enemy.state.is_moved = true
				current_enemy.state.is_ability_used = true
		else:
			print("[AI_DEBUG] Enemy at ", pos.position, " has no legal moves, marking as done")
			current_enemy.state.is_moved = true
			current_enemy.state.is_ability_used = true
	else:
		print("[AI_DEBUG] No more enemies can act")

	if not moves_stack.is_empty():
		print("[AI_DEBUG] Executing AI move, transitioning to ANIMATING state")
		state = States.ANIMATING
		camera_controller.focus_camera(current_enemy)
		wait_for_camera = true
		timer.start(pre_enemy_turn_wait)
		await timer.timeout
		wait_for_camera = false
	else:
		# No more enemies can move, switch back to player turn
		print("[AI_DEBUG] No moves in stack, ending enemy turn")
		is_player_turn = true
		_on_turn_changed(true)

func _on_character_sanity_flipped(character: Character) -> void:
	print("heyaaa, we just flipped sanity")
	emit_signal("character_stats_changed", character)
	#characters.erase(character)
	
	

func interpolate_to(target_transform:Transform3D, delta:float) -> void:
	camera_controller.set_pivot_target_transform(target_transform)

#func tick_all_units_end_round(owner: Character) -> void:
func tick_all_units_end_round() -> void:
	## Iterate over duplicates, to avoid null values if units die
	#var dupe := characters.duplicate()
	
	var c:Character = null
	for index : int in range(characters.size()):
		if(characters.get(index) == null):
			push_warning("Character with index %d in characters array was null at end of tick" % index)
			continue
		c = characters.get(index)
		if not is_instance_valid(c):
			continue
		if not (c is Character):
			continue
		if c.state and c.state.is_alive == false:
			continue

		c.state.tick_effects_end_round(c)


func _on_ribbon_attack_pressed() -> void:
	if selected_unit != null and selected_unit.state.has_preformed_action:
		print("Unit has already performed an action this turn.")
		return
	
	movement_map.clear()
	initiate_attack_selection()

func _on_ribbon_skill_pressed(skill: Skill) -> void:
	print("is_ability_used at ribbon press: ", selected_unit.state.is_ability_used if selected_unit else "no unit")
	if selected_unit != null and selected_unit.state.is_ability_used:
		print("Unit has already used their ability this turn.")
		return
	_exit_skill_target_mode()
	movement_grid.clear()
	
	if selected_unit == null:
		print("Pressed skill: ", skill.skill_id, " but no unit selected. This should never happen!")
		return
	
	active_skill = skill
	skill_caster = selected_unit
	is_choosing_skill_target = true
	
	_show_skill_target_tiles(skill_caster.state.grid_position, active_skill)
	print("Entered skill target mode: ", active_skill.skill_id, ". Caster: ", skill_caster.data.unit_name)


func can_use_skill(caster: Character, skill: Skill) -> bool:
	if caster == null or skill == null:
		return false
	
	var origin := caster.state.grid_position
	for unit in characters:
		if not is_instance_valid(unit) or not unit.state.is_alive:
			continue
		
		var pos := unit.state.grid_position
		var dist : int = abs(pos.x - origin.x) + abs(pos.z - origin.z)
		var dy := pos.y - origin.y
		
		# Matching _get_tiles_in_manhattan_range default y range
		if dist >= skill.min_range and dist <= skill.max_range and dy >= -1 and dy < 5:
			if _is_valid_target(unit, skill, caster):
				return true
	return false

func _show_skill_target_tiles(origin: Vector3i, skill: Skill) -> void:
	#valid_skill_target_tiles.clear()
	#path_map.clear() 
#
	#var tiles_in_range: Array[Vector3i] = _get_tiles_in_manhattan_range(origin, skill.min_range, skill.max_range)
#
	#for t in tiles_in_range:
		#var unit: Character = get_unit(t)
		#if _is_valid_target(unit, skill, skill_caster):
			#valid_skill_target_tiles[t] = true
			#path_map.set_cell_item(t, skill_target_code)
	#
	#valid_skill_target_tiles.clear()
	#path_map.clear()

	#var o := Vector3i(origin.x, 0, origin.z)
	var o := Vector3i(origin)
	var tiles_in_range: Array[Vector3i] = _get_tiles_in_manhattan_range(o, skill.min_range, skill.max_range)

	for t in tiles_in_range:
		#var p := Vector3i(t.x, 0, t.z)
		var p := Vector3i(t)
		var unit: Character = get_unit(p)

		if unit == null:
			continue

		if _is_valid_target(unit, skill, skill_caster):
			valid_skill_target_tiles[p] = true
			path_map.set_cell_item(p, skill_target_code)

func _get_tiles_in_manhattan_range(origin: Vector3i, min_r: int, max_r: int, min_y : int = -1, max_y : int = 5) -> Array[Vector3i]:
	var out: Array[Vector3i] = []
	min_r = max(min_r, 0)
	max_r = max(max_r, 0)

	for dx in range(-max_r, max_r + 1):
		var rem:int = max_r - abs(dx)
		for dz in range(-rem, rem + 1):
			for dy in range(min_y, max_y):
				var dist :int = abs(dx) + abs(dz)
				if dist < min_r or dist > max_r:
					continue
				out.append(Vector3i(origin.x + dx, origin.y+dy, origin.z + dz))
	return out

func _exit_skill_target_mode() -> void:
	var caster := skill_caster
	is_choosing_skill_target = false
	active_skill = null
	skill_caster = null
	valid_skill_target_tiles.clear()
	path_map.clear()
	print("caster is_moved: ", caster.state.is_moved if caster else "null")
	if caster != null and caster.state.is_moved == false:
		select_unit(caster)


func _is_valid_target(unit: Character, skill: Skill, caster: Character) -> bool:
	if unit == null or skill == null or caster == null:
		return false

	match skill.target_faction:
		Skill.TargetFaction.FRIENDLY:
			return unit.state.faction == caster.state.faction or unit == caster
		Skill.TargetFaction.ENEMY:
			return unit.state.faction != caster.state.faction
		Skill.TargetFaction.BOTH:
			return true
		Skill.TargetFaction.SELF:
			return unit == caster
		
	return false


func get_screen_position(sprite: Sprite3D) -> Vector2:
	var camera := get_viewport().get_camera_3d()
	if not camera:
		return Vector2.ZERO

	if camera.is_position_behind(sprite.global_position):
		return Vector2(-9999, -9999) # or hide UI

	return camera.unproject_position(sprite.global_position)


func _update_ui_elements(_delta: float) -> void:
	if turn_transition_animation_player.is_playing():
		turn_transition.show()
		camera_controller.lock_camera()
	else:
		turn_transition.hide()
		camera_controller.unlock_camera()


func _process(delta: float) -> void:
	if Main.campaign.game_status != CampaignState.GameStatus.PLAYING:
		return
	
	_update_ui_elements(delta)
	
	if turn_transition_animation_player.is_playing():
		return
	
	if !combat_vfx.is_finished():
		return
	
	if wait_for_camera:
		return
	
	match state:
		States.PLAYING:
			process_playing(delta)
		States.ANIMATING:
			process_animating(delta)
		States.TRANSITION:
			process_transition(delta)
		States.AI_TURN:
			MoveAI()


func process_playing(_delta: float) -> void:
	CheckVictoryConditions()
	
	if is_player_turn:
		if is_in_menu:
			return
		
		# Pathfinding visualization for selected unit
		if selected_unit and not is_in_menu:
			var pos := get_grid_cell_from_mouse()
			if pos != Vector3i(2147483647, 2147483647, 2147483647) and movement_map.get_cell_item(pos) != GridMap.INVALID_CELL_ITEM:
				path_map.clear()
				var points := movement_grid.get_path(selected_unit.state.grid_position, pos)
				for point in points:
					path_map.set_cell_item(point, 0)
			else:
				path_map.clear()
		
		# Turn end check
		if not _has_available_player_moves():
			is_player_turn = false
			_on_turn_changed(false)
	else:
		# AI Turn
		MoveAI()


func process_animating(delta: float) -> void:
	if moves_stack.is_empty() and animation_path.is_empty() and not _is_processing_move:
		if is_in_menu:
			return # Wait for the popup menu to be closed
		_on_animation_finished()
		return
	
	if animation_path.is_empty() and not _is_processing_move and not moves_stack.is_empty():
		_start_next_move_animation()
	elif not animation_path.is_empty():
		_update_movement_animation(delta)


func process_transition(_delta: float) -> void:
	if not turn_transition_animation_player.is_playing():
		if is_player_turn:
			state = States.PLAYING
		else:
			state = States.AI_TURN # Wait, AI_TURN is a separate state?
			# If I rename AI_TURN to match the snippet, it's confusing.
			# But I'll keep the logic as it was in my _process_transition.

func _has_available_player_moves() -> bool:
	for c in characters:
		if not is_instance_valid(c): continue
		if c.state.faction == CharacterState.Faction.PLAYER and c.state.is_alive:
			if not c.state.is_moved or not c.state.is_ability_used:
				return true
	return false

func _start_turn_transition_anim() -> void:
	turn_transition_animation_player.play()
	if is_player_turn:
		player_label.show()
		enemy_label.hide()
	else:
		player_label.hide()
		enemy_label.show()

func _start_next_move_animation() -> void:
	if moves_stack.is_empty():
		return
	
	_is_processing_move = true
	active_move = moves_stack.pop_front()
	
	# RE-INITIALIZE GAME STATE to ensure it's in sync with units
	game_state = GameState.from_level(self)
	active_move.prepare(game_state)
	
	# Start physical movement FIRST
	print("[DEBUG_LOG] Animation Start: move from ", active_move.start_pos, " to ", active_move.end_pos)
	create_path(active_move.start_pos, active_move.end_pos)
	# Fallback: if create_path failed to set selected_unit, try to recover
	if selected_unit == null:
		selected_unit = game_state.get_unit(active_move.start_pos)
		if selected_unit == null:
			selected_unit = game_state.get_unit(active_move.end_pos)
	
	print("[DEBUG_LOG] Selected unit for animation: ", selected_unit.data.unit_name if selected_unit else "NULL")
	
	if animation_path.is_empty():
		# Instant move if no path
		if selected_unit != null:
			print("[DEBUG_LOG] Instant move to ", active_move.end_pos)
			selected_unit.move_to(active_move.end_pos)
	else:
		print("[DEBUG_LOG] Movement path size: ", animation_path.size())
		pass

	# If it's an attack, we need to wait for physical movement to reach end_pos 
	# before showing VFX.
	if not animation_path.is_empty():
		# We'll let _update_movement_animation handle it and trigger VFX when done.
		await _wait_for_movement()
	elif active_move.start_pos != active_move.end_pos:
		# If no path but start != end, it's an instant move that should be finished
		pass

	print("[DEBUG_LOG] Physical movement finished. Playing VFX for result: ", active_move.result)
	# Execute VFX
	await combat_vfx.play_attack(active_move.result)
	
	# Actual damage
	print("[DEBUG_LOG] Applying damage via active_move")
	active_move.apply_damage(game_state)
	
	# Ensure victims that died are removed from occupancy
	if active_move.result and active_move.result.killed:
		occupancy_overlay.set_cell_item(active_move.result.victim.state.grid_position, GridMap.INVALID_CELL_ITEM)
	
	# Update occupancy map for mover
	var code := enemy_code if not is_player_turn else player_code_done
	occupancy_overlay.set_cell_item(active_move.start_pos, GridMap.INVALID_CELL_ITEM)
	occupancy_overlay.set_cell_item(active_move.end_pos, code)
	
	# If the unit actually moved, ensure its state is updated
	if selected_unit != null:
		selected_unit.state.grid_position = active_move.end_pos
		print("[AI_DEBUG] Setting is_moved=true for '", selected_unit.data.unit_name, "' at ", active_move.end_pos)
		selected_unit.state.is_moved = true
		# BUG FIX: Both Attack and Wait should set is_ability_used = true
		if active_move is Attack or active_move is Wait:
			print("[AI_DEBUG] Setting is_ability_used=true for '", selected_unit.data.unit_name, "' (", active_move.get_class(), ")")
			selected_unit.state.is_ability_used = true
		emit_signal("character_stats_changed", selected_unit)
	
	if is_player_turn:
		# If it was a move, maybe show popup?
		if (active_move is Move or active_move is Wait) and selected_unit != null and is_instance_valid(selected_unit):
			show_move_popup(get_screen_position(selected_unit.sprite))
		elif active_move is Attack:
			_is_processing_move = false # Must clear BEFORE finished
			_on_animation_finished()
			return

	_is_processing_move = false

func _wait_for_movement() -> void:
	while not animation_path.is_empty():
		await get_tree().process_frame

func _update_movement_animation(delta: float) -> void:
	if selected_unit == null or not is_instance_valid(selected_unit):
		# Cannot continue animation safely, finish up
		animation_path.clear()
		_on_animation_finished()
		return
	
	var movement_speed := 8.0
	var target : Vector3 = animation_path.front()
	var dir : Vector3 = target - selected_unit.position
	var step := movement_speed * delta
	
	if dir.length() <= step:
		selected_unit.position = target
		animation_path.pop_front()
		if animation_path.is_empty():
			selected_unit.move_to(active_move.end_pos)
			selected_unit.pause_anim()
	else:
		selected_unit.position += dir.normalized() * step
		_play_run_animation(dir)

func _play_run_animation(dir: Vector3) -> void:
	if selected_unit == null or not is_instance_valid(selected_unit):
		return
	if abs(dir.x) > abs(dir.z):
		if dir.x > 0: selected_unit.play(selected_unit.run_right_animation)
		else: selected_unit.play(selected_unit.run_left_animation)
	else:
		if dir.z > 0: selected_unit.play(selected_unit.run_down_animation)
		else: selected_unit.play(selected_unit.run_up_animation)

func _on_animation_finished() -> void:
	print("[AI_DEBUG] Animation finished, is_player_turn=", is_player_turn)
	if is_player_turn:
		print("[AI_DEBUG] Transitioning to PLAYING state")
		state = States.PLAYING
	else:
		print("[AI_DEBUG] Transitioning to AI_TURN state")
		state = States.AI_TURN

	movement_map.clear()
	path_map.clear()
	_clear_selection()
	camera_controller.free_camera()

	for c in characters:
		if is_instance_valid(c): emit_signal("character_stats_changed", c)

func _on_level_state_changed(_new_state: States) -> void:
	match _new_state:
		States.TRANSITION:
			_start_turn_transition_anim()

func end_player_turn() -> bool:
	if !is_player_turn:
		return false
	if (turn_transition_animation_player.is_playing()):
		return false
	if(!combat_vfx.is_finished()):
		return false
	if wait_for_camera:
		return false
	if (is_in_menu):
		return false
	if state != States.PLAYING:
		return false
	var units :Array[Vector3i] = occupancy_overlay.get_used_cells();
	for i in units.size():
		var pos :Vector3i = units[i];
		if (occupancy_overlay.get_cell_item(pos) == player_code):
			active_move = Wait.new(pos)
			active_move.execute(game_state);
			occupancy_overlay.set_cell_item(active_move.start_pos, GridMap.INVALID_CELL_ITEM);
			occupancy_overlay.set_cell_item(active_move.end_pos, player_code_done);
	is_player_turn = false
	_on_turn_changed(false)
	return true
	
