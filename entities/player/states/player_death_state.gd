class_name PlayerDeathState
extends PlayerState

## Seconds before player_died is emitted, so the animation can play.
@export var death_time: float = 1.0

var _time_left: float = 0.0

func enter() -> void:
	# Die flying away from whatever hit the player last.
	player.velocity = player.knockback
	# Face the source so the fall animation matches the knockback.
	player.face(-player.knockback.x)
	player.knockback = Vector2.ZERO
	_time_left = death_time
	player.play_animation(PlayerAnimations.DEATH)

func exit() -> void:
	pass

# No input and no exit: death is final until the level reacts.
func physics_update(delta: float) -> void:
	if player.is_on_floor():
		player.velocity.x = 0.0
	if _time_left <= 0.0:
		return
	_time_left -= delta
	if _time_left <= 0.0:
		EventBus.player_died.emit()
