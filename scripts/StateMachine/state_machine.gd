extends Node
class_name StateMachine

var _stack: Array[LevelState] = []

var current: LevelState:
	get: return _stack.back() if not _stack.is_empty() else null

## Transition_to for gameplay states
func transition_to(new_state: LevelState) -> void:
	if not _stack.is_empty():
		_stack.back().exit(owner) 	## Clean up Step 1
		_stack.clear()				## Reference dropped here, old state destructed
	_stack.append(new_state)
	new_state.enter(owner)

## Push/pop for overlays like Main Menu
func push(new_state: LevelState) -> void:
	if not _stack.is_empty():
		_stack.back().exit(owner)
		_stack.clear()
	_stack.append(new_state)
	new_state.enter(owner)

func pop() -> void:
	if _stack.is_empty():
		return
	_stack.back().exit(owner)
	_stack.pop_back()
	if not _stack.is_empty():
		_stack.back().enter(owner)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if current != null:
		current.update(owner, delta)

func _unhandled_input(event: InputEvent) -> void:
	if current != null:
		current.handle_input(owner, event)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
