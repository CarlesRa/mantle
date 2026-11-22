class_name BossChaseState
extends BossState

func enter() -> void:
	boss.play_animation(&"run")

func physics_update(_delta: float) -> void:
	if boss.player_is_dead:
		boss.velocity.x = 0.0
		change_state.emit(BossStates.IDLE)
		return
	if not is_instance_valid(boss.target):
		boss.velocity.x = 0.0
		change_state.emit(BossStates.IDLE)
		return
	boss.face_target()
	var distance: float = boss.distance_to_target()
	if distance <= boss.attack_range:
		if randf() < boss.jump_chance:
			change_state.emit(BossStates.JUMP)
		else:
			boss.velocity.x = 0.0
			change_state.emit(BossStates.TELEGRAPH)
	elif distance > boss.detection_range:
		boss.velocity.x = 0.0
		change_state.emit(BossStates.IDLE)
	else:
		boss.velocity.x = signf(boss.target.global_position.x - boss.global_position.x) * boss.move_speed
