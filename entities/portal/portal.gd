## Fixed portal that turns the player into the assigned form.
## Place it with its origin on the ground.
class_name FormPortal
extends Area2D

const PORTAL_TINT_SHADER: Shader = preload("res://entities/portal/portal_tint.gdshader")

@onready var _sprite: AnimatedSprite2D = $AnimatedSprite2D
var _tint_material: ShaderMaterial
var _is_active: bool = true

@export var starts_active: bool = true
@export var form: PlayerForm:
	set(value):
		form = value
		_update_sprite_color()
@export var sfx: SoundEffect

func _ready() -> void:
	_tint_material = ShaderMaterial.new()
	_tint_material.shader = PORTAL_TINT_SHADER
	_sprite.material = _tint_material
	_update_sprite_color()
	set_active(starts_active)

func set_active(value: bool) -> void:
	_is_active = value
	visible = value
	set_physics_process(value)
	if value:
		AudioManager.play_sfx(sfx, 0.6)

func _update_sprite_color() -> void:
	if is_instance_valid(_tint_material):
		_tint_material.set_shader_parameter(
			"tint_color", form.portal_color if form else Color.WHITE
		)

# Polled instead of using body_entered so a transformation that was blocked
# (the new hitbox did not fit) is retried while the player stays inside.
func _physics_process(_delta: float) -> void:
	if not _is_active or not form:
		return
	for body: Node2D in get_overlapping_bodies():
		var player: Player = body as Player
		if player:
			player.change_form(form)
