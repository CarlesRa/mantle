
class_name TestDummy
extends Node2D

## If on, it also hurts the player on contact.
@export var hurts_player: bool = false

@onready var _hitbox: Hitbox = $Hitbox


func _ready() -> void:
	_hitbox.deactivate()
	_hitbox.body_entered.connect(_on_hitbox_body_entered)
	_hitbox.body_exited.connect(_on_hitbox_body_exited)


func _on_hitbox_body_entered(body: Node2D) -> void:
	if not hurts_player:
		return
	if body is Player:
		_hitbox.activate()


func _on_hitbox_body_exited(body: Node2D) -> void:
	if body is Player:
		_hitbox.deactivate()


func receive_hit(hit_data: HitData) -> void:
	take_hit(hit_data.source_position, hit_data.damage)


func take_hit(_source_position: Vector2, damage: int = 1) -> void:
	print("Dummy hit for %d" % damage)
	modulate = Color(3.0, 3.0, 3.0)
	create_tween().tween_property(self, "modulate", Color.WHITE, 0.2)
