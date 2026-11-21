extends Node

## Generic persistent key-value storage backed by a Godot ConfigFile.
const STORE_PATH: String = "user://mantle_store.cfg"

var _config: ConfigFile = ConfigFile.new()


func _ready() -> void:
	var error: Error = _config.load(STORE_PATH)
	if error != OK and error != ERR_FILE_NOT_FOUND:
		push_error("StoreManager: could not load '%s' (error %d)." % [STORE_PATH, error])


## Stores a value under a section and key, then persists the updated file.
func set_value(section: String, key: String, value: Variant) -> Error:
	if section.is_empty() or key.is_empty():
		push_error("StoreManager: section and key cannot be empty.")
		return ERR_INVALID_PARAMETER

	_config.set_value(section, key, value)
	var error: Error = _config.save(STORE_PATH)
	if error != OK:
		push_error("StoreManager: could not save '%s' (error %d)." % [STORE_PATH, error])
	return error


## Returns the stored value, or [param default_value] when it is missing.
func get_value(section: String, key: String, default_value: Variant = null) -> Variant:
	return _config.get_value(section, key, default_value)


## Checks whether a section contains the requested key.
func has_value(section: String, key: String) -> bool:
	return _config.has_section_key(section, key)


## Removes a value and persists the updated file.
func erase_value(section: String, key: String) -> Error:
	if not _config.has_section_key(section, key):
		return OK

	_config.erase_section_key(section, key)
	var error: Error = _config.save(STORE_PATH)
	if error != OK:
		push_error("StoreManager: could not save '%s' (error %d)." % [STORE_PATH, error])
	return error
