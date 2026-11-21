class_name Player
extends CharacterBody2D

const GRAVITY_SETTING: String = "physics/2d/default_gravity"
const WHITE_FLASH_SHADER: Shader = preload("res://entities/player/shaders/white_flash.gdshader")

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
## Portion of the flash spent whitening the old form before the swap.
@export_range(0.0, 1.0) var transform_peak_fraction: float = 0.35

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
var transform_tween: Tween
var _invulnerable_left: float = 0.0
var _transform_invulnerable: bool = false
var _pending_form: PlayerForm
var _transform_material: ShaderMaterial
var _original_sprite_material: Material
var _transform_swapped: bool = false
const TRANSFORM_FIT_RETRY_TIME: float = 0.15

## Attack currently being executed. Null when no attack is active.
var _active_attack: AttackData
## Prevents the same animation frame from spawning multiple projectiles.
var _projectile_launched: bool = false

var _visuals: Node2D
var _sprite: AnimatedSprite2D
var _collision: CollisionShape2D
var _hitbox: Hitbox
var _hitbox_collision: CollisionShape2D
var _hurtbox: Hurtbox
var _hurtbox_collision: CollisionShape2D


# Nodes are cached on enter_tree because the StateMachine (a child) runs its
# first state before this node's _ready.
func _enter_tree() -> void:
	add_to_group("player")
	_visuals = $Visuals as Node2D
	_sprite = $Visuals/AnimatedSprite2D as AnimatedSprite2D
	_collision = $CollisionShape2D as CollisionShape2D
	_hitbox = $Visuals/Hitbox as Hitbox
	_hitbox.source = self
	_hitbox_collision = $Visuals/Hitbox/CollisionShape2D as CollisionShape2D
	_hurtbox = $Visuals/Hurtbox
	_hurtbox.owner_entity = self
	_hurtbox_collision = $Visuals/Hurtbox/CollisionShape2D as CollisionShape2D
	fall_speed_limit = max_fall_speed
	if initial_form:
		_apply_form(initial_form)

func _ready() -> void:
	health = max_health
	$AudioListener2D.make_current()
	_sprite.frame_changed.connect(_on_sprite_frame_changed)
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
		var current_fall_speed_limit: float = fall_speed_limit
		if glide_fall_speed > 0.0 and Input.is_action_pressed("jump") and velocity.y > 0.0:
			current_fall_speed_limit = minf(current_fall_speed_limit, glide_fall_speed)
		velocity.y = minf(velocity.y, current_fall_speed_limit)

	move_and_slide()

## Switches to another form. Returns false if it is already the current form
## or if the new collision shape does not fit where the player stands.
func change_form(new_form: PlayerForm) -> bool:
	if is_dead or is_transforming() or not new_form or new_form == form:
		return false
	if not _fits(new_form):
		return false
	finish_attack()
	_pending_form = new_form
	_transform_invulnerable = true
	start_transform_tween()
	return true

func is_transforming() -> bool:
	return transform_tween != null and transform_tween.is_running()

func start_transform_tween() -> void:
	_transform_swapped = false
	_original_sprite_material = _sprite.material
	_transform_material = ShaderMaterial.new()
	_transform_material.shader = WHITE_FLASH_SHADER
	_transform_material.set_shader_parameter("white_amount", 0.0)
	_sprite.material = _transform_material
	var duration: float = _pending_form.get_transform_duration()
	var peak_fraction: float = clampf(transform_peak_fraction, 0.01, 0.99)
	EventBus.player_transform_started.emit(_pending_form, duration)
	transform_tween = create_tween()
	transform_tween.tween_method(_set_transform_white_amount, 0.0, 1.0, duration * peak_fraction)
	transform_tween.tween_callback(_try_swap_transform_form)
	transform_tween.finished.connect(_on_transform_peak_finished.bind(duration, peak_fraction))

func _set_transform_white_amount(amount: float) -> void:
	if _transform_material:
		_transform_material.set_shader_parameter("white_amount", amount)

