
class_name Hitbox
extends Area2D

## Amount of damage dealt by this hitbox.
@export var damage: int = 1

## Entity responsible for this hit.
@export var source: Node2D

## Whether this hitbox can currently deal damage.
var _active: bool = false

## Entities already hit during the current activation.
var _hit_targets: Array[Node2D] = []


func _init() -> void:
	collision_layer = 16
	collision_mask = 8


func _ready() -> void:
	monitoring = false
	area_entered.connect(_on_area_entered)


## Enables the hitbox and starts a new hit window.
func activate() -> void:
	_hit_targets.clear()
	_active = true
	monitoring = true


## Disables the hitbox.
func deactivate() -> void:
	_active = false
	monitoring = false


func _on_area_entered(area: Area2D) -> void:
	if not _active:
		return

	if not area is Hurtbox:
		return

	var hurtbox: Hurtbox = area
	var target: Node2D = hurtbox.owner_entity

	if not is_instance_valid(target):
		return

	if _hit_targets.has(target):
		return

	if target == source:
		return

	_hit_targets.append(target)

	var impact := HitData.new(
		damage,
		source,
		global_position
	)

	hurtbox.receive_hit(impact)
