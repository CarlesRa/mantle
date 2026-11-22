## Walks forward until a wall or a ledge is ahead. Stationary enemies stand still instead.
class_name EnemyOnePatrolState
extends EnemyOneState


func enter() -> void:
	if enemy.stationary:
		enemy.play_animation(EnemyOne.ANIM_IDLE)
	else:
		enemy.play_animation(EnemyOne.ANIM_WALK)


func physics_update(_delta: float) -> void:
	if enemy.can_see_player():
		change_state.emit(EnemyOneStates.ATTACK)
		return

	if enemy.stationary:
		enemy.velocity.x = 0.0
		return

	if enemy.should_turn():
		change_state.emit(EnemyOneStates.IDLE)
		return

	enemy.velocity.x = enemy.direction * enemy.move_speed
