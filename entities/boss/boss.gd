class_name Boss
extends CharacterBody2D

const GRAVITY_SETTING: String = "physics/2d/default_gravity"
const TELEGRAPH_TINT_COLOR: Color = Color(1.0, 0.25, 0.25)

signal died

## Form whose visuals, attacks, and audio are used by this boss.
@export var form: PlayerForm
## Maximum health.
@export var max_health: int = 8
## Horizontal movement speed in px/s.
@export var move_speed: float = 100.0
## Distance at which the boss starts pursuing the player.
@export var detection_range: float = 320.0
## Distance at which the boss stops and attacks.
@export var attack_range: float = 110.0
## Multiplier applied to attack damage without changing AttackData.
@export var damage_multiplier: float = 1.0
## Optional hitbox timing for the primary attack animation.
@export var attack1_track: BossAttackTrack
## Optional hitbox timing for the secondary attack animation.
@export var attack2_track: BossAttackTrack
## Multiplier applied to attack cooldown duration.
@export var cooldown_multiplier: float = 1.0
## Seconds the boss ignores hits after taking damage.
@export var invulnerability_time: float = 1.0
@export_range(0.0, 1.0) var jump_chance: float = 0.33
@export var ground_ray: RayCast2D

var health: int = 0
var gravity: float = float(ProjectSettings.get_setting(GRAVITY_SETTING))
var target: Player
var is_dead: bool = false
var _death_finished: bool = false
var player_is_dead: bool = false
var invulnerability_left: float = 0.0
var active_attack: AttackData
var _active_attack_track: BossAttackTrack
var _applied_attack_keyframe: BossHitKeyframe
var _tracked_hitbox_active: bool = false
var _attack_has_hit_target: bool = false
var _projectile_launched: bool = false
var previous_attack: AttackData
var consecutive_attack_count: int = 0
var _visuals: Node2D
var _sprite: AnimatedSprite2D
var _body_collision: CollisionShape2D
var _hitbox: Hitbox
var _hitbox_collision: CollisionShape2D
var _hurtbox: Hurtbox
var _telegraph_tween: Tween
var _original_self_modulate: Color
var _audio_handler: BossAudioHandler


func _enter_tree() -> void:
	_visuals = $Visuals as Node2D
	_sprite = $Visuals/AnimatedSprite2D as AnimatedSprite2D
	_body_collision = $CollisionShape2D as CollisionShape2D
	_hitbox = $Visuals/Hitbox as Hitbox
	_hitbox.source = self
	_hitbox_collision = $Visuals/Hitbox/CollisionShape2D as CollisionShape2D
	_hurtbox = $Visuals/Hurtbox as Hurtbox
	_audio_handler = $BossAudioHandler as BossAudioHandler
	_hurtbox.owner_entity = self
	EventBus.player_died.connect(_on_player_died)


func _ready() -> void:
	health = max_health
	_original_self_modulate = _sprite.self_modulate
	target = get_tree().get_first_node_in_group("player") as Player
	_audio_handler.form = form
	# This listener runs after Hitbox delivers damage and disables it for the rest of the attack.
	_hitbox.area_entered.connect(_on_attack_hitbox_area_entered)


func _physics_process(delta: float) -> void:
	invulnerability_left = maxf(invulnerability_left - delta, 0.0)
	_visuals.visible = invulnerability_left <= 0.0 or int(invulnerability_left * 10.0) % 2 == 0
	if not is_on_floor():
		velocity.y += gravity * delta
	move_and_slide()


## Faces the target horizontally while preserving the current direction at zero distance.
func face_target() -> void:
	if not is_instance_valid(target):
		return
	var direction: float = target.global_position.x - global_position.x
	if not is_zero_approx(direction):
		_visuals.scale.x = signf(direction)


func finish_death() -> void:
	if _death_finished:
		return
	_death_finished = true
	_audio_handler.play_death()
	died.emit()
	set_physics_process(false)


func distance_to_target() -> float:
	if not is_instance_valid(target):
		return INF
	return global_position.distance_to(target.global_position)


