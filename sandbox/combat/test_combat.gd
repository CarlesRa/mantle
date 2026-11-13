extends Node2D

@onready var hitbox: Hitbox = $Attacker/Hitbox
@onready var target: Node2D = $Target

func _ready() -> void:
	print("--- Combat Tests Started ---")

	# Test 1: One hit per target per activation.
	hitbox.activate()

	await get_tree().physics_frame
	await get_tree().physics_frame

	print("Test 1 - Target hit count: ", target.hit_count)

	# Test 2: A new activation allows another hit.
	hitbox.deactivate()
	hitbox.activate()

	await get_tree().physics_frame

	print("Test 2 - Target hit count: ", target.hit_count)

	# Test 3: The attacker must not hit itself.
	hitbox.deactivate()
	hitbox.activate()

	await get_tree().physics_frame

	print("Test 3 - Attacker hit count: ", $Attacker.hit_count)
