# Author: Alan & Alexander

## Class to control a camera.
## Design is to set a destination to the
class_name CameraController extends Node3D

#region Components
@onready var springarm : SpringArm3D = %SpringArm
@onready var camera : Camera3D = %Camera
#endregion

#region Variables
## Inverse of percentage of remaining distance covered by LERP per second.
## A weight of 0.1 covers 90% of the remaining distance every second, and a weight of 0.2
## convers 80% of the remaining distance every second
var _lerp_weight : float;

var _camera_max_x : float;
var _camera_min_x : float;
var _camera_max_z : float;
var _camera_min_z : float;

enum CameraStates {
	FREE, ## player controlled
	FOCUS_UNIT, ## interpolating to a unit
	TRACK_MOVE, ## following a moving unit
	RETURN }; ## interpolating back to saved position
var camera_mode : CameraStates = CameraStates.FREE;

#region Springarm Length
var _target_springarm_length : float;
#endregion

#region Pivot
var _target_pivot_transform : Transform3D
#endregion


#endregion


func _ready() -> void:
	_target_springarm_length = springarm.get_length()
	_lerp_weight = 0.5

func _process(delta: float) -> void:
	_process_springarm(delta)
	_process_pivot(delta)


	

#region Setup functions
func setup_minmax_positions(minimum_x: float, maximum_x: float, minimum_z: float, maximum_z: float) -> void:
	_camera_min_x = minimum_x
	_camera_max_x = maximum_x
	_camera_min_z = minimum_z
	_camera_max_z = maximum_z



#endregion

#region Camera functions
func make_current() -> void:
	camera.make_current()
	
func clear_current() -> void:
	camera.clear_current()

## Returns a 3D position in world space, that is the result of projecting a point on the Viewport rectangle by the inverse camera projection. This is useful for casting rays in the form of (origin, normal) for object intersection or picking.
func project_ray_origin(screen_point: Vector2) -> Vector3:
	return camera.project_ray_origin(screen_point)

## Returns a normal vector in world space, that is the result of projecting a point on the Viewport rectangle by the inverse camera projection. This is useful for casting rays in the form of (origin, normal) for object intersection or picking.
func project_ray_normal(screen_point: Vector2) -> Vector3:
	return camera.project_ray_normal(screen_point)

## Set the target location
func set_target_pivot_transform(target_transform:Transform3D) -> void:
	_target_pivot_transform = target_transform

func _process_pivot(dt: float) -> void:
	var weight: float = 1 - pow(_lerp_weight, dt) 
	global_transform.origin = global_transform.origin.lerp(
		_target_pivot_transform.origin,
		weight
	)
	
	global_transform.basis = global_transform.basis.slerp(
		_target_pivot_transform.basis,
		weight
	)
#endregion

#region Springarm functions
func set_springarm_length_immediate(new_length: float) -> void:
	springarm.set_length(new_length)

func set_springarm_length_lerp(new_target_lenght: float) -> void:
	_target_springarm_length = new_target_lenght

## private
func _process_springarm(dt: float) -> void:
	var current_length: float = springarm.get_length()
	# source: https://www.construct.net/en/blogs/ashleys-blog-2/using-lerp-delta-time-924
	# Using lerp with delta-time
	var weight: float = 1 - pow(_lerp_weight, dt)
	lerpf(current_length, _target_springarm_length, weight)
#endregion

## Set inverse of percentage of remaining distance covered by LERP per second.
## A weight of 0.1 covers 90% of the remaining distance every second, and a weight of 0.2
## convers 80% of the remaining distance every second
## range is [0, 1]
func set_lerp_weight(new_weight_decimal_form: float) -> void:
	if new_weight_decimal_form < 0:
		new_weight_decimal_form = 0
	elif new_weight_decimal_form > 1:
		new_weight_decimal_form = 1
	_lerp_weight = new_weight_decimal_form
