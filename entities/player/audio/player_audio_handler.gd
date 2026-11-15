## Selects the audio data associated with the Player's current form.
class_name PlayerAudioHandler
extends Node

const BASE_FORM: PlayerForm = preload("res://entities/player/forms/base/base.tres")
const MALE_WIZARD_FORM: PlayerForm = preload(
	"res://entities/player/forms/male_wizard/male_wizard.tres"
)
const FEMALE_WIZARD_FORM: PlayerForm = preload(
	"res://entities/player/forms/female_wizard/female_wizard.tres"
)

@export var base_audio: PlayerAudioSet
@export var male_wizard_audio: PlayerAudioSet
@export var female_wizard_audio: PlayerAudioSet

var current_audio_set: PlayerAudioSet


func _ready() -> void:
	EventBus.player_form_changed.connect(_on_player_form_changed)


func _on_player_form_changed(form: PlayerForm) -> void:
	if form == BASE_FORM:
		current_audio_set = base_audio
	elif form == MALE_WIZARD_FORM:
		current_audio_set = male_wizard_audio
	elif form == FEMALE_WIZARD_FORM:
		current_audio_set = female_wizard_audio
	else:
		current_audio_set = null


## AnimationPlayer Call Method Track entry points.
func play_jump_sfx() -> void:
	pass


func play_land_sfx() -> void:
	pass


func play_run_sfx() -> void:
	pass


func play_primary_attack_sfx() -> void:
	pass


func play_secondary_attack_sfx() -> void:
	pass


func play_damage_sfx() -> void:
	pass


func play_death_sfx() -> void:
	pass


func play_form_change_sfx() -> void:
	pass
