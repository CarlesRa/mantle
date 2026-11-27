extends CanvasLayer

@onready var health_bar: HealthBar = %HealthBar


func _ready() -> void:
	EventBus.player_health_changed.connect(health_bar.set_health)
