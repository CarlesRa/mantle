## Frame-keyed hitbox configuration for a boss attack.
class_name BossAttackTrack
extends Resource

## The most recent keyframe at or before the current frame is applied.
@export var keyframes: Array[BossHitKeyframe] = []
