extends Node2D

const ARENA_SCENE_PATH: String = "res://levels/boss_arena/boss_arena.tscn"

@export var encounter: BossEncounter
@export var encounter_female_wizard: BossEncounter

var _transition_requested: bool = false


func _unhandled_input(event: InputEvent) -> void:
	if _transition_requested or not event is InputEventKey:
		return

	var key_event: InputEventKey = event as InputEventKey
	if not key_event.pressed or key_event.echo:
		return
	if key_event.physical_keycode == KEY_B:
		_transition_to_arena(encounter)
	elif key_event.physical_keycode == KEY_N:
		_transition_to_arena(encounter_female_wizard)


func _transition_to_arena(selected_encounter: BossEncounter) -> void:
	if not selected_encounter:
		push_error("ArenaTransitionTest: no encounter assigned.")
		return
	_transition_requested = true
	var error: Error
	if GameManager.run_state == GameManager.RunState.MENU:
		error = await GameManager.start_run(ARENA_SCENE_PATH, selected_encounter)
	else:
		error = await GameManager.change_level(ARENA_SCENE_PATH, selected_encounter)

	if error != OK:
		push_error("ArenaTransitionTest: arena transition failed (%d)." % error)
		_transition_requested = false
