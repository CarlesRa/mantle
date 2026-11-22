## Level 1 flow. Owns the rock trap cutscene: touching the log pile fades the screen
## to black, drops the rock on the guard and shakes the camera when the view returns.
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

#Conditionals
var _trap_done: bool = false
var _is_restarting: bool = false

func _ready() -> void:
	if not _has_references():
		return
	fallen_rock.visible = false
	fade_rect.modulate = Color(1.0, 1.0, 1.0, 0.0)
	trap_trigger.body_entered.connect(_on_trap_trigger_body_entered)
	kill_zone.body_entered.connect(_on_kill_zone_body_entered)
	
	sword_pickup.visible = false
	sword_pickup.set_deferred(&"monitoring", false)
	sword_pickup.body_entered.connect(_on_sword_pickup_body_entered)
	_start_sword_floating()


func _has_references() -> bool:
	if (
		player and camera and kill_zone and fade_rect
		and trap_trigger and trapped_guard and fallen_rock and trap_setup
		and sword_pickup and sword_sprite
	):
		return true
	var msg := "LevelOne: some references are not assigned in the Inspector."
	push_error(msg)
	assert(false, msg)
	return false
		
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
	_shake_camera()
	await _fade_to(0.0)

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
	if _is_restarting or body != player:
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
	AudioManager.play_sfx(sword_pickup_sfx)
	sword_pickup.queue_free()
	_unlock_player_attack()

func _unlock_player_attack() -> void:
	print("Sword collected")
