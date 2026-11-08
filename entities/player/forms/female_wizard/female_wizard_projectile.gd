class_name FemaleWizardProjectile
extends Area2D

@export var speed: float = 500.0
@export var lifetime: float = 3.0

var _direction: float = 0.0
var _damage: int = 1
var _launched: bool = false


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func launch(direction: float, damage: int) -> void:
	_direction = signf(direction)
	_damage = damage
	_launched = true
	$AnimatedSprite2D.flip_h = _direction < 0.0


func _physics_process(delta: float) -> void:
	if not _launched:
		return

	global_position.x += _direction * speed * delta

	lifetime -= delta
	if lifetime <= 0.0:
		queue_free()


## Damages the body on impact and destroys the projectile.
func _on_body_entered(body: Node2D) -> void:
	if body.has_method("take_hit"):
		body.take_hit(global_position, _damage)

	queue_free()
