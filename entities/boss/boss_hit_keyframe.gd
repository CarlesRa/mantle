## Hitbox state and rectangle geometry from a given animation frame.
class_name BossHitKeyframe
extends Resource

## Animation frame at which this state begins.
@export var frame: int = 0
## Whether the hitbox can deal damage.
@export var active: bool = false
## Rectangle offset in the boss-facing-right orientation.
@export var offset: Vector2 = Vector2.ZERO
## Rectangle size in pixels.
@export var size: Vector2 = Vector2.ZERO
