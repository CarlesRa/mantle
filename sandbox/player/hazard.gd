class_name Hazard
extends Area2D
## Hurts the player on contact. Sandbox element to test Hit and Death states.

## Number of hits before the player dies.
@export var hits_to_kill: int = 3

var _current_hits: int = 0
var _cooldown: float = 0.0

func _ready() -> void:
	_current_hits = hits_to_kill

func _physics_process(delta: float) -> void:
	_cooldown = maxf(_cooldown - delta, 0.0)
	
	for body: Node2D in get_overlapping_bodies():
		var player: Player = body as Player
		if player:
			if _cooldown <= 0.0:
				if _current_hits > 1:
					player.take_hit(global_position)
					_current_hits -= 1
					_cooldown = player.invulnerability_time 
				else:
					player.take_hit(global_position, 999)
			return
