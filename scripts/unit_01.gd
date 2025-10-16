extends Node2D

class_name Unit

enum UnitType {PLAYER, ENEMY, NPC}
enum UnitClass {FIGHTER, MAGE, HEALER, ARCHER}

@export var unit_name : String = "Unit"
@export var unit_type : UnitType = UnitType.PLAYER
@export var unit_class: UnitClass = UnitClass.FIGHTER

# Unit Stats
@export var max_hp: int = 20
@export var current_hp: int = 20
@export var strength: int = 5
@export var magic: int = 0
@export var skill: int = 5
@export var speed: int = 5
@export var defense: int = 3
@export var resistance: int = 0
@export var movement: int = 5
@export var experience: int = 0

# Stat gain per level
@export var strength_gain: float = 5
@export var magic_gain: float = 0
@export var skill_gain: float = 5
@export var speed_gain: float = 5
@export var defense_gain: float = 3
@export var resistance_gain: float = 0
@export var movement_gain: float = 5

# Combat stats
@export var weapon_might: int = 5
@export var weapon_range_min: int = 1
@export var weapon_range_max: int = 1

# Grid position
var grid_position: Vector2i
var movement_type: String = "foot"  # foot, cavalry, flying, armored

# Turn state
var has_acted: bool = false
var can_move: bool = true

signal unit_died(unit: Unit)
signal hp_changed(current: int, maximum: int)

func ready():
	update_visuals()
	
func initialize(pos: Vector2i):
	grid_position = pos
	current_hp = max_hp
	has_acted = false
	can_move = true
	
# HEALTH
func take_damage(damage: int):
	current_hp = max(0, current_hp - damage)
	hp_changed.emit(current_hp, max_hp)
	update_visuals()
	
	if current_hp <= 0:
		die()
		
func heal(amount: int):
	current_hp = min(max_hp, current_hp + amount)
	hp_changed.emit(current_hp, max_hp)
	update_visuals()		

func die():
	unit_died.emit(self)
	queue_free()

# COMBAT STATS
func get_attack_power() -> int:
	if unit_class == UnitClass.MAGE:
		return magic + weapon_might
	else:
		return strength + weapon_might

func get_hit_chance() -> int:
	return 90 + skill * 2

func get_critical_chance() -> int:
	return skill / 2

func get_avoid() -> int:
	return speed * 2

func can_attack(target_pos: Vector2i) -> bool:
	var distance = abs(grid_position.x - target_pos.x) + abs(grid_position.y - target_pos.y)
	return distance >= weapon_range_min and distance <= weapon_range_max

func calculate_damage(target: Unit) -> int:
	var attack = get_attack_power()
	var defense_stat = defense if unit_class != UnitClass.MAGE else target.resistance
	var damage = max(0, attack - defense_stat)
	return damage
	
# TURN MANAGEMENT
func end_turn():
	has_acted = true
	can_move = false
	update_visuals()
	
func start_turn():
	has_acted = false
	can_move = true
	update_visuals()

func update_visuals():
	if has_acted: # Dim the sprite if unit has acted
		modulate = Color(0.5, 0.5, 0.5, 1.0)
	else:
		modulate = Color(1.0, 1.0, 1.0, 1.0)
		
func get_movement_range() -> int:
	return movement

func move_to(new_position: Vector2i):
	grid_position = new_position
	
func level_up():
	if experience >= 100:
		experience = experience - 100	
