class_name Hurtbox
extends Area2D

## Entity that owns this hurtbox.
@export var owner_entity: Node2D


func _init() -> void:
	collision_layer = 8
	collision_mask = 0


## Receives hit data and forwards it to the owning entity.
func receive_hit(hit_data: HitData) -> void:
	if not is_instance_valid(owner_entity):
		return

	if owner_entity.has_method("receive_hit"):
		owner_entity.receive_hit(hit_data)
	else:
		push_warning("%s has a Hurtbox but no receive_hit()" % owner_entity.name)
