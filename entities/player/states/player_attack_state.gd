class_name PlayerAttackState
extends PlayerState

## How fast the player brakes on the ground while attacking (higher = stops sooner).
@export var brake_rate: float = 10.0

var _time_left: float = 0.0

func enter() -> void:
	_time_left = player.attack_duration
	player.play_animation(PlayerAnimations.ATTACK)
	if not player.form.attack_projectile:
		player.set_attack_active(true)

func exit() -> void:
	player.set_attack_active(false)

func physics_update(delta: float) -> void:
	if player.is_on_floor():
		# On the ground the attack brakes the player.
		player.velocity.x = move_toward(player.velocity.x, 0.0, player.move_speed * brake_rate * delta)
	else:
		# In the air the player keeps control.
		_apply_horizontal_movement()

	_time_left -= delta
	if _time_left > 0.0:
		return
	if not player.is_on_floor():
		change_state.emit(PlayerStates.FALL)
	elif is_zero_approx(Input.get_axis("move_left", "move_right")):
		change_state.emit(PlayerStates.IDLE)
	else:
		change_state.emit(PlayerStates.MOVE)
