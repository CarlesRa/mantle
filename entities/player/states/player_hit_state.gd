class_name PlayerHitState
extends PlayerState

## Seconds the player cannot act after being hit.
@export var stun_time: float = 0.3

var _time_left: float = 0.0

func enter() -> void:
	_time_left = stun_time
	player.velocity = player.knockback
	player.face(-player.knockback.x)
	player.play_animation(PlayerAnimations.HIT)

func exit() -> void:
	pass

func physics_update(delta: float) -> void:
	# No input here: the player loses control while stunned.
	_time_left -= delta
	if _time_left > 0.0:
		return
	if player.is_on_floor():
		change_state.emit(PlayerStates.IDLE)
	else:
		change_state.emit(PlayerStates.FALL)
