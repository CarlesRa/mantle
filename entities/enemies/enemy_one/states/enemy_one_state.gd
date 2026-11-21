class_name EnemyOneState
extends State


var enemy: EnemyOne


func setup(new_actor: CharacterBody2D) -> bool:
	if not super.setup(new_actor):
		return false
	enemy = new_actor as EnemyOne
	if enemy == null:
		var msg := "%s: actor is not an EnemyOne." % name
		push_error(msg)
		assert(false, msg)
		return false
	return true
