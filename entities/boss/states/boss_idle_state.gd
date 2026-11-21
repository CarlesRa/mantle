class_name BossIdleState
extends BossState

func enter() -> void:
	boss.velocity.x = 0.0
	boss.play_animation(&"idle")

func physics_update(_delta: float) -> void:
	if boss.player_is_dead or not is_instance_valid(boss.target):
		return
	if boss.distance_to_target() <= boss.detection_range:
		change_state.emit(BossStates.CHASE)
