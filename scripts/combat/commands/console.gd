extends Command
class_name Console

var tile_using_ability : Vector3i;
var tile_to_increase_sanity : Vector3i;
var heal_amount : int;


func _init(from_tile : Vector3i, tile_to_heal : Vector3i, amount : int) -> void:
	tile_using_ability = from_tile;
	tile_to_increase_sanity = tile_to_heal;
	heal_amount = amount;


func execute(state : GameState, simulate_only : bool = false) -> void:
	var magician := state.get_unit(tile_using_ability);
	var target := state.get_unit(tile_to_increase_sanity);
	if magician.current_mana > 0 and simulate_only == false:
		magician.mana -= 1;
		magician.current_sanity -= heal_amount / 2;
		target.current_sanity += heal_amount;



func undo(state : GameState, simulate_only : bool = false) -> void:
	if simulate_only == false:
		var unit := state.get_unit(tile_to_increase_sanity);
		unit.sanity -= heal_amount;
		unit.mana += 1;
