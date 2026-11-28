extends Control

@export_multiline var credits_text: String = (
	"Music: <TBD>\n"
	+ "Sprites: Shikashi's Fantasy Icons Pack (and <TBD>)\n"
	+ "Font: Gothic Pixel Font (0S)"
)

@onready var _play_button: Button = %PlayButton
@onready var _credits_button: Button = %CreditsButton
@onready var _credits_panel: PanelContainer = %CreditsPanel
@onready var _credits_label: Label = %CreditsLabel
@onready var _back_button: Button = %BackButton


func _ready() -> void:
	Engine.time_scale = 1.0
	AudioManager.stop_music(0.5)
	_credits_panel.visible = false
	_credits_label.text = credits_text
	_play_button.pressed.connect(_on_play_pressed)
	_credits_button.pressed.connect(_on_credits_pressed)
	_back_button.pressed.connect(_on_back_pressed)
	_play_button.grab_focus()


func _on_play_pressed() -> void:
	_play_button.disabled = true
	_credits_button.disabled = true
	Engine.time_scale = 1.0
	GameManager.arena_return = null
	GameManager.clear_level_checkpoint()
	await SceneManager.change_scene(SceneManager.FIRST_SCENE_PATH)


func _on_credits_pressed() -> void:
	_credits_panel.visible = true
	_back_button.grab_focus()


func _on_back_pressed() -> void:
	_credits_panel.visible = false
	_credits_button.grab_focus()
