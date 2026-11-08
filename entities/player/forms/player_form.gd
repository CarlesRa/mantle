## Data of one player transformation: movement stats, hitbox, look and world look.
## Create one .tres per form and assign it to a portal or to Player.initial_form.
class_name PlayerForm
extends Resource

@export var id: StringName
@export var display_name: String = ""

@export_group("Movement")
## Horizontal speed in px/s.
@export var move_speed: float = 200.0
## Initial vertical speed of a jump in px/s. Negative goes up.
@export var jump_velocity: float = -400.0
## Extra jumps allowed while in the air (1 = double jump).
@export var air_jumps: int = 0
## Max fall speed in px/s while holding jump. 0.0 disables gliding.
@export var glide_fall_speed: float = 0.0

@export_group("Hitbox")
## Size in px. The player origin is at its feet, so the box sits right above it.
@export var hitbox_size: Vector2 = Vector2(14.0, 38.0)

@export_group("Visuals")
@export var sprite_frames: SpriteFrames
## Sprite offset so the feet of the character sit on the player origin.
@export var sprite_offset: Vector2 = Vector2.ZERO
## Color of the portals that give this form.
@export var portal_color: Color = Color.WHITE

@export_group("Combat")
## Seconds the Attack state lasts. Should match the length of the attack animation.
@export var attack_duration: float = 0.3
@export var attack_damage: int = 1
## Melee hitbox with the character facing right and the origin at the feet.
@export var attack_hitbox_size: Vector2 = Vector2(24.0, 30.0)
@export var attack_hitbox_offset: Vector2 = Vector2(20.0, -20.0)
## If set, the attack spawns this instead of using the melee hitbox.
@export var attack_projectile: PackedScene

@export_group("World look")
## Multiplies the screen color while this form is active.
@export var world_tint: Color = Color.WHITE
@export_range(0.0, 2.0, 0.01) var world_saturation: float = 1.0
@export_range(0.0, 2.0, 0.01) var world_contrast: float = 1.0
