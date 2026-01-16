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
var _lerp_weight : float;

var _pivot_max_x : float;
var _pivot_min_x : float;
var _pivot_max_z : float;
var _pivot_min_z : float;

enum CameraStates {
	FREE, ## player controlled
	FOCUS_UNIT, ## interpolating to a unit
	TRACK_MOVE, ## following a moving unit
	RETURN }; ## interpolating back to saved position
var camera_mode : CameraStates = CameraStates.FREE;

#region Springarm Length
var _springarm_target_length : float;
var springarm_length_maximum : float
var springarm_length_minimum : float
#endregion

#region Pivot
var _pivot_target_transform : Transform3D
#endregion


#endregion


func _ready() -> void:
	springarm_length_maximum = springarm.transform.origin.z
	springarm_length_minimum = springarm.transform.origin.z
	set_springarm_target_length(springarm.transform.origin.z)
	_lerp_weight = 0.05
	set_pivot_target_transform(pivot.transform)

func _process(delta: float) -> void:
	_process_springarm(delta)
	_process_pivot(delta)


	

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
#endregion

#region Springarm functions
func set_springarm_length(new_length: float) -> void:
	springarm.transform.origin.z = new_length

func add_springarm_length(new_length: float) -> void:
	springarm.transform.origin.z += new_length

func set_springarm_target_length(new_target_lenght: float) -> void:
	_springarm_target_length = new_target_lenght

func add_springarm_target_length(new_target_lenght: float) -> void:
	_springarm_target_length += new_target_lenght

## private
func _process_springarm(dt: float) -> void:
	# clamp springarm length
	
	if(springarm.transform.origin.z < springarm_length_minimum):
		springarm.transform.origin.z = springarm_length_minimum
	if(springarm.transform.origin.z > springarm_length_maximum):
		springarm.transform.origin.z = springarm_length_maximum
		
	if(_springarm_target_length < springarm_length_minimum):
		_springarm_target_length = springarm_length_minimum
	if(_springarm_target_length > springarm_length_maximum):
		_springarm_target_length = springarm_length_maximum
	
	
	# source: https://www.construct.net/en/blogs/ashleys-blog-2/using-lerp-delta-time-924
	# Using lerp with delta-time
	var weight: float = 1 - pow(_lerp_weight, dt)
	springarm.transform.origin = springarm.transform.origin.lerp(Vector3(0, 0, _springarm_target_length), weight)
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
