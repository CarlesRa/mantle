class_name PlayerJumpState
extends PlayerState

func enter() -> void:
	EventBus.player_jumped.emit()
	player.velocity.y = player.jump_velocity
	# start jump animation

func exit() -> void:
	# stop jump animation
	pass

func physics_update(_delta: float) -> void:
	_apply_horizontal_movement()
	if player.velocity.y >= 0.0:
		change_state.emit(PlayerStates.FALL)
		return
