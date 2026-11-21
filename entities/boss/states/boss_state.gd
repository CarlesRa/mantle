class_name BossState
extends State

var boss: Boss

func setup(new_actor: CharacterBody2D) -> bool:
	if not super(new_actor):
		return false
	boss = new_actor as Boss
	return boss != null
