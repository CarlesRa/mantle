extends CanvasLayer

const SLOW_MO_SCALE: float = 0.3
const SLOW_MO_DURATION: float = 0.35
const DEATH_DELAY: float = 0.4
const FADE_DURATION: float = 0.6

@onready var _background: ColorRect = $Background
@onready var _content: Control = $CenterContainer
@onready var _try_again_button: Button = %TryAgainButton
@onready var _main_menu_button: Button = %MainMenuButton

var _shown: bool = false
var _time_tween: Tween
var _fade_tween: Tween


func _ready() -> void:
	visible = false
	_background.modulate.a = 0.0
	_content.modulate.a = 0.0
	_try_again_button.disabled = true
	_main_menu_button.disabled = true
	_main_menu_button.visible = ResourceLoader.exists(SceneManager.MAIN_MENU_PATH)
	_try_again_button.pressed.connect(_on_try_again_pressed)
	_main_menu_button.pressed.connect(_on_main_menu_pressed)
	EventBus.player_died.connect(_on_player_died)


func _exit_tree() -> void:
	Engine.time_scale = 1.0


func _on_player_died() -> void:
	if _shown:
		return
	_shown = true
	visible = true

	AudioManager.stop_music(0.5)
	_stop_portal_loops()

	if _time_tween and _time_tween.is_valid():
		_time_tween.kill()
	_time_tween = create_tween()
	_time_tween.set_ignore_time_scale(true)
	_time_tween.tween_property(Engine, "time_scale", SLOW_MO_SCALE, SLOW_MO_DURATION)

	if _fade_tween and _fade_tween.is_valid():
		_fade_tween.kill()
	_fade_tween = create_tween()
	_fade_tween.set_ignore_time_scale(true)
	_fade_tween.tween_interval(DEATH_DELAY)
	_fade_tween.tween_property(_background, "modulate:a", 1.0, FADE_DURATION)
	_fade_tween.parallel().tween_property(_content, "modulate:a", 1.0, FADE_DURATION)
	_fade_tween.finished.connect(_on_fade_finished)


func _on_fade_finished() -> void:
	_try_again_button.disabled = false
	_main_menu_button.disabled = false
	_try_again_button.grab_focus()


func _stop_portal_loops() -> void:
	for node: Node in get_tree().get_nodes_in_group("portal"):
		if node.has_method("_stop_portal_sound"):
			node.call("_stop_portal_sound")
	var current_scene: Node = get_tree().current_scene
	if current_scene:
		for child: Node in current_scene.find_children("*", "FormPortal", true, false):
			if child.has_method("_stop_portal_sound"):
				child.call("_stop_portal_sound")


func _on_try_again_pressed() -> void:
	_try_again_button.disabled = true
	_main_menu_button.disabled = true
	Engine.time_scale = 1.0
	var current_scene: Node = get_tree().current_scene
	if current_scene is BossArena:
		await SceneManager.reload_current_scene()
		return
	var checkpoint: ArenaReturnConfig = GameManager.get_level_checkpoint()
	if checkpoint and not checkpoint.scene_path.is_empty():
		await SceneManager.change_scene(checkpoint.scene_path, SceneManager.DEFAULT_FADE_DURATION, checkpoint)
	else:
		await SceneManager.reload_current_scene()


func _on_main_menu_pressed() -> void:
	_try_again_button.disabled = true
	_main_menu_button.disabled = true
	Engine.time_scale = 1.0
	GameManager.arena_return = null
	GameManager.clear_level_checkpoint()
	await SceneManager.change_scene(SceneManager.MAIN_MENU_PATH)
