class_name PlayerFallState
extends PlayerState

var _jump_buffer: float = 0.0

func enter() -> void:
	_jump_buffer = 0.0
	# start fall animation

func exit() -> void:
	# stop fall animation
	pass

func physics_update(delta: float) -> void:
	_apply_horizontal_movement()
	if _jump_buffer > 0.0:
		_jump_buffer = maxf(_jump_buffer - delta, 0.0)
	if Input.is_action_just_pressed("jump"):
		_jump_buffer = player.jump_buffer_time
	if player.is_on_floor() and player.velocity.y >= 0.0:
		if _jump_buffer > 0.0:
			_land(PlayerStates.JUMP)
			return
		if is_zero_approx(player.velocity.x):
			_land(PlayerStates.IDLE)
			return
		_land(PlayerStates.MOVE)
		return

func _land(next_state: StringName) -> void:
	EventBus.player_landed.emit()
	change_state.emit(next_state)
