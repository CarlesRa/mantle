## Audio clips used by one Player form.
## Assign streams here; playback is handled by PlayerAudioHandler.
class_name PlayerAudioSet
extends Resource

@export_group("Movement")
@export var jump_sfx: AudioStream
@export var land_sfx: AudioStream
@export var run_sfx: AudioStream

@export_group("Combat")
@export var attack_primary_sfx: AudioStream
@export var attack_secondary_sfx: AudioStream
@export var damage_sfx: AudioStream
@export var death_sfx: AudioStream

@export_group("Forms")
@export var form_change_sfx: AudioStream
