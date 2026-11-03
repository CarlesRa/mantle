extends Node
## Script for testing signal transmission.

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	EventBus.player_jumped.connect(_on_player_jumped)
	EventBus.player_landed.connect(_on_player_landed)

func _on_player_jumped() -> void:
	print("Signal player_jumped emmited.")

func _on_player_landed() -> void:
	print("Signal player_landed emmited.")
