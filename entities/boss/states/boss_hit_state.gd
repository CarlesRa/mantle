class_name BossHitState
extends BossState

## Brief recovery after taking damage.
@export var hit_time: float = 0.2
var _time_left: float

func enter() -> void:
	_time_left = hit_time
	boss.velocity.x = 0.0
	boss.play_animation(&"hit", true)

func physics_update(delta: float) -> void:
	if boss.player_is_dead:
		change_state.emit(BossStates.IDLE)
		return
	_time_left -= delta
	if _time_left > 0.0:
		return
	if boss.distance_to_target() <= boss.detection_range:
		change_state.emit(BossStates.CHASE)
	else:
		change_state.emit(BossStates.IDLE)
