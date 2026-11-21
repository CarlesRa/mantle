## Level 1 flow. Owns the rock trap cutscene: touching the log pile fades the screen
## to black, drops the rock on the guard and shakes the camera when the view returns.
extends Node2D

## Seconds the screen takes to fade to black and back.
@export var fade_time: float = 0.4
## Seconds the screen stays black while the rock falls.
@export var black_time: float = 1.0
## Maximum camera offset in px during the shake.
@export var shake_strength: float = 6.0
## Seconds the camera shake lasts.
@export var shake_time: float = 0.4
## Number of jumps the camera makes while shaking.
@export var shake_steps: int = 8

@export var player: Player
@export var camera: Camera2D
@export var trap_trigger: Area2D
@export var trapped_guard: EnemyOne
@export var fallen_rock: Node2D
@export var fade_rect: ColorRect

var _trap_done: bool = false

func _ready() -> void:
	if not _has_references():
		return
	fallen_rock.visible = false
	fade_rect.modulate = Color(1.0, 1.0, 1.0, 0.0)
	trap_trigger.body_entered.connect(_on_trap_trigger_body_entered)

func _has_references() -> bool:
	if player and camera and trap_trigger and trapped_guard and fallen_rock and fade_rect:
		return true
	var msg := "LevelOne: some rock trap references are not assigned in the Inspector."
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
	await _fade_to(1.0)

	fallen_rock.visible = true
	trapped_guard.die()
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
