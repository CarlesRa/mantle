extends Node

enum RunState { MENU, PLAYING, PAUSED, GAME_OVER }

const PLAYER_GROUP: StringName = &"player"

var run_state: RunState = RunState.MENU


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if not EventBus.player_died.is_connected(_on_player_died):
		EventBus.player_died.connect(_on_player_died)


## Loads a gameplay scene and starts a new run.
func start_run(scene_path: String) -> Error:
	if run_state == RunState.PLAYING or run_state == RunState.PAUSED:
		return ERR_BUSY

	var previous_state: RunState = run_state
	var was_paused: bool = get_tree().paused
	get_tree().paused = false
	var error: Error = await SceneManager.change_scene(scene_path)
	if error != OK:
		run_state = previous_state
		get_tree().paused = was_paused
		return error

	run_state = RunState.PLAYING
	EventBus.game_started.emit()
	return OK


## Pauses the active run.
func pause_run() -> void:
	if run_state != RunState.PLAYING:
		return

	run_state = RunState.PAUSED
	get_tree().paused = true
	EventBus.game_paused.emit()


## Resumes a paused run.
func resume_run() -> void:
	if run_state != RunState.PAUSED:
		return

	get_tree().paused = false
	run_state = RunState.PLAYING
	EventBus.game_resumed.emit()


## Ends the active run and pauses gameplay for result UI.
func finish_run() -> void:
	if run_state != RunState.PLAYING and run_state != RunState.PAUSED:
		return

	get_tree().paused = true
	run_state = RunState.GAME_OVER
	EventBus.game_over.emit()


## Returns to a menu scene, leaving the saved checkpoint intact.
func return_to_menu(scene_path: String) -> Error:
	var previous_state: RunState = run_state
	var was_paused: bool = get_tree().paused
	get_tree().paused = false
	var error: Error = await SceneManager.change_scene(scene_path)
	if error != OK:
		run_state = previous_state
		get_tree().paused = was_paused
		return error

	run_state = RunState.MENU
	return OK


## Saves the current scene and player's global position as the checkpoint.
func save_checkpoint(player: Node2D) -> Error:
	if player == null or not is_instance_valid(player):
		return ERR_INVALID_PARAMETER

	var current_scene: Node = get_tree().current_scene
	if current_scene == null or current_scene.scene_file_path.is_empty():
		return ERR_UNCONFIGURED

	var error: Error = SaveManager.save_checkpoint(
		current_scene.scene_file_path, player.global_position
	)
	if error == OK:
		EventBus.checkpoint_saved.emit()
	return error


## Loads the checkpoint scene, finds its player, and restores the saved position.
func continue_from_checkpoint() -> Error:
	var checkpoint: Dictionary = SaveManager.load_checkpoint()
	if checkpoint.is_empty():
		return ERR_FILE_NOT_FOUND

	var scene_path: String = checkpoint["scene_path"]
	var current_scene: Node = get_tree().current_scene
	if current_scene == null or current_scene.scene_file_path != scene_path:
		var previous_state: RunState = run_state
		var was_paused: bool = get_tree().paused
		get_tree().paused = false
		var scene_error: Error = await SceneManager.change_scene(scene_path)
		if scene_error != OK:
			run_state = previous_state
			get_tree().paused = was_paused
			return scene_error

	var player: Node = get_tree().get_first_node_in_group(PLAYER_GROUP)
	if not player is Node2D:
		push_error("GameManager: checkpoint scene has no Node2D in the 'player' group.")
		return ERR_DOES_NOT_EXIST

	(player as Node2D).global_position = checkpoint["player_position"]
	if player is CharacterBody2D:
		(player as CharacterBody2D).velocity = Vector2.ZERO

	get_tree().paused = false
	run_state = RunState.PLAYING
	EventBus.checkpoint_loaded.emit()
	return OK


func _on_player_died() -> void:
	finish_run()
