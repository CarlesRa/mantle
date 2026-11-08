## Fixed portal that turns the player into the assigned form.
## Place it with its origin on the ground; it draws itself with the form color.
class_name FormPortal
extends Area2D

const SIZE: Vector2 = Vector2(28.0, 60.0)
const POINTS: int = 24

@export var form: PlayerForm:
	set(value):
		form = value
		queue_redraw()

var _time: float = 0.0

func _process(delta: float) -> void:
	_time += delta
	queue_redraw()

# Polled instead of using body_entered so a transformation that was blocked
# (the new hitbox did not fit) is retried while the player stays inside.
func _physics_process(_delta: float) -> void:
	if not form:
		return
	for body: Node2D in get_overlapping_bodies():
		var player: Player = body as Player
		if player:
			player.change_form(form)

func _draw() -> void:
	var color: Color = form.portal_color if form else Color.WHITE
	var center: Vector2 = Vector2(0.0, -SIZE.y / 2.0)
	var pulse: float = 0.5 + 0.5 * sin(_time * 3.0)
	var outline: PackedVector2Array = PackedVector2Array()
	for i: int in POINTS + 1:
		var angle: float = TAU * float(i) / float(POINTS)
		outline.append(center + Vector2(cos(angle) * SIZE.x / 2.0, sin(angle) * SIZE.y / 2.0))
	var fill: Color = color
	fill.a = 0.25 + 0.2 * pulse
	draw_colored_polygon(outline, fill)
	draw_polyline(outline, color, 2.0)
