class_name PlayerDeathState
extends PlayerState

var _death_finished: bool = false

func enter() -> void:
	# Preserve the knockback's vertical launch, but prevent horizontal drift.
	player.velocity = player.knockback
	player.velocity.x = 0.0
	player.face(-player.knockback.x)
	player.knockback = Vector2.ZERO
	_death_finished = false
	player.play_animation(PlayerAnimations.DEATH, true)
	var sprite: AnimatedSprite2D = player.get_node("Visuals/AnimatedSprite2D")
	if not sprite.animation_finished.is_connected(_on_animation_finished):
		sprite.animation_finished.connect(_on_animation_finished)
	if not sprite.sprite_frames or not sprite.sprite_frames.has_animation(PlayerAnimations.DEATH):
		_on_animation_finished()

func exit() -> void:
	var sprite: AnimatedSprite2D = player.get_node("Visuals/AnimatedSprite2D")
	if sprite.animation_finished.is_connected(_on_animation_finished):
		sprite.animation_finished.disconnect(_on_animation_finished)

# Death is final, but the body continues falling and can land.
func physics_update(delta: float) -> void:
	player.velocity.x = 0.0
	if not player.is_on_floor():
		player.velocity.y = minf(player.velocity.y + player.gravity * delta, player.max_fall_speed)
	else:
		player.velocity.y = 0.0
	player.move_and_slide()

func _on_animation_finished() -> void:
	if _death_finished:
		return
	_death_finished = true
	EventBus.player_died.emit()
