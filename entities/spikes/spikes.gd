## Spike trap that hurts the player on contact while its spikes are out.
## It can stay out all the time or go in and out in a loop.
class_name Spikes
extends Node2D

const ANIM_CYCLE: StringName = &"cycle"

## When true, the spikes go in and out in a loop. When false, they stay out.
@export var moving: bool = false
## Damage dealt to the player on each hit.
@export var damage: int = 1
## Seconds to wait before the first cycle, to desync several moving traps.
@export var start_delay: float = 0.0
## First animation frame where the spikes are out enough to hurt.
@export var danger_from_frame: int = 2
## Last animation frame where the spikes are out enough to hurt.
@export var danger_to_frame: int = 6
## Frame shown when the spikes do not move.
@export var static_frame: int = 4

var _sprite: AnimatedSprite2D
var _damage_zone: Area2D
var _delay_left: float = 0.0

func _ready() -> void:
	_sprite = $AnimatedSprite2D
	_damage_zone = $DamageZone
	_sprite.animation = ANIM_CYCLE
	_sprite.stop()
	if moving:
		_sprite.frame = 0
		_delay_left = start_delay
	else:
		_sprite.frame = static_frame

func _physics_process(delta: float) -> void:
	if moving and not _sprite.is_playing():
		_delay_left -= delta
		if _delay_left <= 0.0:
			_sprite.play(ANIM_CYCLE)

	if not _is_dangerous():
		return
	for body: Node2D in _damage_zone.get_overlapping_bodies():
		if body.has_method(&"take_hit"):
			body.call(&"take_hit", global_position, damage)

func _is_dangerous() -> bool:
	if not moving:
		return true
	if not _sprite.is_playing():
		return false
	return _sprite.frame >= danger_from_frame and _sprite.frame <= danger_to_frame
