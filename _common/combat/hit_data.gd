
class_name HitData
extends RefCounted

## Amount of damage dealt by this hit.
var damage: int

## Entity responsible for this hit.
var source: Node2D

## World position from which the hit originated.
var source_position: Vector2

func _init(
	p_damage: int,
	p_source: Node2D,
	p_source_position: Vector2
) -> void:
	damage = p_damage
	source = p_source
	source_position = p_source_position
