extends Node3D

@export var minimum_camera_height: float = 3.0
@export var maximum_camera_height: float = 15.0

@export var minimum_camera_x: float = -10.0
@export var maximum_camera_x: float = 100.0
@export var minimum_camera_z: float = -10.0
@export var maximum_camera_z: float = 10.0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	hide()
	var camera_controller : CameraController = Main.camera_controller
	if ( camera_controller == null):
		return
		
	camera_controller.make_current()
	camera_controller.setup_minmax_positions(
		minimum_camera_x,
		maximum_camera_x,
		minimum_camera_z,
		maximum_camera_z
	)
	camera_controller.springarm_length_maximum = maximum_camera_height
	camera_controller.springarm_length_minimum = minimum_camera_height
	var newTransform : Transform3D = transform
	camera_controller.free_camera()
	camera_controller.set_pivot_transform(newTransform)
