extends Node


const DEFAULT_FADE_DURATION: float = 0.25

var _overlay: ColorRect
var _is_transitioning: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

	var canvas_layer: CanvasLayer = CanvasLayer.new()
	canvas_layer.name = "SceneTransitionLayer"
	canvas_layer.layer = 100
	canvas_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(canvas_layer)

	_overlay = ColorRect.new()
	_overlay.name = "FadeOverlay"
	_overlay.color = Color.TRANSPARENT
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	canvas_layer.add_child(_overlay)


## Fades out, changes to the scene at [param scene_path], then fades in.
func change_scene(
	scene_path: String,
	fade_duration: float = DEFAULT_FADE_DURATION,
	scene_configuration: Resource = null
) -> Error:
	if scene_path.is_empty():
		push_error("SceneManager: scene path cannot be empty.")
		return ERR_INVALID_PARAMETER

	if _is_transitioning:
		push_error("SceneManager: a scene transition is already in progress.")
		return ERR_BUSY

	_is_transitioning = true
	var duration: float = maxf(fade_duration, 0.0)
	await _fade_to(Color.BLACK, duration)

	var packed_scene: PackedScene = load(scene_path) as PackedScene
	if packed_scene == null:
		push_error("SceneManager: could not load scene '%s'." % scene_path)
		await _fade_to(Color.TRANSPARENT, duration)
		_is_transitioning = false
		return ERR_CANT_OPEN

	var next_scene: Node = packed_scene.instantiate()
	if scene_configuration != null:
		if not next_scene.has_method("configure"):
			push_error("SceneManager: scene '%s' does not accept configuration." % scene_path)
			next_scene.free()
			await _fade_to(Color.TRANSPARENT, duration)
			_is_transitioning = false
			return ERR_INVALID_PARAMETER
		next_scene.call("configure", scene_configuration)

	var tree: SceneTree = get_tree()
	var previous_scene: Node = tree.current_scene
	tree.root.add_child(next_scene)
	tree.current_scene = next_scene
	if is_instance_valid(previous_scene):
		previous_scene.queue_free()

	await _fade_to(Color.TRANSPARENT, duration)
	_is_transitioning = false
	return OK


## Reloads the current scene.
func reload_current_scene() -> Error:
	var current_scene: Node = get_tree().current_scene
	if current_scene == null or current_scene.scene_file_path.is_empty():
		push_error("SceneManager: there is no current scene to reload.")
		return ERR_UNCONFIGURED

	return await change_scene(current_scene.scene_file_path)


func _fade_to(target_color: Color, duration: float) -> void:
	if duration == 0.0:
		_overlay.color = target_color
		return

	var tween: Tween = create_tween()
	tween.tween_property(_overlay, "color", target_color, duration)
	await tween.finished
