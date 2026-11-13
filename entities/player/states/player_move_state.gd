class_name PlayerMoveState
extends PlayerControlledState

func enter() -> void:
	player.play_animation(PlayerAnimations.RUN)

func exit() -> void:
	# stop move animation
	print('exit move_state')
	pass

func _controlled_update(_delta: float) -> void:
	if not player.is_on_floor():
		change_state.emit(PlayerStates.FALL)
		return
	if Input.is_action_just_pressed("jump"):
		change_state.emit(PlayerStates.JUMP)
		return
	_apply_horizontal_movement()
	if is_zero_approx(player.velocity.x):
		change_state.emit(PlayerStates.IDLE)
		return
