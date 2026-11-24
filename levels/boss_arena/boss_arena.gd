class_name BossArena
extends Node2D

@export var player_scene: PackedScene
@export var boss_scene: PackedScene
@export var player_form: PlayerForm
@export var portal: FormPortal
@export var portal_delay: float = 1.5
@export var music: AudioStream
@export var background: Texture2D
@export var return_prompt: Label

var _portal_crossed: bool = false
var _returning: bool = false


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

	var player: Player = player_scene.instantiate() as Player
	if player_form:
		player.initial_form = player_form
	player.global_position = $PlayerSpawn.global_position
	add_child(player)

	var boss: Boss = boss_scene.instantiate() as Boss
	boss.global_position = $BossSpawn.global_position
	add_child(boss)

	portal.set_active(false)
	if return_prompt:
		return_prompt.visible = false
	boss.died.connect(_on_boss_died)
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


func _on_boss_died() -> void:
	await get_tree().create_timer(portal_delay).timeout
	portal.set_active(true)


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
