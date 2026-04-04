extends Area2D

@export var heal_amount: int = 10

func _ready():
	body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	if body.has_method("take_damage"):
		# Heal the player, capped at max_health
		var new_health = min(body.health + heal_amount, body.max_health)
		body.health = new_health
		PlayerData.health = new_health
		body.health_changed.emit()
		if body.health_bar:
			body.health_bar.value = new_health
		print("HealItem: healed player for ", heal_amount, " points. Health now: ", new_health)
		queue_free()
