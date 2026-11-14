class_name TestDummy
extends Node2D

## If on, it also hurts the player on contact.
@export var hurts_player: bool = true

@onready var _hitbox: Hitbox = $Hitbox
@onready var _contact_detector: Area2D = $ContactDetector


func _ready() -> void:
	_hitbox.source = self
	_hitbox.deactivate()

	_contact_detector.area_entered.connect(_on_contact_detector_area_entered)
	_contact_detector.area_exited.connect(_on_contact_detector_area_exited)


func _on_contact_detector_area_entered(area: Area2D) -> void:
	if not hurts_player:
		return

	if area is Hurtbox and area.owner_entity is Player:
		_hitbox.activate()


func _on_contact_detector_area_exited(area: Area2D) -> void:
	if area is Hurtbox and area.owner_entity is Player:
		_hitbox.deactivate()


func receive_hit(hit_data: HitData) -> void:
	take_hit(hit_data.source_position, hit_data.damage)


func take_hit(_source_position: Vector2, damage: int = 1) -> void:
	print("Dummy hit for %d" % damage)
	modulate = Color(3.0, 3.0, 3.0)
	create_tween().tween_property(self, "modulate", Color.WHITE, 0.2)
