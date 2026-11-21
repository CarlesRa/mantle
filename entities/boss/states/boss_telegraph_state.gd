class_name BossTelegraphState
extends BossState

## Pause before the attack starts.
@export var telegraph_time: float = 0.35
var _time_left: float

func enter() -> void:
	_time_left = telegraph_time
	boss.velocity.x = 0.0
	boss.face_target()
	boss.play_animation(&"idle", true)
	boss.start_telegraph_tint(telegraph_time)

func physics_update(delta: float) -> void:
	if boss.player_is_dead:
		change_state.emit(BossStates.IDLE)
		return
	boss.face_target()
	_time_left -= delta
	if _time_left <= 0.0:
		change_state.emit(BossStates.ATTACK)

func exit() -> void:
	boss.cancel_telegraph_tint()
