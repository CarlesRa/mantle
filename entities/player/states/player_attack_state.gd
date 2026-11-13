class_name PlayerAttackState
extends PlayerState

## Button slot this node handles: 0 = primary attack, 1 = secondary attack.
@export var slot: int = 0
## How fast the player brakes on the ground while attacking (higher = stops sooner).
@export var brake_rate: float = 10.0

var _data: AttackData
var _time_left: float = 0.0

func enter() -> void:
	_data = player.get_attack(slot)
	
	if not _data:
		push_warning("Form %s has no attack in slot %d" % [player.form.id, slot])
		change_state.emit(PlayerStates.IDLE)
		return

	_time_left = _data.duration
	player.play_animation(_data.animation, true)
	player.start_attack(_data)

func exit() -> void:
	player.finish_attack()

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