func get_animation_duration(animation: StringName) -> float:
	var frames: SpriteFrames = _sprite.sprite_frames
	if not frames or not frames.has_animation(animation):
		return 0.0
	return frames.get_frame_count(animation) / maxf(frames.get_animation_speed(animation), 1.0)


func play_animation(animation: StringName, restart: bool = false) -> void:
	if not _sprite.sprite_frames or not _sprite.sprite_frames.has_animation(animation):
		return
	if restart:
		_sprite.stop()
	_sprite.play(animation)

func is_ground_within(distance: float) -> bool:
	if not is_instance_valid(ground_ray):
		return false

	ground_ray.force_raycast_update()

	if not ground_ray.is_colliding():
		return false

	var ground_distance: float = (
			ground_ray.global_position.distance_to(
			ground_ray.get_collision_point()
		)
	)

	return ground_distance <= distance


## Duplicated from Player.start_attack(); this activates the hitbox by keyframes instead.
func start_attack(data: AttackData) -> void:
	_prepare_attack(data)
	_active_attack_track = null
	_applied_attack_keyframe = null
	if data.projectile_scene:
		_hitbox.deactivate()
		_tracked_hitbox_active = false
		_connect_attack_frame_listener()
		return
	_set_hitbox_shape(data.hitbox_size, data.hitbox_offset)
	_hitbox.activate()
	_tracked_hitbox_active = true


func start_secondary_attack() -> void:
	var data: AttackData = form.secondary_attack
	if not data:
		return

	active_attack = data
	var track: BossAttackTrack = get_attack_track(data)

	if track:
		start_tracked_attack(data, track)
	else:
		start_attack(data)

	play_animation(data.animation, true)


func start_tracked_attack(data: AttackData, track: BossAttackTrack) -> void:
	_prepare_attack(data)
	_active_attack_track = track
	_applied_attack_keyframe = null
	_hitbox.deactivate()
	_tracked_hitbox_active = false
	_connect_attack_frame_listener()


func _connect_attack_frame_listener() -> void:
	var frame_callable: Callable = Callable(self, "_on_attack_frame_changed")
	if not _sprite.frame_changed.is_connected(frame_callable):
		_sprite.frame_changed.connect(frame_callable)


func _prepare_attack(data: AttackData) -> void:
	active_attack = data
	_attack_has_hit_target = false
	_projectile_launched = false
	_hitbox.damage = maxi(0, roundi(float(data.damage) * damage_multiplier))
	_audio_handler.play_attack(data)


func get_attack_track(data: AttackData) -> BossAttackTrack:
	if data == form.primary_attack:
		return attack1_track
	if data == form.secondary_attack:
		return attack2_track
	return null


func _on_attack_frame_changed() -> void:
	if not active_attack or _sprite.animation != active_attack.animation:
		return
	if active_attack.projectile_scene:
		if _projectile_launched or _sprite.frame < active_attack.launch_frame:
			return
		_projectile_launched = true
		_spawn_projectile(active_attack)
		return
	if not _active_attack_track:
		return
	var selected_keyframe: BossHitKeyframe = null
	for keyframe: BossHitKeyframe in _active_attack_track.keyframes:
		if keyframe and keyframe.frame <= _sprite.frame:
			if not selected_keyframe or keyframe.frame > selected_keyframe.frame:
				selected_keyframe = keyframe
	if not selected_keyframe or selected_keyframe == _applied_attack_keyframe:
		return
	_applied_attack_keyframe = selected_keyframe
	_set_hitbox_shape(selected_keyframe.size, selected_keyframe.offset)
	if selected_keyframe.active and not _tracked_hitbox_active and not _attack_has_hit_target:
		_hitbox.activate()
		_tracked_hitbox_active = true
	elif not selected_keyframe.active and _tracked_hitbox_active:
		_hitbox.deactivate()
		_tracked_hitbox_active = false


