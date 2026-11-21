## Sound effects used by one Player form.
## Playback is handled by PlayerAudioHandler.
class_name PlayerAudioSet
extends Resource

@export_group("Movement")
@export var jump_sfx: SoundEffect
@export var land_sfx: SoundEffect

@export_group("Combat")
@export var damage_sfx: SoundEffect
@export var death_sfx: SoundEffect

@export_group("Forms")
@export var form_change_sfx: SoundEffect

@export_group("Frame Cues")
@export var frame_cues: Array[FrameCue]
