class_name Hazard
extends Area2D
## Hurts the player on contact. Sandbox element to test the Hit state.

func _physics_process(_delta: float) -> void:
	for body: Node2D in get_overlapping_bodies():
		var player: Player = body as Player
		if player:
			player.take_hit(global_position)
