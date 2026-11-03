class_name PlayerIdleState
extends PlayerState

func enter() -> void:
	player.velocity.x = 0.0
	# start idle animation

func exit() -> void:
	# stop idle animation
	pass

func physics_update(_delta: float) -> void:
	if not player.is_on_floor():
		change_state.emit(PlayerStates.FALL)
		return
	if Input.is_action_just_pressed("jump"):
		change_state.emit(PlayerStates.JUMP)
		return
	if not is_zero_approx(Input.get_axis("move_left", "move_right")):
		change_state.emit(PlayerStates.MOVE)
		return
