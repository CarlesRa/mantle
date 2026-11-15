extends Node2D

## Sound used by keys 1 and 2.
@export var sfx: SoundEffect
## First music track used by key 3.
@export var music_a: AudioStream
## Second music track used by key 4.
@export var music_b: AudioStream
## Third music track used by key 5
@export var music_c: AudioStream

@onready var _label: Label = $Label

var _playing_slot: String = "None"


func _ready() -> void:
	_update_label()


func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	match event.physical_keycode:
		KEY_1:
			AudioManager.play_sfx(sfx)
		KEY_2:
			AudioManager.play_sfx(sfx)
		KEY_3:
			if music_a != null:
				AudioManager.play_music(music_a)
				_playing_slot = "A"
				_update_label()
		KEY_4:
			if music_b != null:
				AudioManager.play_music(music_b)
				_playing_slot = "B"
				_update_label()
		KEY_5:
			if music_c != null:
				AudioManager.play_music(music_c)
				_playing_slot = "A"
				_update_label()
		KEY_6:
			AudioManager.stop_music()
			_playing_slot = "None"
			_update_label()
		KEY_Q:
			_adjust_bus_volume(&"Music", 0.1)
		KEY_A:
			_adjust_bus_volume(&"Music", -0.1)
		KEY_W:
			_adjust_bus_volume(&"SFX", 0.1)
		KEY_S:
			_adjust_bus_volume(&"SFX", -0.1)


func _adjust_bus_volume(bus_name: StringName, amount: float) -> void:
	var current_volume: float = AudioManager.get_bus_volume(bus_name)
	AudioManager.set_bus_volume(bus_name, current_volume + amount)


func _update_label() -> void:
	_label.text = ("1/2: Play configured SFX (pitch variation set in Inspector)\n
		3: Play music A\n
		4: Play music B\n
		5: Stop music\n
		Q/A: Music volume up/down\n
		W/S: SFX volume up/down\n\n
		Playing music slot: %s" % _playing_slot
	)
