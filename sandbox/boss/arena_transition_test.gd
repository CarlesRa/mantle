extends Node2D

const ARENA_SCENE_PATH: String = "res://levels/boss_arena/boss_arena.tscn"

@export var encounter: BossEncounter

var _transition_requested: bool = false


func _unhandled_input(event: InputEvent) -> void:
	if _transition_requested or not event is InputEventKey:
		return

	var key_event: InputEventKey = event as InputEventKey
	if key_event.pressed and not key_event.echo and key_event.physical_keycode == KEY_B:
		_transition_to_arena()


func _transition_to_arena() -> void:
	_transition_requested = true
	var error: Error
	if GameManager.run_state == GameManager.RunState.MENU:
		error = await GameManager.start_run(ARENA_SCENE_PATH, encounter)
	else:
		error = await GameManager.change_level(ARENA_SCENE_PATH, encounter)

	if error != OK:
		push_error("ArenaTransitionTest: arena transition failed (%d)." % error)
		_transition_requested = false
