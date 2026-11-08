class_name EnemyOnePatrolState
extends EnemyOneState


func enter() -> void:
	enemy.play_animation(EnemyOne.ANIM_WALK)


func physics_update(_delta: float) -> void:
	if enemy.should_turn():
		change_state.emit(EnemyOneStates.IDLE)
		return

	enemy.velocity.x = enemy.direction * enemy.move_speed