func _on_attack_hitbox_area_entered(area: Area2D) -> void:
	if not active_attack or not _tracked_hitbox_active or _attack_has_hit_target:
		return
	if not area is Hurtbox:
		return
	var target_entity: Node2D = (area as Hurtbox).owner_entity
	if not is_instance_valid(target_entity) or target_entity == self:
		return
	_attack_has_hit_target = true
	# Area2D monitoring is locked while its in/out signals are being dispatched.
	_hitbox.call_deferred("deactivate")
	_tracked_hitbox_active = false


func _spawn_projectile(data: AttackData) -> void:
	var projectile: Node2D = data.projectile_scene.instantiate() as Node2D
	if not projectile:
		push_error("Boss: projectile scene root must inherit from Node2D.")
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


func _set_hitbox_shape(size: Vector2, offset: Vector2) -> void:
	var shape := RectangleShape2D.new()
	shape.size = size
	_hitbox_collision.shape = shape
	# Visuals.scale.x mirrors local offsets for AttackData and keyframe tracks alike.
	_hitbox_collision.position = offset


func choose_attack() -> AttackData:
	var options: Array[AttackData] = []
	if form.primary_attack:
		options.append(form.primary_attack)
	if form.secondary_attack:
		options.append(form.secondary_attack)
	if options.size() > 1 and previous_attack and consecutive_attack_count >= 2:
		options.erase(previous_attack)
	var selected: AttackData = (
		options[randi_range(0, options.size() - 1)] if not options.is_empty() else null
	)
	if selected == previous_attack:
		consecutive_attack_count += 1
	else:
		previous_attack = selected
		consecutive_attack_count = 1 if selected else 0
	return selected


func finish_attack() -> void:
	var frame_callable: Callable = Callable(self, "_on_attack_frame_changed")
	if _sprite.frame_changed.is_connected(frame_callable):
		_sprite.frame_changed.disconnect(frame_callable)
	_hitbox.call_deferred("deactivate")
	_tracked_hitbox_active = false
	_active_attack_track = null
	_applied_attack_keyframe = null
	_attack_has_hit_target = false
	_projectile_launched = false
	active_attack = null


func receive_hit(hit_data: HitData) -> void:
	if is_dead or invulnerability_left > 0.0:
		return
	health = maxi(health - hit_data.damage, 0)
	# Duplicated from Player invulnerability feedback; if changed, review both.
	invulnerability_left = maxf(invulnerability_time, 0.0)
	_audio_handler.play_damage()
	if health <= 0:
		($StateMachine as StateMachine).change_to(BossStates.DEATH)
		return
	if ($StateMachine as StateMachine).current_state.name != BossStates.ATTACK:
		($StateMachine as StateMachine).change_to(BossStates.HIT)


func start_telegraph_tint(duration: float) -> void:
	cancel_telegraph_tint()
	_telegraph_tween = create_tween()
	_telegraph_tween.tween_property(
		_sprite, "self_modulate", TELEGRAPH_TINT_COLOR, duration * 0.35
	)
	_telegraph_tween.tween_property(
		_sprite, "self_modulate", _original_self_modulate, duration * 0.65
	)


func cancel_telegraph_tint() -> void:
	if is_instance_valid(_telegraph_tween) and _telegraph_tween.is_running():
		_telegraph_tween.kill()
	_telegraph_tween = null
	_sprite.self_modulate = _original_self_modulate


func die() -> void:
	if is_dead:
		return
	is_dead = true
	cancel_telegraph_tint()
	finish_attack()
	_hitbox.set_deferred("monitoring", false)
	_hurtbox.set_deferred("monitoring", false)
	_hurtbox.set_deferred("monitorable", false)
	collision_layer = 0
	collision_mask = 0
	_body_collision.set_deferred("disabled", true)
	set_physics_process(false)

func _on_player_died() -> void:
	if is_dead:
		return
	player_is_dead = true
	finish_attack()
	velocity.x = 0.0
	play_animation(&"idle", true)
	($StateMachine as StateMachine).change_to(BossStates.IDLE)
