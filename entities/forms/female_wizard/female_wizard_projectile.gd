class_name FemaleWizardProjectile
extends Area2D

const FLY_SFX: SoundEffect = preload("res://entities/forms/female_wizard/audio/projectile_fly_sound.tres")
const IMPACT_SFX: SoundEffect = preload("res://entities/forms/female_wizard/audio/projectile_impact_sound.tres")

@export var speed: float = 500.0
## Seconds the projectile lives if it does not hit anything.
@export var lifetime: float = 3.0
## Seconds before expiring during which the projectile fades out.
@export var fade_time: float = 0.5

var _direction: float = 0.0
var _source: Node2D
var _launched: bool = false
var _impacted: bool = false
var _time_left: float = 0.0
var _hitbox: Hitbox
var _flight_audio: AudioStreamPlayer2D

func _ready() -> void:
	_time_left = lifetime
	body_entered.connect(_on_body_entered)
	_hitbox = $Hitbox as Hitbox
	_hitbox.area_entered.connect(_on_hurtbox_entered)
	_flight_audio = $FlightAudio as AudioStreamPlayer2D

func launch(direction: float, attack_data: AttackData, source: Node2D) -> void:
	_direction = signf(direction)
	_source = source
	_hitbox.damage = attack_data.damage
	_hitbox.source = source
	_hitbox.activate()
	_launched = true
	$AnimatedSprite2D.flip_h = _direction < 0.0
	_flight_audio.stream = FLY_SFX.stream
	_flight_audio.volume_db = FLY_SFX.volume_db
	_flight_audio.play()

func _physics_process(delta: float) -> void:
	if not _launched:
		return

	global_position.x += _direction * speed * delta

	_time_left -= delta
	if _time_left <= 0.0:
		_flight_audio.stop()
		queue_free()
	# Fade out during the last fade_time seconds.
	if fade_time > 0.0:
		modulate.a = clampf(_time_left / fade_time, 0.0, 1.0)
	else:
		modulate.a = 1.0

## Solid body collisions destroy the projectile, except for its owner.
func _on_body_entered(body: Node2D) -> void:
	if body == _source:
		return
	_play_impact_and_destroy()

## A valid hurtbox collision is handled by Hitbox and consumes this projectile.
func _on_hurtbox_entered(area: Area2D) -> void:
	if area is Hurtbox:
		var hurtbox: Hurtbox = area
		if hurtbox.owner_entity == _source:
			return
		_play_impact_and_destroy()

func _play_impact_and_destroy() -> void:
	if _impacted:
		return
	_impacted = true
	_flight_audio.stop()
	AudioManager.play_sfx(IMPACT_SFX)
	queue_free()
