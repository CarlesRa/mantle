class_name BossArena
extends Node2D

@export var player_scene: PackedScene
@export var boss_scene: PackedScene
@export var player_form: PlayerForm
@export var portal: FormPortal
@export var portal_delay: float = 1.5
@export var music: AudioStream
@export var background: Texture2D


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
	boss.died.connect(_on_boss_died)

	AudioManager.play_music(music)

func _on_boss_died() -> void:
	await get_tree().create_timer(portal_delay).timeout
	portal.set_active(true)
