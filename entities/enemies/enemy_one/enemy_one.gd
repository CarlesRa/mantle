class_name EnemyOne
extends CharacterBody2D

const GRAVITY_SETTING: String = "physics/2d/default_gravity"
const ANIM_IDLE: StringName = &"idle"
const ANIM_WALK: StringName = &"walk"
const ANIM_ATTACK: StringName = &"attack"
const ANIM_HIT: StringName = &"hit"
const ANIM_DEATH: StringName = &"death"



## Horizontal speed in px/s.
@export var move_speed: float = 60.0
## Maximum downward speed in px/s.
@export var max_fall_speed: float = 800.0
## Side the enemy faces when the level starts.
@export_enum("Right:1", "Left:-1") var initial_direction: int = 1

## When true, the enemy guards its spot instead of patrolling or chasing.
@export var stationary: bool = false

## Facing direction: 1.0 is right, -1.0 is left.
var direction: float = 1.0
var gravity: float = float(ProjectSettings.get_setting(GRAVITY_SETTING))

var _visuals: Node2D
var _sprite: AnimatedSprite2D
var _wall_ray: RayCast2D
var _player_ray: RayCast2D
var _floor_ray: RayCast2D
var _attack_hitbox: Area2D
var _state_machine: StateMachine
##Player enemy Spotted
var target: Node2D

func _enter_tree() -> void:
	_visuals = $Visuals
	_sprite = $Visuals/AnimatedSprite2D
	_wall_ray = $Visuals/WallRay
	_floor_ray = $Visuals/FloorRay
	_player_ray = $Visuals/PlayerRay
	_attack_hitbox = $Visuals/AttackHitBox
	_state_machine = $StateMachine
	
func _ready() -> void:
	face(float(initial_direction))

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

## Returns true when the player is in front, within reach and not behind a wall.
func can_see_player() -> bool:
	_player_ray.force_raycast_update()
	var collider := _player_ray.get_collider()
	if collider is Player:
		target = collider
		return true
	return false

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

## Returns true when anim_name is not the current animation or has stopped playing.
func is_animation_finished(anim_name: StringName) -> bool:
	return _sprite.animation != anim_name or not _sprite.is_playing()

## Stop all collision with other object
func disable_collision() -> void:
	set_physics_process(false)
	velocity = Vector2.ZERO
	collision_layer = 0
	collision_mask = 0
	$CollisionShape2D.set_deferred(&"disabled", true)
	_attack_hitbox.set_deferred(&"monitoring", false)

## Returns the frame index of the current animation.
func get_animation_frame() -> int:
	return _sprite.frame

## Calls take_hit on every body inside the attack hitbox that implements it.
func strike(damage: int) -> void:
	for body: Node2D in _attack_hitbox.get_overlapping_bodies():
		if body.has_method(&"take_hit"):
			body.call(&"take_hit", global_position, damage)


## Kills the enemy right away, for scripted events such as traps.
func die() -> void:
	_state_machine.change_to(EnemyOneStates.DEATH)
