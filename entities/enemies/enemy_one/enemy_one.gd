class_name EnemyOne
extends CharacterBody2D

const GRAVITY_SETTING: String = "physics/2d/default_gravity"
const ANIM_IDLE: StringName = &"idle"
const ANIM_WALK: StringName = &"walk"

## Horizontal speed in px/s.
@export var move_speed: float = 60.0
## Maximum downward speed in px/s.
@export var max_fall_speed: float = 800.0

## Facing direction: 1.0 is right, -1.0 is left.
var direction: float = 1.0
var gravity: float = float(ProjectSettings.get_setting(GRAVITY_SETTING))

var _visuals: Node2D
var _sprite: AnimatedSprite2D
var _wall_ray: RayCast2D
var _floor_ray: RayCast2D

func _enter_tree() -> void:
	_visuals = $Visuals
	_sprite = $Visuals/AnimatedSprite2D
	_wall_ray = $Visuals/WallRay
	_floor_ray = $Visuals/FloorRay

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y += gravity * delta
		velocity.y = minf(velocity.y, max_fall_speed)

	move_and_slide()

## Returns true when there is a wall ahead, or no floor ahead while on the ground.
func should_turn() -> bool:	
	_wall_ray.force_raycast_update()
	_floor_ray.force_raycast_update()
	if _wall_ray.is_colliding():
		return true
	return is_on_floor() and not _floor_ray.is_colliding()

## Flips the facing direction.
func turn_around() -> void:
	face(-direction)

## Faces the sign of new_direction. Zero keeps the current side.
func face(new_direction: float) -> void:
	if is_zero_approx(new_direction):
		return
	direction = signf(new_direction)
	_visuals.scale.x = direction

## Plays an animation only if the current SpriteFrames has it.
func play_animation(anim_name: StringName) -> void:
	if _sprite.sprite_frames and _sprite.sprite_frames.has_animation(anim_name):
		_sprite.play(anim_name)
