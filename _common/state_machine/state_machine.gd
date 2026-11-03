class_name StateMachine
extends Node

@export var initial_state: State
@export var debug: bool = false

var states: Dictionary[StringName, State]
var current_state: State
var actor: CharacterBody2D

func _ready() -> void:
	if not initial_state:
		var error_message: String = "Not initial state assigned"
		if owner:
			error_message += " in %s" % owner.name
		push_error(error_message)
		set_physics_process(false)
		return
	if not _register_states():
		set_physics_process(false)
		return
	_execute_change_state(initial_state)

func _register_states() -> bool:
	if owner is not CharacterBody2D:
		var error_message: String = "owner is not a CharacterBody2D"
		if owner:
			error_message += ", current owner: %s" % owner.name
		push_error(error_message)
		return false
	actor = owner
	for child in get_children():
		var state: State = child as State
		if not state:
			push_warning("The child %s is not State" % child.name)
			continue
		if not state.setup(actor):
			push_error("State %s failed to set up" % state.name)
			return false
		state.change_state.connect(_handle_state)
		states[state.name] = state
	return true

func _physics_process(delta: float) -> void:
	if not current_state:
		return
	current_state.physics_update(delta)

func _handle_state(state_name: StringName) -> void:
	if states.is_empty():
		push_error("The states have not been set")
		return
	var exists_new_state: bool = states.has(state_name)
	if not current_state:
		var new_state: State = states.get(state_name) if exists_new_state else initial_state
		var warning_message: String = "Current state is not present"
		if new_state:
			warning_message += ", going to state %s" % new_state.name
		push_warning(warning_message)
		_execute_change_state(new_state)
		return
	if not exists_new_state:
		var error_message: String = "No state with name %s" % state_name
		push_error(error_message)
		assert(false, error_message)
		if current_state != initial_state:
			_execute_change_state(initial_state)
		return
	var state_to_change: State = states.get(state_name)
	if current_state == state_to_change:
		return
	_execute_change_state(state_to_change)

func _execute_change_state(state: State) -> void:
	if not state:
		push_error("_execute_change_state called without value")
		return
	if current_state:
		current_state.exit()
	if debug:
		print("change state to %s" % state.name)
	current_state = state
	current_state.enter()
