class_name PlayerJumpState
extends PlayerState

func enter() -> void:
	EventBus.player_jumped.emit()
	player.velocity.y = player.jump_velocity
	player.play_animation(PlayerAnimations.JUMP)

func exit() -> void:
	# stop jump animation
	pass

func physics_update(_delta: float) -> void:
	_apply_horizontal_movement()
	if player.velocity.y >= 0.0:
		change_state.emit(PlayerStates.FALL)
		return
	# Air jump while still rising (double jump forms).
	if Input.is_action_just_pressed("jump") and player.consume_air_jump():
		_start_jump(true)

func _start_jump(restart_animation: bool) -> void:
	EventBus.player_jumped.emit()
	player.coyote_left = 0.0
	player.velocity.y = player.jump_velocity
	player.play_animation(PlayerAnimations.JUMP, restart_animation)
