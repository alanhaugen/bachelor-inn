extends Move
class_name Heal

var amount: int = 0          # Amount to heal
var previous_hp: int = 0     # Stores HP before healing

# Constructor
func _init(in_start_pos: Vector3i, inTargetPos: Vector3i, inAmount: int) -> void:
	end_pos = inTargetPos
	start_pos = in_start_pos
	amount = inAmount

# Execute the heal
func execute(state: GameState, simulate_only: bool = false) -> void:
	var unit := state.get_unit(end_pos)
	if unit == null:
		push_warning("Heal: no unit at position " + str(end_pos))
		return

	# Store previous HP for undo
	previous_hp = unit.state.current_health

	# Apply healing
	if not simulate_only:
		unit.state.current_health = min(unit.state.max_health, unit.state.current_health + amount)
		Main.battle_log.text = unit.data.unit_name + " is healed by " + str(amount) + " hp\n" + Main.battle_log.text;

# Undo the heal
func undo(state: GameState, simulate_only: bool = false) -> void:
	var unit := state.get_unit(end_pos)
	if unit == null:
		push_warning("Heal undo: no unit at position " + str(end_pos))
		return

	if not simulate_only:
		unit.state.current_health = previous_hp