func _try_swap_transform_form() -> void:
	if not _pending_form or _transform_swapped or not _fits(_pending_form):
		return
	var new_form: PlayerForm = _pending_form
	if _active_attack:
		finish_attack()
	_apply_form(new_form)
	_transform_swapped = true
	EventBus.player_form_changed.emit(new_form)
	_refresh_current_state_animation()

func _retry_transform_swap(_elapsed: float) -> void:
	if not _transform_swapped:
		_try_swap_transform_form()

func _on_transform_peak_finished(duration: float, peak_fraction: float) -> void:
	if _transform_swapped:
		_start_transform_fade(duration * (1.0 - peak_fraction))
		return
	transform_tween = create_tween()
	transform_tween.tween_method(_retry_transform_swap, 0.0, TRANSFORM_FIT_RETRY_TIME, TRANSFORM_FIT_RETRY_TIME)
	transform_tween.finished.connect(_on_transform_retry_finished.bind(duration, peak_fraction))

func _on_transform_retry_finished(duration: float, peak_fraction: float) -> void:
	_start_transform_fade(duration * (1.0 - peak_fraction))

func _start_transform_fade(duration: float) -> void:
	transform_tween = create_tween()
	transform_tween.tween_method(_set_transform_white_amount, 1.0, 0.0, duration)
	transform_tween.finished.connect(_on_transform_tween_finished)

func _refresh_current_state_animation() -> void:
	var current_state: State = ($StateMachine as StateMachine).current_state
	if not current_state:
		return
	match current_state.name:
		PlayerStates.IDLE:
			play_animation(PlayerAnimations.IDLE, true)
		PlayerStates.MOVE:
			play_animation(PlayerAnimations.RUN, true)
		PlayerStates.JUMP:
			play_animation(PlayerAnimations.JUMP, true)
		PlayerStates.FALL:
			play_animation(PlayerAnimations.FALL, true)
		PlayerStates.HIT:
			play_animation(PlayerAnimations.HIT, true)
		PlayerStates.ATTACK, PlayerStates.ATTACK_SECONDARY:
			var attack_state := current_state as PlayerAttackState
			var attack: AttackData = get_attack(attack_state.slot) if attack_state else null
			if attack:
				play_animation(attack.animation, true)
			else:
				play_animation(PlayerAnimations.IDLE, true)

func _on_transform_tween_finished() -> void:
	_cleanup_transform_effect()

func cancel_transform() -> void:
	if transform_tween and transform_tween.is_running():
		transform_tween.kill()
	_cleanup_transform_effect()

func _cleanup_transform_effect() -> void:
	_set_transform_white_amount(0.0)
	_sprite.material = _original_sprite_material
	if not _transform_swapped and not is_dead:
		_sprite.play()
	_transform_material = null
	_original_sprite_material = null
	_pending_form = null
	_transform_swapped = false
	_transform_invulnerable = false
	transform_tween = null

## Plays an animation of the current form. Does nothing if it does not exist.
func play_animation(animation: StringName, restart: bool = false) -> void:
	if not _sprite.sprite_frames or not _sprite.sprite_frames.has_animation(animation):
		return
	if restart:
		_sprite.stop()
	_sprite.play(animation)

## Turns the sprite towards the horizontal direction. 0 keeps the current side.
func face(direction: float) -> void:
	if is_zero_approx(direction) or not form:
		return
	_visuals.scale.x = signf(direction)
	_collision.position = _get_collision_position(form)

## Spends one air jump. Returns false if none is left.
func consume_air_jump() -> bool:
	if air_jumps_left <= 0:
		return false
	air_jumps_left -= 1
	return true

