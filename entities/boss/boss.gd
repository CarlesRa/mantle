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
## Multiplier applied to attack cooldown duration.
@export var cooldown_multiplier: float = 1.0
## Seconds the boss ignores hits after taking damage.
@export var invulnerability_time: float = 1.0

var health: int = 0
var gravity: float = float(ProjectSettings.get_setting(GRAVITY_SETTING))
var target: Player
var is_dead: bool = false
var player_is_dead: bool = false
var invulnerability_left: float = 0.0
var active_attack: AttackData
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


## Duplicated from Player.start_attack(); if you change one, review the other.
func start_attack(data: AttackData) -> void:
	active_attack = data
	_hitbox.damage = maxi(0, roundi(float(data.damage) * damage_multiplier))
	var shape := RectangleShape2D.new()
	shape.size = data.hitbox_size
	_hitbox_collision.shape = shape
	_hitbox_collision.position = data.hitbox_offset
	_hitbox.activate()
	_audio_handler.play_attack(data)


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
	_hitbox.deactivate()
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

func _on_player_died() -> void:
	player_is_dead = true
