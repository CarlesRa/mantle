## Fixed portal that turns the player into the assigned form.
## Place it with its origin on the ground.
class_name FormPortal
extends Area2D

signal reward_taken(form: PlayerForm)

const PORTAL_TINT_SHADER: Shader = preload("res://entities/portal/portal_tint.gdshader")

@onready var _sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var _audio_player: AudioStreamPlayer2D = $AudioStreamPlayer2D
var _tint_material: ShaderMaterial
var _audio_tween: Tween
var _fade_tween: Tween
var _is_active: bool = true
var _reward_emitted: bool = false

@export var starts_active: bool = true
@export var form: PlayerForm:
	set(value):
		form = value
		_update_sprite_color()
@export var sfx: SoundEffect

func _ready() -> void:
	_tint_material = ShaderMaterial.new()
	_tint_material.shader = PORTAL_TINT_SHADER
	_sprite.material = _tint_material
	_update_sprite_color()
	set_active(starts_active)

func set_active(value: bool, fade_duration: float = 0.0) -> void:
	_is_active = value
	visible = value
	_reward_emitted = false
	if _fade_tween and _fade_tween.is_valid():
		_fade_tween.kill()
	if value:
		_play_portal_sound()
		if fade_duration > 0.0:
			modulate.a = 0.0
			set_physics_process(false)
			_fade_tween = create_tween()
			_fade_tween.tween_property(self, "modulate:a", 1.0, fade_duration)
			_fade_tween.finished.connect(func() -> void: set_physics_process(true))
		else:
			modulate.a = 1.0
			set_physics_process(true)
	else:
		set_physics_process(false)
		_stop_portal_sound()

func _play_portal_sound() -> void:
	if not _audio_player:
		return
	if sfx and sfx.stream:
		_audio_player.stream = sfx.stream
	if not _audio_player.stream:
		return
	if _audio_tween and _audio_tween.is_valid():
		_audio_tween.kill()
	var target_db: float = (sfx.volume_db if sfx else 0.0) + 6.0
	_audio_player.volume_db = -80.0
	_audio_player.play()
	_audio_tween = create_tween()
	_audio_tween.tween_property(_audio_player, "volume_db", target_db, 0.6)

func _stop_portal_sound() -> void:
	if _audio_tween and _audio_tween.is_valid():
		_audio_tween.kill()
	if _audio_player:
		_audio_player.stop()

func _update_sprite_color() -> void:
	if is_instance_valid(_tint_material):
		_tint_material.set_shader_parameter(
			"tint_color", form.portal_color if form else Color.WHITE
		)

# Polled instead of using body_entered so a transformation that was blocked
# (the new hitbox did not fit) is retried while the player stays inside.
func _physics_process(_delta: float) -> void:
	if not _is_active or not form:
		return
	for body: Node2D in get_overlapping_bodies():
		var player: Player = body as Player
		if not player or _reward_emitted:
			continue
		if player.change_form(form):
			_reward_emitted = true
			reward_taken.emit(form)
