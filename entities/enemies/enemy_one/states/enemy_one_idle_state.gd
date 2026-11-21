class_name EnemyOneIdleState
extends EnemyOneState

@export var wait_time: float = 0.6

var _time_left: float = 0.0


func enter() -> void:
	enemy.velocity.x = 0.0
	_time_left = wait_time
	enemy.play_animation(EnemyOne.ANIM_IDLE)


func physics_update(delta: float) -> void:
	_time_left -= delta
	if _time_left > 0.0:
		return

	enemy.turn_around()
	change_state.emit(EnemyOneStates.PATROL)
