class_name Player
extends CharacterBody2D

const GRAVITY_SETTING: String = "physics/2d/default_gravity"

## Horizontal speed in px/s.
@export var move_speed: float = 200.0
## Initial vertical speed of a jump in px/s. Negative goes up.
@export var jump_velocity: float = -400.0
## Maximum downward speed in px/s.
@export var max_fall_speed: float = 800.0
## Time in seconds a jump press is remembered before landing. 0.0 disables it.
@export var jump_buffer_time: float = 0.1

var gravity: float = float(ProjectSettings.get_setting(GRAVITY_SETTING))

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y += gravity * delta
		velocity.y = minf(velocity.y, max_fall_speed)

	move_and_slide()
