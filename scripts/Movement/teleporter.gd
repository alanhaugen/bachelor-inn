extends Area3D
class_name Teleporter

@export var linked_teleporter: NodePath #String = ""
@export var teleporter_grid_position: Vector3i = Vector3i.ZERO
var is_active: bool = false
var pending_teleport_char: Character = null

func _ready() -> void:
	add_to_group("teleporters")
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node3D) -> void:
	print("Teleporter body_entered: ", body.name, " type: ", body.get_class())
	if body is not Character:
		return
	if body.state.faction != CharacterState.Faction.PLAYER:
		return
	pending_teleport_char = body
	print("Teleporter: ", name, " triggered by: ", body.data.unit_name)

func get_linked_portal() -> Teleporter:
	if linked_teleporter.is_empty():
		return null
	return get_node(linked_teleporter) as Teleporter
