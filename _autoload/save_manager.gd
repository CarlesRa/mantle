extends Node

## Section and keys used for the basic player checkpoint.
const CHECKPOINT_SECTION: String = "checkpoint"
const SCENE_PATH_KEY: String = "scene_path"
const PLAYER_POSITION_KEY: String = "player_position"


## Saves a checkpoint containing the current scene and player position.
func save_checkpoint(scene_path: String, player_position: Vector2) -> Error:
	if scene_path.is_empty():
		push_error("SaveManager: scene path cannot be empty.")
		return ERR_INVALID_PARAMETER

	var store: Node = _get_store_manager()
	if store == null:
		push_error("SaveManager: StoreManager autoload is not available.")
		return ERR_UNCONFIGURED

	var error: Error = store.call(
		"set_value", CHECKPOINT_SECTION, SCENE_PATH_KEY, scene_path
	)
	if error != OK:
		return error

	return store.call(
		"set_value", CHECKPOINT_SECTION, PLAYER_POSITION_KEY, player_position
	)


## Returns the checkpoint data, or an empty dictionary when none is available.
func load_checkpoint() -> Dictionary:
	var store: Node = _get_store_manager()
	if store == null:
		push_error("SaveManager: StoreManager autoload is not available.")
		return {}

	if not store.call("has_value", CHECKPOINT_SECTION, SCENE_PATH_KEY):
		return {}
	if not store.call("has_value", CHECKPOINT_SECTION, PLAYER_POSITION_KEY):
		return {}

	var scene_path: Variant = store.call(
		"get_value", CHECKPOINT_SECTION, SCENE_PATH_KEY, ""
	)
	var player_position: Variant = store.call(
		"get_value", CHECKPOINT_SECTION, PLAYER_POSITION_KEY, Vector2.ZERO
	)
	if not scene_path is String or not player_position is Vector2:
		push_error("SaveManager: stored checkpoint data has an invalid format.")
		return {}

	return {
		"scene_path": scene_path,
		"player_position": player_position,
	}


## Reports whether a complete, valid checkpoint is available.
func has_checkpoint() -> bool:
	return not load_checkpoint().is_empty()


## Removes the saved checkpoint data.
func clear_checkpoint() -> Error:
	var store: Node = _get_store_manager()
	if store == null:
		push_error("SaveManager: StoreManager autoload is not available.")
		return ERR_UNCONFIGURED

	var error: Error = store.call(
		"erase_value", CHECKPOINT_SECTION, SCENE_PATH_KEY
	)
	if error != OK:
		return error

	return store.call(
		"erase_value", CHECKPOINT_SECTION, PLAYER_POSITION_KEY
	)


func _get_store_manager() -> Node:
	return get_node_or_null("/root/StoreManager")
