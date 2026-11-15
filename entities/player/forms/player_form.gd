## Data of one player transformation: movement stats, hitbox, look and world look.
## Create one .tres per form and assign it to a portal or to Player.initial_form.
class_name PlayerForm
extends Resource

const DEFAULT_TRANSFORM_DURATION: float = 0.5
const MIN_TRANSFORM_DURATION: float = 0.05

var _warned_about_transform_duration: bool = false

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

@export_group("Collisions")
## Size in px. The player origin is at its feet, so the box sits right above it.
@export var collision_size: Vector2 = Vector2(14.0, 38.0)
## Offset of the physical collision shape, relative to the player's facing direction.
@export var collision_offset: Vector2 = Vector2.ZERO
## Size of the area where this form can receive damage.
@export var hurtbox_size: Vector2 = Vector2(14.0, 38.0)
## Offset of the hurtbox shape, relative to the player's facing direction.
@export var hurtbox_offset: Vector2 = Vector2.ZERO

@export_group("Visuals")
@export var sprite_frames: SpriteFrames
## Sprite offset so the feet of the character sit on the player origin.
@export var sprite_offset: Vector2 = Vector2.ZERO
## Color of the portals that give this form.
@export var portal_color: Color = Color.WHITE

@export_group("Transformation")
## Seconds for this form's transformation. 0.0 uses the transformation SFX length; a positive value overrides it.
@export var transform_time: float = 0.0

@export_group("Audio")
@export var audio: PlayerAudioSet

@export_group("Combat")
## Attack of the main button. Null = the form cannot attack.
@export var primary_attack: AttackData
## Attack of the second button. Null = the form has no second attack.
@export var secondary_attack: AttackData

@export_group("World look")
## Multiplies the screen color while this form is active.
@export var world_tint: Color = Color.WHITE
@export_range(0.0, 2.0, 0.01) var world_saturation: float = 1.0
@export_range(0.0, 2.0, 0.01) var world_contrast: float = 1.0

## Resolves the transformation duration from an override or this form's SFX.
func get_transform_duration() -> float:
	if transform_time > 0.0:
		return maxf(transform_time, MIN_TRANSFORM_DURATION)

	var transform_sfx: SoundEffect = audio.form_change_sfx if audio else null
	if transform_sfx and transform_sfx.stream:
		var stream_length: float = transform_sfx.stream.get_length()
		if stream_length > 0.0:
			return maxf(stream_length, MIN_TRANSFORM_DURATION)

	if not _warned_about_transform_duration:
		var form_name: String = display_name
		if form_name.is_empty():
			form_name = String(id)
		if form_name.is_empty():
			form_name = resource_name
		if form_name.is_empty():
			form_name = "<unnamed>"
		push_warning(
			"PlayerForm '%s' has no measurable transformation SFX; using %.2f seconds."
			% [form_name, DEFAULT_TRANSFORM_DURATION]
		)
		_warned_about_transform_duration = true
	return DEFAULT_TRANSFORM_DURATION
