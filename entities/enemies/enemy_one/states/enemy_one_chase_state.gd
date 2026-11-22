## Follows the target and attacks it when in reach.
class_name EnemyOneChaseState
extends EnemyOneState

## Horizontal distance in px under which the enemy does not turn
const TURN_DEADZONE: float = 4.0

## Horizontal speed in px/s while chasing.
@export var chase_speed: float = 90.0
## Distance in px at which the enemy forgets the target.
@export var give_up_distance: float = 200.0


func physics_update(_delta: float) -> void:	
	if not _has_target():
		enemy.target = null
		change_state.emit(EnemyOneStates.PATROL)
		return

	var dx := enemy.target.global_position.x - enemy.global_position.x
	if absf(dx) > TURN_DEADZONE:
		enemy.face(dx)

	if enemy.can_see_player():
		change_state.emit(EnemyOneStates.ATTACK)
		return

	if enemy.stationary or enemy.should_turn():
		enemy.velocity.x = 0.0
		enemy.play_animation(EnemyOne.ANIM_IDLE)
		return

	enemy.velocity.x = enemy.direction * chase_speed
	enemy.play_animation(EnemyOne.ANIM_WALK)


func _has_target() -> bool:
	if not is_instance_valid(enemy.target):
		return false
	return enemy.global_position.distance_to(enemy.target.global_position) <= give_up_distance
