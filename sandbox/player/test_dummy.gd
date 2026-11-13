class_name TestDummy
extends StaticBody2D

## If on, it also hurts the player on contact.
@export var hurts_player: bool = false

@onready var _damage_zone: Area2D = $DamageZone

func _physics_process(_delta: float) -> void:
	if not hurts_player:
		return
	for body: Node2D in _damage_zone.get_overlapping_bodies():
		var player: Player = body as Player
		if player:
			player.take_hit(global_position)

func take_hit(_source_position: Vector2, damage: int = 1) -> void:
	print("Dummy hit for %d" % damage)
	modulate = Color(3.0, 3.0, 3.0)
	create_tween().tween_property(self, "modulate", Color.WHITE, 0.2)
