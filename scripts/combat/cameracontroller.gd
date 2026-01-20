# Author: Alan & Alexander

## Class to control a camera.
## Design is to set a destination to the
class_name CameraController extends Node3D

#region Components
@onready var springarm : Node3D = %Springarm
@onready var camera : Camera3D = %Camera
@onready var pivot : Node3D = %Pivot
#endregion

#region Variables
## Inverse of percentage of remaining distance covered by LERP per second.
## A weight of 0.1 covers 90% of the remaining distance every second, and a weight of 0.2
## convers 80% of the remaining distance every second
@export_range(0, 1, 0.0001, "exp") var _lerp_weight : float = 0.0015;
var _focused_unit : Node3D

enum CameraStates {
	FREE, ## player controlled
	FOCUS_UNIT, ## interpolating to a unit
	LOCKED, ## Camera will not recieve new positions, but will interpolate to existing targets
}
var camera_mode : CameraStates = CameraStates.FREE;

#region Springarm Length
@export var _springarm_target_length : float;
@export var springarm_length_maximum : float
@export var springarm_length_minimum : float
#endregion

#region Pivot
var _pivot_target_transform : Transform3D
@export var _pivot_max_x : float;
@export var _pivot_min_x : float;
@export var _pivot_max_z : float;
@export var _pivot_min_z : float;
#endregion


#endregion


func _ready() -> void:
	springarm_length_maximum = springarm.transform.origin.z
	springarm_length_minimum = springarm.transform.origin.z
	set_springarm_target_length(springarm.transform.origin.z)
	set_pivot_target_transform(pivot.transform)
	_focused_unit = self

#region _process
func _process(delta: float) -> void:
	if(camera_mode == CameraStates.FOCUS_UNIT):
		_process_focus_unit()
	_process_springarm(delta)
	_process_pivot(delta)

func _process_pivot(dt: float) -> void:
	var weight: float = 1 - pow(_lerp_weight, dt)
	#pivot.transform
	pivot.transform.origin = pivot.transform.origin.lerp(
			_pivot_target_transform.origin,
			weight
	)
	pivot.transform.basis = pivot.transform.basis.slerp(
			_pivot_target_transform.basis,
			weight
	)

func _process_springarm(dt: float) -> void:
	# source: https://www.construct.net/en/blogs/ashleys-blog-2/using-lerp-delta-time-924
	# Using lerp with delta-time
	var weight: float = 1 - pow(_lerp_weight, dt)
	springarm.transform.origin = springarm.transform.origin.lerp(Vector3(0, 0, _springarm_target_length), weight)

func _process_focus_unit() -> void:
	if(_focused_unit == null):
		return
	set_pivot_target_translate(_focused_unit.transform.origin)

#region Setup functions
func setup_minmax_positions(minimum_x: float, maximum_x: float, minimum_z: float, maximum_z: float) -> void:
	_pivot_min_x = minimum_x
	_pivot_max_x = maximum_x
	_pivot_min_z = minimum_z
	_pivot_max_z = maximum_z

#endregion

#region Camera functions
func make_current() -> void:
	camera.make_current()
	
func clear_current() -> void:
	camera.clear_current()

## Returns a 3D position in world space, that is the result of projecting 
## a point on the Viewport rectangle by the inverse camera projection. 
## This is useful for casting rays in the form of (origin, normal) for 
## object intersection or picking.
func project_ray_origin(screen_point: Vector2) -> Vector3:
	return camera.project_ray_origin(screen_point)

## Returns a normal vector in world space, that is the result of projecting 
## a point on the Viewport rectangle by the inverse camera projection. 
## This is useful for casting rays in the form of (origin, normal) for 
## object intersection or picking.
func project_ray_normal(screen_point: Vector2) -> Vector3:
	return camera.project_ray_normal(screen_point)
#endregion

#region Pivot functions
## Set the target location
func set_pivot_target_transform(target_transform:Transform3D) -> void:
	_pivot_target_transform = target_transform
	_clamp_pivot_target_translation()

func set_pivot_target_translate(target_translate: Vector3) -> void:
	_pivot_target_transform.origin = target_translate
	_clamp_pivot_target_translation()

func add_pivot_target_translate(added_translate: Vector3) -> void:
	_pivot_target_transform.origin += added_translate
	_clamp_pivot_target_translation()

func set_pivot_transform(target_transform:Transform3D) -> void:
	_pivot_target_transform = target_transform
	pivot.transform = target_transform
	_clamp_pivot_translation()
	_clamp_pivot_target_translation()

func add_pivot_translate(added_translate: Vector3) -> void:
	_pivot_target_transform.origin += added_translate
	pivot.transform.origin += added_translate
	_clamp_pivot_translation()
	_clamp_pivot_target_translation()

func _clamp_pivot_target_translation() -> void:
	if _pivot_target_transform.origin.x > _pivot_max_x:
		_pivot_target_transform.origin.x = _pivot_max_x
	if _pivot_target_transform.origin.x < _pivot_min_x:
		_pivot_target_transform.origin.x = _pivot_min_x
	if _pivot_target_transform.origin.z < _pivot_min_z:
		_pivot_target_transform.origin.z = _pivot_min_z
	if _pivot_target_transform.origin.z > _pivot_max_z:
		_pivot_target_transform.origin.z = _pivot_max_z

func _clamp_pivot_translation() -> void:
	if pivot.transform.origin.x > _pivot_max_x:
		pivot.transform.origin.x = _pivot_max_x
	if pivot.transform.origin.x < _pivot_min_x:
		pivot.transform.origin.x = _pivot_min_x
	if pivot.transform.origin.z < _pivot_min_z:
		pivot.transform.origin.z = _pivot_min_z
	if pivot.transform.origin.z > _pivot_max_z:
		pivot.transform.origin.z = _pivot_max_z


#endregion

#region Springarm functions
func set_springarm_length(new_length: float) -> void:
	springarm.transform.origin.z = new_length
	_springarm_target_length = new_length
	_clamp_springarm_length()
	_clamp_springarm_target_length()

func add_springarm_length(new_length: float) -> void:
	springarm.transform.origin.z += new_length
	_springarm_target_length = new_length
	_clamp_springarm_length()
	_clamp_springarm_target_length()

func set_springarm_target_length(new_target_lenght: float) -> void:
	_springarm_target_length = new_target_lenght
	_clamp_springarm_target_length()

func add_springarm_target_length(new_target_lenght: float) -> void:
	_springarm_target_length += new_target_lenght
	_clamp_springarm_target_length()

func _clamp_springarm_length() -> void:
	if(springarm.transform.origin.z < springarm_length_minimum):
		springarm.transform.origin.z = springarm_length_minimum
	if(springarm.transform.origin.z > springarm_length_maximum):
		springarm.transform.origin.z = springarm_length_maximum

func _clamp_springarm_target_length() -> void:
	if(_springarm_target_length < springarm_length_minimum):
		_springarm_target_length = springarm_length_minimum
	if(_springarm_target_length > springarm_length_maximum):
		_springarm_target_length = springarm_length_maximum

## private
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

## makes camera focus a unit and interpolate it
## returns false if Node3D does not exist
## otherwise returns true and changes camera mode
func focus_camera(unit: Node3D) -> bool:
	if(unit == null):
		return false
	_focused_unit = unit
	camera_mode = CameraStates.FOCUS_UNIT
	return true

func free_camera() -> void:
	camera_mode = CameraStates.FREE

func lock_camera() -> void:
	camera_mode = CameraStates.LOCKED
