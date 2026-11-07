class_name Player
extends CharacterBody2D

const GRAVITY_SETTING: String = "physics/2d/default_gravity"

## Maximum player health.
@export var max_health: int = 3
## Form the player starts with.
@export var initial_form: PlayerForm
## Maximum downward speed in px/s.
@export var max_fall_speed: float = 800.0
## Time in seconds a jump press is remembered before landing. 0.0 disables it.
@export var jump_buffer_time: float = 0.1
## Time in seconds after leaving a ledge during which a jump is still allowed.
@export var coyote_time: float = 0.08
## Seconds the player cannot be hit again after taking a hit.
@export var invulnerability_time: float = 1.0

var health: int = 0
var is_dead: bool = false

## Current form. Use change_form() to modify it.
var form: PlayerForm

## Stats copied from the current form.
var move_speed: float = 200.0
var jump_velocity: float = -400.0
var glide_fall_speed: float = 0.0
var max_air_jumps: int = 0

var gravity: float = float(ProjectSettings.get_setting(GRAVITY_SETTING))

## Downward speed limit for the current frame. States lower it to glide.
var fall_speed_limit: float = 800.0
var air_jumps_left: int = 0
var coyote_left: float = 0.0
## Set by take_hit(). The Hit state applies it as velocity on enter.
var knockback: Vector2 = Vector2.ZERO
var _invulnerable_left: float = 0.0

var _visuals: Node2D
var _sprite: AnimatedSprite2D
var _collision: CollisionShape2D

# Nodes are cached on enter_tree because the StateMachine (a child) runs its
# first state before this node's _ready.
func _enter_tree() -> void:
	_visuals = $Visuals as Node2D
	_sprite = $Visuals/AnimatedSprite2D as AnimatedSprite2D
	_collision = $CollisionShape2D as CollisionShape2D
	fall_speed_limit = max_fall_speed
	if initial_form:
		_apply_form(initial_form)

func _ready() -> void:
	health = max_health
	if form:
		# Deferred so every listener in the scene is ready.
		EventBus.player_form_changed.emit.call_deferred(form)

func _physics_process(delta: float) -> void:
	_invulnerable_left = maxf(_invulnerable_left - delta, 0.0)
	_visuals.visible = _invulnerable_left <= 0.0 or int(_invulnerable_left * 10.0) % 2 == 0
	if is_on_floor() and velocity.y >= 0.0:
		coyote_left = coyote_time
		air_jumps_left = max_air_jumps
	else:
		coyote_left = maxf(coyote_left - delta, 0.0)
		velocity.y += gravity * delta
		velocity.y = minf(velocity.y, fall_speed_limit)

	move_and_slide()

## Switches to another form. Returns false if it is already the current form
## or if the new hitbox does not fit where the player stands.
func change_form(new_form: PlayerForm) -> bool:
	if is_dead or not new_form or new_form == form:
		return false
	if not _fits(new_form):
		return false
	_apply_form(new_form)
	_flash()
	EventBus.player_form_changed.emit(new_form)
	return true

## Plays an animation of the current form. Does nothing if it does not exist.
func play_animation(animation: StringName, restart: bool = false) -> void:
	if not _sprite.sprite_frames or not _sprite.sprite_frames.has_animation(animation):
		return
	if restart:
		_sprite.stop()
	_sprite.play(animation)

## Turns the sprite towards the horizontal direction. 0 keeps the current side.
func face(direction: float) -> void:
	if is_zero_approx(direction):
		return
	_visuals.scale.x = signf(direction)

## Spends one air jump. Returns false if none is left.
func consume_air_jump() -> bool:
	if air_jumps_left <= 0:
		return false
	air_jumps_left -= 1
	return true

## True if the hitbox of the candidate form does not overlap the world.
func _fits(candidate: PlayerForm) -> bool:
	var shape: RectangleShape2D = RectangleShape2D.new()
	# Slightly smaller so standing on the floor is not counted as overlapping.
	shape.size = candidate.hitbox_size - Vector2(2.0, 2.0)
	var query: PhysicsShapeQueryParameters2D = PhysicsShapeQueryParameters2D.new()
	query.shape = shape
	query.transform = Transform2D(0.0, global_position + Vector2(0.0, -candidate.hitbox_size.y / 2.0))
	query.collision_mask = collision_mask
	query.exclude = [get_rid()]
	return get_world_2d().direct_space_state.intersect_shape(query, 1).is_empty()

## Copies everything a form defines into the player: stats, hitbox, sprite
## frames and sprite offset. Does not check that the new hitbox fits and does
## not emit player_form_changed; change_form() does both, so call that instead
## unless it is the initial form.
func _apply_form(new_form: PlayerForm) -> void:
	form = new_form
	move_speed = new_form.move_speed
	jump_velocity = new_form.jump_velocity
	glide_fall_speed = new_form.glide_fall_speed
	max_air_jumps = new_form.air_jumps
	air_jumps_left = mini(air_jumps_left, max_air_jumps)

	# A new shape per form: sub-resources of a scene are shared by all instances.
	var shape: RectangleShape2D = RectangleShape2D.new()
	shape.size = new_form.hitbox_size
	_collision.shape = shape
	_collision.position = Vector2(0.0, -new_form.hitbox_size.y / 2.0)

	#var current_animation: StringName = _sprite.animation
	_sprite.sprite_frames = new_form.sprite_frames
	_sprite.offset = new_form.sprite_offset
	#if not _sprite.sprite_frames.has_animation(current_animation):
		#current_animation = PlayerAnimations.IDLE
	#_sprite.play(current_animation)

func _flash() -> void:
		var tween: Tween = create_tween()
		tween.tween_property(_visuals, "modulate", Color.WHITE, 0.3).from(Color(3.0, 3.0, 3.0))

## Tries to hurt the player. Called by anything dangerous (hazards, enemies).
## Ignored while dead or invulnerable. Otherwise it takes [param damage] from
## health, stores a knockback away from [param source_position] and goes to
## Hit, or to Death if health reaches zero. Emits player_hit when it lands.
func take_hit(source_position: Vector2, damage: int = 1) -> void:
	if is_dead or _invulnerable_left > 0.0:
		return
	var side: float = signf(global_position.x - source_position.x)
	knockback = Vector2(side * 150.0, -200.0)
	health -= damage
	EventBus.player_hit.emit()
	if health <= 0:
		_die()
		return
	_invulnerable_left = invulnerability_time
	($StateMachine as StateMachine).change_to(PlayerStates.HIT)

func _die() -> void:
	is_dead = true
	_invulnerable_left = 0.0
	($StateMachine as StateMachine).change_to(PlayerStates.DEATH)
