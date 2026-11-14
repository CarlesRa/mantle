extends Node2D

var hit_count: int = 0

func receive_hit(_hit_data: HitData) -> void:
	hit_count += 1
	print("Attacker hit! Count: ", hit_count)