## True if the candidate form's collision shape does not overlap the world.
func _fits(candidate: PlayerForm) -> bool:
	var shape: RectangleShape2D = RectangleShape2D.new()
	# Slightly smaller so standing on the floor is not counted as overlapping.
	shape.size = candidate.collision_size - Vector2(2.0, 2.0)

	var query: PhysicsShapeQueryParameters2D = PhysicsShapeQueryParameters2D.new()
	query.shape = shape
	query.transform = Transform2D(0.0, global_position + _get_collision_position(candidate))
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
	shape.size = new_form.collision_size
	_collision.shape = shape
	_collision.position = _get_collision_position(form)

	var hurtbox_shape := RectangleShape2D.new()
	hurtbox_shape.size = new_form.hurtbox_size
	_hurtbox_collision.shape = hurtbox_shape

	_hurtbox_collision.position = Vector2(
		new_form.hurtbox_offset.x,
		-new_form.hurtbox_size.y / 2.0 + new_form.hurtbox_offset.y,
	)

	var current_animation: StringName = _sprite.animation
	_sprite.sprite_frames = new_form.sprite_frames
	_sprite.offset = new_form.sprite_offset
	if not _sprite.sprite_frames.has_animation(current_animation):
		current_animation = PlayerAnimations.IDLE
	_sprite.play(current_animation)

## Calculates the collision position for a given form and facing direction.
func _get_collision_position(target_form: PlayerForm) -> Vector2:
	var direction: float = signf(_visuals.scale.x)
	if is_zero_approx(direction):
		direction = 1.0

	var offset: Vector2 = target_form.collision_offset
	offset.x *= direction

	return Vector2(offset.x, -target_form.collision_size.y / 2.0 + offset.y)


func set_attack_active(active: bool) -> void:
	if active:
		_hitbox.activate()
	else:
		_hitbox.deactivate()

## Attack data for a button slot (0 = primary, 1 = secondary). Null if none.
func get_attack(slot: int) -> AttackData:
	return form.primary_attack if slot == 0 else form.secondary_attack


## Sets up a melee or projectile attack.
func start_attack(data: AttackData) -> void:
	if is_transforming():
		return
	_active_attack = data
	_projectile_launched = false

	# Projectile attacks do not use the player's fixed hitbox.
	if data.projectile_scene:
		set_attack_active(false)
		return

	_hitbox.damage = data.damage

	# Melee attacks keep the existing hitbox behavior.
	var shape: RectangleShape2D = RectangleShape2D.new()
	shape.size = data.hitbox_size
	_hitbox_collision.shape = shape
	_hitbox_collision.position = data.hitbox_offset
	set_attack_active(true)


## Checks whether the current animation frame launches a projectile.
func _on_sprite_frame_changed() -> void:
	if not _active_attack or not _active_attack.projectile_scene:
		return

	if _projectile_launched:
		return

	if _sprite.animation != _active_attack.animation:
		return

	if _sprite.frame < _active_attack.launch_frame:
		return

	_projectile_launched = true
	_spawn_projectile(_active_attack)


## Creates and launches the projectile belonging to the current attack.
func _spawn_projectile(data: AttackData) -> void:
	var projectile: Node2D = data.projectile_scene.instantiate() as Node2D

	if not projectile:
		push_error("Projectile scene root must inherit from Node2D.")
		return

	get_tree().current_scene.add_child(projectile)

	var direction: float = signf(_visuals.scale.x)
	if is_zero_approx(direction):
		direction = 1.0

	var offset: Vector2 = data.projectile_offset
	offset.x *= direction

	projectile.global_position = global_position + offset

	if projectile.has_method("launch"):
		projectile.launch(direction, data, self)


## Clears the active attack.
func finish_attack() -> void:
	set_attack_active(false)
	_active_attack = null
	_projectile_launched = false

func receive_hit(hit_data: HitData) -> void:
	take_hit(hit_data.source_position, hit_data.damage)

## Applies damage to the player.
## Ignored while dead or invulnerable. Otherwise reduces health, stores
## knockback away from [param source_position] and transitions to Hit,
## or to Death if health reaches zero. Emits player_hit when damage is applied.
func take_hit(source_position: Vector2, damage: int = 1) -> void:
	if is_dead or _invulnerable_left > 0.0 or _transform_invulnerable:
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
	cancel_transform()
	($StateMachine as StateMachine).change_to(PlayerStates.DEATH)
