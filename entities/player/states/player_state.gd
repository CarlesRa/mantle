class_name PlayerState
extends State

var player: Player

## Casts the actor to Player. Returns false if the cast fails.
func setup(new_actor: CharacterBody2D) -> bool:
	if not super(new_actor):
		return false

	player = new_actor as Player
	if player:
		return true

	var error_message: String = (
		"PlayerState: Error casting to Player new_actor: %s" % new_actor.name
	)
	push_error(error_message)
	assert(false, error_message)
	return false

## Reads the horizontal input and applies it to the player's velocity.x.
## Only touches the x axis, so vertical movement is left to gravity and jumps.
func _apply_horizontal_movement() -> void:
	var direction: float = Input.get_axis("move_left", "move_right")
	player.velocity.x = direction * player.move_speed
