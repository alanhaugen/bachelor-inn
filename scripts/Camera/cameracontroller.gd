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
	NOT_IN_LEVEL,
}
var _camera_mode : CameraStates = CameraStates.NOT_IN_LEVEL;
var _unlock_camera_mode : CameraStates = _camera_mode
## Freeze camera mode, so the camera mode can not be changed.
## Used by the Tutorial
var freeze_camera_mode : bool = false

#region Springarm Length
@export var _springarm_target_length : float;
@export_range(0, 20, 0.1, "or_greater") var springarm_length_maximum : float = 3
@export_range(0, 20, 0.1, "or_greater") var springarm_length_minimum : float = 15
#endregion

#region Pivot
var _pivot_target_transform : Transform3D
@export var _pivot_max_x : float;
@export var _pivot_min_x : float;
@export var _pivot_max_z : float;
@export var _pivot_min_z : float;
@export var camera_speed: float = 15.0
#endregion

#region input variables
var _screen_movement : Vector2 = Vector2(0, 0)
@export var mouse_drag_sensitivity: float = 50.0
var _zoom_factor : float = 0
@export var mouse_scroll_sensitivity: float = 1
@export var keyboard_zoom_factor: float = 1
#endregion

#endregion


func _ready() -> void:
	springarm_length_maximum = springarm.transform.origin.z
	springarm_length_minimum = springarm.transform.origin.z
	set_springarm_target_length(springarm.transform.origin.z)
	set_pivot_target_transform(pivot.transform)
	_focused_unit = self


#region input
func _input(event: InputEvent) -> void:
	if _camera_mode == CameraStates.FREE:
		_input_dragging(event)
		_input_zoom(event)


func _input_dragging(event: InputEvent) -> void:
	#this statement may cause a bug on phones.
	#Figure out how to enable input mapping for phones
	if Input.is_action_just_released("enable_dragging"):
		Input.mouse_mode = Input.MouseMode.MOUSE_MODE_VISIBLE
	if !Input.is_action_pressed("enable_dragging"):
		return
	Input.mouse_mode = Input.MouseMode.MOUSE_MODE_CAPTURED
	
	var checkMouseDragging:bool = event is InputEventMouseMotion
	var checkScreenDragging:bool = false
	#if statement is to fix a runtime bug
	if event is InputEventScreenDrag and event.index >= 1:
		checkScreenDragging = true
	
	if checkMouseDragging or checkScreenDragging:
		_screen_movement.x += -event.relative.x/mouse_drag_sensitivity
		_screen_movement.y += -event.relative.y/mouse_drag_sensitivity

func _input_zoom(event: InputEvent) -> void:
	if not (event is InputEventMouseButton):
		return
		
	var zoomDirection : float = 0
	if event.button_index == MOUSE_BUTTON_WHEEL_UP:
		zoomDirection = -1
	elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
		zoomDirection = 1
	else:
		return
		
	var zoomStrength : float = event.factor
	
	## To fix system dependent bug with InputEventMouseButton.factor
	if zoomStrength == 0:
		zoomStrength = 1
		
	_zoom_factor += zoomStrength*zoomDirection*mouse_scroll_sensitivity

#endregion


#region _process
func _process(delta: float) -> void:
	if(_camera_mode == CameraStates.FOCUS_UNIT):
		_process_focus_unit(delta)
	if(_camera_mode == CameraStates.FREE):
		_process_input_pivot(delta)
		_process_input_springarm(delta)
	_process_springarm(delta)
	_process_pivot(delta)


func _process_pivot(delta: float) -> void:
	delta = min(delta, 0.04)
	var weight: float = 1 - pow(_lerp_weight, delta)
	pivot.transform.origin = pivot.transform.origin.lerp(
			_pivot_target_transform.origin,
			weight
	)
	pivot.transform.basis = pivot.transform.basis.slerp(
			_pivot_target_transform.basis,
			weight
	)
	
	##removed lines used to experiment with tactical view
	#var springarmPercent : float = (springarm.transform.origin.z - springarm_length_minimum)/(springarm_length_maximum - springarm_length_minimum)
	#var targetAngleMax : float = -90
	#var targetAngleMin : float = -30
	#var targetAngleDifference : float = targetAngleMax - targetAngleMin
	#var targetAngle :float = targetAngleMin + targetAngleDifference*springarmPercent
	#pivot.transform.basis = Basis.from_euler(Vector3(deg_to_rad(targetAngle), 0, 0))

func _process_springarm(delta: float) -> void:
	# source: https://www.construct.net/en/blogs/ashleys-blog-2/using-lerp-delta-time-924
	# Using lerp with delta-time
	var weight: float = 1 - pow(_lerp_weight, delta)
	springarm.transform.origin = springarm.transform.origin.lerp(Vector3(0, 0, _springarm_target_length), weight)


