class_name BossCooldownState
extends BossState

## Base cooldown between attacks in seconds.
@export var cooldown_time: float = 0.6
var _time_left: float

func enter() -> void:
	_time_left = maxf(cooldown_time * boss.cooldown_multiplier, 0.0)
	boss.velocity.x = 0.0
	boss.play_animation(&"idle")

func physics_update(delta: float) -> void:
	if boss.player_is_dead:
		change_state.emit(BossStates.IDLE)
		return
	boss.face_target()
	_time_left -= delta
	if _time_left > 0.0:
		return
	if boss.distance_to_target() <= boss.attack_range:
		change_state.emit(BossStates.TELEGRAPH)
	elif boss.distance_to_target() <= boss.detection_range:
		change_state.emit(BossStates.CHASE)
	else:
		change_state.emit(BossStates.IDLE)
