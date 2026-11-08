## One attack of a form: animation, timing, damage and hit area.
class_name AttackData
extends Resource

@export var animation: StringName = &"attack"
## Seconds the Attack state lasts. Should not exceed the animation length.
@export var duration: float = 0.3
@export var damage: int = 1
## Hit area with the character facing right and the origin at the feet.
@export var hitbox_size: Vector2 = Vector2(60.0, 35.0)
@export var hitbox_offset: Vector2 = Vector2(30.0, -20.0)
## Optional projectile scene. Null means melee attack.
@export var projectile_scene: PackedScene
## Animation frame that launches the projectile.
@export var launch_frame: int = 8
## Projectile spawn offset. X is relative to facing direction.
@export var projectile_offset: Vector2 = Vector2(25.0, -30.0)
