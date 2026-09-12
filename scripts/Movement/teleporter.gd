extends Area3D
class_name Teleporter

@export var linked_teleporter: NodePath #String = ""

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node3D) -> void:
	if body is not Character:
		return
	if body.state.faction != CharacterState.Faction.PLAYER:
		return
	var destination: Teleporter = get_node(linked_teleporter)
	if destination == null:
		return
	body.position = destination.global_position
	body.state.grid_position = Main.level.world_to_grid(destination.global_position)
	Main.level.occupancy_map.set_cell_item(body.state.grid_position, Main.level.player_code)
