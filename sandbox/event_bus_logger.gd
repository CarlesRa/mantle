extends Node
## Script for testing signal transmission.

func _ready() -> void:
	EventBus.player_jumped.connect(_on_player_jumped)
	EventBus.player_landed.connect(_on_player_landed)
	EventBus.player_hit.connect(_on_player_hit)
	EventBus.player_died.connect(_on_player_died)

func _on_player_jumped() -> void:
	print("Signal player_jumped emitted.")

func _on_player_landed() -> void:
	print("Signal player_landed emitted.")

func _on_player_hit() -> void:
	print("Signal player_hit emitted.")

func _on_player_died() -> void:
	print("Signal player_died emitted.")
