## Plays audio configured by the Player's current form.
class_name PlayerAudioHandler
extends Node

@export var animated_sprite: AnimatedSprite2D

var current_audio_set: PlayerAudioSet
var _form_loop_player: AudioStreamPlayer


func _ready() -> void:
	_form_loop_player = AudioStreamPlayer.new()
	_form_loop_player.name = "FormLoopPlayer"
	_form_loop_player.bus = AudioManager.SFX
	add_child(_form_loop_player)
	EventBus.player_jumped.connect(_on_player_jumped)
	EventBus.player_landed.connect(_on_player_landed)
	EventBus.player_hit.connect(_on_player_hit)
	EventBus.player_died.connect(_on_player_died)
	EventBus.player_form_changed.connect(_on_player_form_changed)
	EventBus.player_transform_started.connect(_on_player_transform_started)
	EventBus.player_attacked.connect(_on_player_attacked)
	if animated_sprite != null:
		animated_sprite.frame_changed.connect(_on_sprite_frame_changed)
	var player: Player = get_parent() as Player
	if player != null and player.form != null:
		_on_player_form_changed(player.form)


func _on_player_jumped() -> void:
	_play_sfx(current_audio_set.jump_sfx if current_audio_set != null else null)


func _on_player_landed() -> void:
	_play_sfx(current_audio_set.land_sfx if current_audio_set != null else null)


func _on_player_hit() -> void:
	_play_sfx(current_audio_set.damage_sfx if current_audio_set != null else null)


func _on_player_died() -> void:
	_form_loop_player.stop()
	_play_sfx(current_audio_set.death_sfx if current_audio_set != null else null)


func _on_player_form_changed(form: PlayerForm) -> void:
	current_audio_set = form.audio if form != null else null
	var loop_sfx: SoundEffect = form.form_loop_sfx if form != null else null
	var loop_stream: AudioStream = loop_sfx.stream if loop_sfx != null else null
	if _form_loop_player.stream == loop_stream and _form_loop_player.playing:
		return
	_form_loop_player.stop()
	_form_loop_player.stream = loop_stream
	if loop_sfx != null and loop_stream != null:
		_form_loop_player.volume_db = loop_sfx.volume_db
		_form_loop_player.play()

func _on_player_transform_started(form: PlayerForm, _duration: float) -> void:
	var form_audio: PlayerAudioSet = form.audio if form != null else null
	_play_sfx(form_audio.form_change_sfx if form_audio != null else null)


func _on_player_attacked(attack: AttackData) -> void:
	if attack == null:
		return
	_play_sfx(attack.sfx)


func _on_sprite_frame_changed() -> void:
	if animated_sprite == null or animated_sprite.frame == 0 or current_audio_set == null:
		return
	for cue: FrameCue in current_audio_set.frame_cues:
		if cue == null:
			continue
		if cue.animation == animated_sprite.animation and cue.frame == animated_sprite.frame:
			_play_sfx(cue.sound)
			return


func _play_sfx(sound: SoundEffect) -> void:
	if sound == null:
		return
	AudioManager.play_sfx(sound)
