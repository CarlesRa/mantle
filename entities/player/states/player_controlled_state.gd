# player_controlled_state.gd
class_name PlayerControlledState
extends PlayerState
## States where the player has control. Hit and Death extend PlayerState instead.

func physics_update(delta: float) -> void:
	if Input.is_action_just_pressed("attack"):
		change_state.emit(PlayerStates.ATTACK)
		return
	if Input.is_action_just_pressed("attack_secondary") and player.get_attack(1):
		change_state.emit(PlayerStates.ATTACK_SECONDARY)
		return
	_controlled_update(delta)

## Override this instead of physics_update.
func _controlled_update(_delta: float) -> void:
	pass
