class_name EnemyOneAttackState
extends EnemyOneState


## Damage dealt to whatever the sword hits.
@export var damage: int = 1
## Animation frame where the sword is fully swung and can hit.
@export var strike_frame: int = 4

var _has_struck: bool = false


func enter() -> void:
	enemy.velocity.x = 0.0
	_has_struck = false
	enemy.play_animation(EnemyOne.ANIM_ATTACK)


func physics_update(_delta: float) -> void:
	if enemy.is_animation_finished(EnemyOne.ANIM_ATTACK):
		change_state.emit(EnemyOneStates.PATROL)
		return
		
	if not _has_struck and enemy.get_animation_frame() >= strike_frame:
		_has_struck = true
		enemy.strike(damage)
