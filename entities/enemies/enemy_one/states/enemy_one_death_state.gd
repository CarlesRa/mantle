class_name EnemyOneDeathState
extends EnemyOneState


func enter() -> void:
	enemy.velocity.x = 0.0
	enemy.disable_collision()
	enemy.play_animation(EnemyOne.ANIM_DEATH)
