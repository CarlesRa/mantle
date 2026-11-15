class_name EnemyOneAttackState
extends EnemyOneState


func enter() -> void:
	enemy.velocity.x = 0.0
	enemy.play_animation(EnemyOne.ANIM_ATTACK)


func physics_update(_delta: float) -> void:
	if enemy.is_animation_finished(EnemyOne.ANIM_ATTACK):
		change_state.emit(EnemyOneStates.PATROL)
		return
