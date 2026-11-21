class_name BossAttackState
extends BossState

var _data: AttackData
var _time_left: float

func enter() -> void:
	if boss.player_is_dead:
		change_state.emit(BossStates.IDLE)
		return
	boss.face_target()
	_data = boss.choose_attack()
	if not _data:
		change_state.emit(BossStates.COOLDOWN)
		return
	_time_left = maxf(_data.duration, 0.0)
	var track: BossAttackTrack = boss.get_attack_track(_data)
	if track:
		boss.start_tracked_attack(_data, track)
		boss.play_animation(_data.animation, true)
	else:
		boss.play_animation(_data.animation, true)
		boss.start_attack(_data)

func physics_update(delta: float) -> void:
	if boss.player_is_dead:
		boss.finish_attack()
		change_state.emit(BossStates.IDLE)
		return
	boss.face_target()
	boss.velocity.x = 0.0
	_time_left -= delta
	if _time_left <= 0.0:
		boss.finish_attack()
		change_state.emit(BossStates.COOLDOWN)

func exit() -> void:
	boss.finish_attack()

