class_name BossAudioHandler
extends Node

@export var animated_sprite: AnimatedSprite2D
@export var form: PlayerForm

func _ready() -> void:
	if animated_sprite:
		animated_sprite.frame_changed.connect(_on_sprite_frame_changed)

func play_damage() -> void:
	_play_sfx(form.audio.damage_sfx if form and form.audio else null)

func play_death() -> void:
	_play_sfx(form.audio.death_sfx if form and form.audio else null)

func play_attack(data: AttackData) -> void:
	if data:
		_play_sfx(data.sfx)

func _on_sprite_frame_changed() -> void:
	if not animated_sprite or animated_sprite.frame == 0 or not form or not form.audio:
		return
	for cue: FrameCue in form.audio.frame_cues:
		if cue and cue.animation == animated_sprite.animation and cue.frame == animated_sprite.frame:
			_play_sfx(cue.sound)
			return

func _play_sfx(sound: SoundEffect) -> void:
	if sound:
		AudioManager.play_sfx(sound)
