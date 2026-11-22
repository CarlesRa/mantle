class_name BossJumpState
extends BossState

@export var jump_velocity: float = -450.0
@export var attack_height: float = 75.0

var _falling: bool = false
var _has_attacked: bool = false


func enter() -> void:
	_falling = false
	_has_attacked = false

	boss.face_target()

	boss.velocity.x = signf(
		boss.target.global_position.x - boss.global_position.x
	) * boss.move_speed * 1.5

	boss.velocity.y = jump_velocity

	boss.play_animation(&"jump", true)


func physics_update(_delta: float) -> void:
	if boss.player_is_dead:
		change_state.emit(BossStates.IDLE)
		return

	if _has_attacked:
		return

	boss.face_target()

	if boss.velocity.y <= 0.0:
		return

	if not _falling:
		_falling = true
		boss.velocity.x = 0.0
		boss.play_animation(&"fall", true)

	if not is_instance_valid(boss.ground_ray):
		return

	boss.ground_ray.force_raycast_update()

	if not boss.ground_ray.is_colliding():
		return

	var ground_distance: float = boss.ground_ray.global_position.distance_to(
		boss.ground_ray.get_collision_point()
	)

	print("Distancia al suelo: ", ground_distance)

	if ground_distance <= attack_height or boss.is_on_floor():
		_has_attacked = true
		print("BOSS: ATAQUE AEREO!")
		change_state.emit(BossStates.ATTACK)