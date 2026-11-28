## Level 1 flow. Owns the rock trap cutscene: touching the log pile fades the screen
## to black, drops the rock on the guard and shakes the camera when the view returns.
## Also handles the kill zone, the sword pickup and the NPC that leads to the boss arena.
extends Node2D

## Seconds the screen takes to fade to black and back.
@export var fade_time: float = 0.4
## Seconds the screen stays black while the rock falls.
@export var black_time: float = 1.0
## Maximum camera offset in px during the shake.
@export var shake_strength: float = 10.0
## Seconds the camera shake lasts.
@export var shake_time: float = 0.5
## Number of jumps the camera makes while shaking.
@export var shake_steps: int = 8
## Sound played when the rock lands on the guard.
@export var rock_impact_sfx: SoundEffect

@export var kill_zone: Area2D
@export var player: Player
@export var camera: Camera2D
@export var trap_trigger: Area2D
@export var trapped_guard: EnemyOne
@export var fallen_rock: Node2D
@export var trap_setup: Node2D
@export var fade_rect: ColorRect

#SwordPickUp
## Height in px of the sword floating motion.
@export var sword_float_height: float = 4.0
## Seconds of a full up-and-down sword float cycle.
@export var sword_float_time: float = 1.2
## Sound played when the player picks up the sword.
@export var sword_pickup_sfx: SoundEffect
@export var sword_pickup: Area2D
@export var sword_sprite: Sprite2D

#Cave
## Seconds the background takes to blend between forest and cave.
@export var background_fade_time: float = 0.6
@export var cave_zone: Area2D
@export var forest_background: Node2D
@export var cave_background: Node2D
## Camera bottom limit in px while the player is inside the cave.
@export var cave_camera_limit_bottom: int = 1720

var _background_tween: Tween

#NPC
## Scene the NPC sends the player to.
@export_file("*.tscn") var boss_arena_scene: String
## Encounter configuration passed to the boss arena.
@export var boss_encounter: BossEncounter
@export var npc_talk_zone: Area2D
@export var npc_prompt: Label




#Conditionals
var _trap_done: bool = false
var _sword_collected: bool = false
var _is_restarting: bool = false
var _player_near_npc: bool = false
var _is_entering_arena: bool = false
var _return_config: ArenaReturnConfig
var _forest_camera_limit_bottom: int = 0


func configure(configuration: Resource) -> void:
	if not configuration is ArenaReturnConfig:
		push_error("LevelOne: expected an ArenaReturnConfig configuration.")
		return
	_return_config = configuration as ArenaReturnConfig
	if _return_config.reward_form and player:
		player.initial_form = _return_config.reward_form


func _ready() -> void:
	if not _has_references():
		return
	fallen_rock.visible = false
	fade_rect.modulate = Color(1.0, 1.0, 1.0, 0.0)
	_forest_camera_limit_bottom = camera.limit_bottom
	trap_trigger.body_entered.connect(_on_trap_trigger_body_entered)
	kill_zone.body_entered.connect(_on_kill_zone_body_entered)

	sword_pickup.visible = false
	sword_pickup.set_deferred(&"monitoring", false)
	sword_pickup.body_entered.connect(_on_sword_pickup_body_entered)
	_start_sword_floating()

	npc_prompt.visible = false
	if _return_config:
		_restore_from_arena()
	else:
		npc_talk_zone.body_entered.connect(_on_npc_talk_zone_body_entered)
		npc_talk_zone.body_exited.connect(_on_npc_talk_zone_body_exited)

	EventBus.player_form_changed.connect(_on_player_form_changed)

	cave_background.modulate = Color(1.0, 1.0, 1.0, 0.0)
	cave_zone.body_entered.connect(_on_cave_zone_body_entered)
	cave_zone.body_exited.connect(_on_cave_zone_body_exited)


func _unhandled_input(event: InputEvent) -> void:
	if _player_near_npc and event.is_action_pressed("interact", false):
		_enter_boss_arena()

func _has_references() -> bool:
	if (
		player and camera and kill_zone and fade_rect
		and trap_trigger and trapped_guard and fallen_rock and trap_setup
		and sword_pickup and sword_sprite
		and npc_talk_zone and npc_prompt and boss_encounter
		and not boss_arena_scene.is_empty()
		and cave_zone and forest_background and cave_background
	):
		return true
	var msg := "LevelOne: some references are not assigned in the Inspector."
	push_error(msg)
	assert(false, msg)
	return false


func _restore_from_arena() -> void:
	_trap_done = _return_config.trap_done
	_sword_collected = _return_config.sword_collected
	$NpcWizard.visible = false
	npc_talk_zone.set_deferred(&"monitoring", false)
	npc_prompt.visible = false
	player.global_position = _return_config.player_position
	player.velocity = Vector2.ZERO
	if not _trap_done:
		return
	fallen_rock.visible = true
	trap_setup.visible = false
	trapped_guard.die()
	if not _sword_collected:
		sword_pickup.visible = true
		sword_pickup.set_deferred(&"monitoring", true)


