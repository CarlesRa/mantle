class_name BossArena
extends Node2D

const ARENA_LEFT: float = 0.0
const ARENA_RIGHT: float = 1152.0
const ARENA_TOP: float = 0.0
const ARENA_BOTTOM: float = 648.0
const CAMERA_SMOOTH_SPEED: float = 6.0

@export var player_scene: PackedScene
@export var boss_scene: PackedScene
@export var player_form: PlayerForm
@export var portal: FormPortal
@export var portal_delay: float = 1.5
@export var music: AudioStream
@export var background: Texture2D
@export var return_prompt: Label
@export var camera_zoom: Vector2 = Vector2(2, 2)

var _portal_crossed: bool = false
var _returning: bool = false
var _player: Player
var _boss: Boss
var _camera: Camera2D
var _boss_alive: bool = true


## Applies encounter-specific resources before the arena enters the scene tree.
func configure(configuration: Resource) -> void:
	if not configuration is BossEncounter:
		push_error("BossArena: expected a BossEncounter configuration.")
		return

	var encounter: BossEncounter = configuration as BossEncounter
	boss_scene = encounter.boss_scene
	player_form = encounter.player_form
	portal.form = encounter.reward_form
	background = encounter.background
	music = encounter.music

func _ready() -> void:
	if background != null:
		($Backgound as Sprite2D).texture = background

	_player = player_scene.instantiate() as Player
	if player_form:
		_player.initial_form = player_form
	_player.global_position = $PlayerSpawn.global_position
	add_child(_player)

	_boss = boss_scene.instantiate() as Boss
	_boss.global_position = $BossSpawn.global_position
	add_child(_boss)
	_boss_alive = is_instance_valid(_boss)

	_camera = Camera2D.new()
	_camera.zoom = camera_zoom
	_camera.limit_left = int(ARENA_LEFT)
	_camera.limit_right = int(ARENA_RIGHT)
	_camera.limit_top = int(ARENA_TOP)
	_camera.limit_bottom = int(ARENA_BOTTOM)
	_camera.limit_smoothed = true
	add_child(_camera)
	_camera.global_position = _get_camera_target()
	_camera.make_current()
	_camera.reset_smoothing()

	portal.set_active(false)
	if return_prompt:
		return_prompt.visible = false
	_boss.died.connect(_on_boss_died)
	portal.reward_taken.connect(_on_reward_taken)

	AudioManager.play_music(music)


func _unhandled_input(event: InputEvent) -> void:
	if not _portal_crossed or _returning or not event.is_action_pressed("interact", false):
		return
	_return_to_level()


func _on_reward_taken(_form: PlayerForm) -> void:
	if _portal_crossed:
		return
	_portal_crossed = true
	if return_prompt:
		return_prompt.visible = true


func _physics_process(delta: float) -> void:
	if not _camera or not is_instance_valid(_player):
		return
	var target: Vector2 = _get_camera_target()
	_camera.global_position = _camera.global_position.lerp(
		target,
		1.0 - exp(-CAMERA_SMOOTH_SPEED * delta)
	)


func _get_camera_target() -> Vector2:
	var target: Vector2 = _player.global_position
	if _boss_alive and is_instance_valid(_boss):
		target = (_player.global_position + _boss.global_position) * 0.5
	var half_view: Vector2 = (get_viewport_rect().size * 0.5) / _camera.zoom
	target.x = clampf(target.x, ARENA_LEFT + half_view.x, ARENA_RIGHT - half_view.x)
	target.y = clampf(target.y, ARENA_TOP + half_view.y, ARENA_BOTTOM - half_view.y)
	return target


func _on_boss_died() -> void:
	_boss_alive = false
	var fade_duration: float = _boss.death_fade_duration if is_instance_valid(_boss) else 0.0
	portal.set_active(true, fade_duration)


func _return_to_level() -> void:
	if _returning:
		return
	var config: ArenaReturnConfig = GameManager.arena_return
	if not config:
		push_warning("BossArena: no ArenaReturnConfig assigned; staying in the arena.")
		return
	_returning = true
	AudioManager.stop_sfx(portal.sfx)
	AudioManager.stop_music()
	var error: Error = await GameManager.change_level(config.scene_path, config)
	GameManager.arena_return = null
	if error != OK:
		push_error("BossArena: could not return to the previous level (%d)." % error)
		_returning = false
