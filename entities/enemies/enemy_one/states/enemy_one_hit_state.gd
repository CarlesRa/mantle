class_name EnemyOneHitState
extends EnemyOneState

## Horizontal deceleration in px/s² applied to the knockback.
@export var knockback_friction: float = 600.0


func enter() -> void:
	enemy.play_animation(EnemyOne.ANIM_HIT)


func physics_update(delta: float) -> void:
	if enemy.is_animation_finished(EnemyOne.ANIM_HIT):
		change_state.emit(EnemyOneStates.PATROL)
		return

	enemy.velocity.x = move_toward(enemy.velocity.x, 0.0, knockback_friction * delta)