func _on_trap_trigger_body_entered(body: Node2D) -> void:
	if _trap_done or body != player:
		return
	_trap_done = true
	_play_rock_trap()

func _play_rock_trap() -> void:
	player.process_mode = Node.PROCESS_MODE_DISABLED
	AudioManager.play_sfx(rock_impact_sfx)
	await _fade_to(1.0)

	fallen_rock.visible = true
	trap_setup.visible = false
	trapped_guard.die()
	sword_pickup.visible = true
	sword_pickup.set_deferred(&"monitoring", true)
	await get_tree().create_timer(black_time).timeout

	# Re-enabled before the shake: the camera is a child of the player
	# and does not move while the player is disabled.
	player.process_mode = Node.PROCESS_MODE_INHERIT
	await _fade_to(0.0)
	_shake_camera()

func _fade_to(alpha: float) -> void:
	var tween := create_tween()
	tween.tween_property(fade_rect, "modulate:a", alpha, fade_time)
	await tween.finished

func _shake_camera() -> void:
	var tween := create_tween()
	var step_time := shake_time / shake_steps
	for i: int in range(shake_steps):
		var strength := shake_strength * (1.0 - float(i) / shake_steps)
		var shake_offset := Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * strength
		tween.tween_property(camera, "offset", shake_offset, step_time)
	tween.tween_property(camera, "offset", Vector2.ZERO, step_time)

func _on_kill_zone_body_entered(body: Node2D) -> void:
	if _is_restarting or _is_entering_arena or body != player:
		return
	_is_restarting = true
	_play_player_death_sfx()
	SceneManager.reload_current_scene()

func _play_player_death_sfx() -> void:
	if player.form and player.form.audio:
		AudioManager.play_sfx(player.form.audio.death_sfx)

func _start_sword_floating() -> void:
	var tween := create_tween().set_loops()
	tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(sword_sprite, "position:y", -sword_float_height, sword_float_time / 2.0)
	tween.tween_property(sword_sprite, "position:y", 0.0, sword_float_time / 2.0)

func _on_sword_pickup_body_entered(body: Node2D) -> void:
	if body != player:
		return
	sword_pickup.set_deferred(&"monitoring", false)
	_sword_collected = true
	AudioManager.play_sfx(sword_pickup_sfx)
	sword_pickup.queue_free()
	_unlock_player_attack()

func _unlock_player_attack() -> void:
	print("Sword collected")

func _on_npc_talk_zone_body_entered(body: Node2D) -> void:
	if body != player:
		return
	_player_near_npc = true
	npc_prompt.visible = true

func _on_npc_talk_zone_body_exited(body: Node2D) -> void:
	if body != player:
		return
	_player_near_npc = false
	npc_prompt.visible = false

func _enter_boss_arena() -> void:
	if _is_entering_arena or _is_restarting:
		return
	_is_entering_arena = true
	npc_prompt.visible = false
	player.process_mode = Node.PROCESS_MODE_DISABLED

	var return_config := ArenaReturnConfig.new()
	return_config.scene_path = scene_file_path
	return_config.player_position = player.global_position
	return_config.reward_form = boss_encounter.reward_form
	return_config.trap_done = _trap_done
	return_config.sword_collected = _sword_collected
	GameManager.arena_return = return_config

	var error: Error
	if GameManager.run_state == GameManager.RunState.MENU:
		error = await GameManager.start_run(boss_arena_scene, boss_encounter)
	else:
		error = await GameManager.change_level(boss_arena_scene, boss_encounter)

	if error != OK:
		var msg := "LevelOne: could not enter the boss arena (%d)." % error
		push_error(msg)
		assert(false, msg)
		player.process_mode = Node.PROCESS_MODE_INHERIT
		npc_prompt.visible = _player_near_npc
		_is_entering_arena = false


func _on_cave_zone_body_entered(body: Node2D) -> void:
	if body == player:
		_blend_background(cave_background, forest_background)
		camera.limit_bottom = cave_camera_limit_bottom

func _on_cave_zone_body_exited(body: Node2D) -> void:
	if body == player:
		_blend_background(forest_background, cave_background)
		camera.limit_bottom = _forest_camera_limit_bottom

## Fades in one background while fading out the other.
func _blend_background(shown: Node2D, hidden: Node2D) -> void:
	if not is_inside_tree():
		return
	if _background_tween:
		_background_tween.kill()
	_background_tween = create_tween().set_parallel()
	_background_tween.tween_property(shown, "modulate:a", 1.0, background_fade_time)
	_background_tween.tween_property(hidden, "modulate:a", 0.0, background_fade_time)


func _on_player_form_changed(form: PlayerForm) -> void:
	if form and form.music:
		AudioManager.play_music(form.music)
