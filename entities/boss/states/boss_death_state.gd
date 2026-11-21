class_name BossDeathState
extends BossState

var _time_left: float

func enter() -> void:
	boss.die()
	boss.velocity = Vector2.ZERO
	boss.play_animation(&"death", true)
	_time_left = boss.get_animation_duration(&"death")

func physics_update(delta: float) -> void:
	_time_left -= delta
	if _time_left <= 0.0:
		boss.finish_death()
