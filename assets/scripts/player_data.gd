extends Node

# PlayerData singleton - persists across scene changes
# Stores all player stats that should survive level transitions

var health: int = 100
var max_health: int = 100
var last_direction: Vector2 = Vector2(0, 1)

func reset():
	health = max_health
	last_direction = Vector2(0, 1)