func _process_focus_unit(_dt: float) -> void:
	if(_focused_unit == null):
		return
	set_pivot_target_translate(_focused_unit.transform.origin)


#region _process_input
func _process_input_pivot(delta: float) -> void:
	if _camera_mode == CameraStates.LOCKED:
		return
		
	var tutorial_camera_moved : bool = false;
	if Input.is_action_pressed("pan_right"):
		_screen_movement.x += camera_speed * delta
	if Input.is_action_pressed("pan_left"):
		_screen_movement.x -= camera_speed * delta
	if Input.is_action_pressed("pan_up"):
		_screen_movement.y -= camera_speed * delta
	if Input.is_action_pressed("pan_down"):
		_screen_movement.y += camera_speed * delta
		
	add_pivot_translate(Vector3(_screen_movement.x, 0, _screen_movement.y))
		
	if(_screen_movement != Vector2.ZERO):
		Tutorial.tutorial_camera_moved();
	if Input.is_action_pressed("selected"):
		pass;
	_screen_movement = Vector2.ZERO

func _process_input_springarm(delta: float) -> void:
	#TODO refactor the springarm input so that the distance scrolled in a second
	#affects the zoom
	
	if Input.is_action_just_released("zoom_in") or Input.is_action_pressed("zoom_in"):
		_zoom_factor += -keyboard_zoom_factor * 20 * delta
	if Input.is_action_just_released("zoom_out") or Input.is_action_pressed("zoom_out"):
		_zoom_factor += keyboard_zoom_factor * 20 * delta
	add_springarm_target_length(_zoom_factor)
	_zoom_factor = 0
#endregion
#endregion

#region Setup functions
func setup_minmax_positions(minimum_x: float, maximum_x: float, minimum_z: float, maximum_z: float) -> void:
	_pivot_min_x = minimum_x
	_pivot_max_x = maximum_x
	_pivot_min_z = minimum_z
	_pivot_max_z = maximum_z

##TODO
#func setup_springarm()
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
	if(_camera_mode == CameraStates.LOCKED):
		return
	_pivot_target_transform = target_transform
	_clamp_pivot_target_translation()


func set_pivot_target_translate(target_translate: Vector3) -> void:
	if(_camera_mode == CameraStates.LOCKED):
		return
	_pivot_target_transform.origin = target_translate
	_clamp_pivot_target_translation()


func add_pivot_target_translate(added_translate: Vector3) -> void:
	if(_camera_mode == CameraStates.LOCKED):
		return
	_pivot_target_transform.origin += added_translate
	_clamp_pivot_target_translation()


func set_pivot_transform(target_transform:Transform3D) -> void:
	if(_camera_mode != CameraStates.FREE):
		return
	_pivot_target_transform = target_transform
	pivot.transform = target_transform
	_clamp_pivot_translation()
	_clamp_pivot_target_translation()


func add_pivot_translate(added_translate: Vector3) -> void:
	if(_camera_mode != CameraStates.FREE):
		return
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
	if(_camera_mode != CameraStates.FREE):
		return
	springarm.transform.origin.z = new_length
	_springarm_target_length = new_length
	_clamp_springarm_length()
	_clamp_springarm_target_length()


func add_springarm_length(new_length: float) -> void:
	if(_camera_mode != CameraStates.FREE):
		return
	springarm.transform.origin.z += new_length
	_springarm_target_length = new_length
	_clamp_springarm_length()
	_clamp_springarm_target_length()


func set_springarm_target_length(new_target_lenght: float) -> void:
	if(_camera_mode == CameraStates.LOCKED):
		return
	_springarm_target_length = new_target_lenght
	_clamp_springarm_target_length()


func add_springarm_target_length(new_target_lenght: float) -> void:
	if(_camera_mode == CameraStates.LOCKED):
		return
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


#region Camera modes
## makes camera focus a unit and interpolate it
## returns false if Node3D does not exist
## otherwise returns true and changes camera mode
func focus_camera(unit: Node3D) -> bool:
	if freeze_camera_mode:
		return false
	if(unit == null):
		return false
	_focused_unit = unit
	_camera_mode = CameraStates.FOCUS_UNIT
	return true


func free_camera() -> void:
	if freeze_camera_mode:
		return
	_camera_mode = CameraStates.FREE


func lock_camera() -> void:
	if freeze_camera_mode:
		return
	if _camera_mode != CameraStates.LOCKED:
		_unlock_camera_mode = _camera_mode
	_camera_mode = CameraStates.LOCKED


## if camera_moce is LOCKED, return the camera to the previous non-LOCKED value
func unlock_camera() -> void:
	if freeze_camera_mode:
		return
	if _camera_mode != CameraStates.LOCKED:
		return
	_camera_mode = _unlock_camera_mode
#endregion
