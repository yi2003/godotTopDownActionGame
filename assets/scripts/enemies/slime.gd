extends CharacterBody2D

@onready var animated_sprite = $AnimatedSprite2D

const SPEED = 100.0
var health = 3
var is_dead = false

func _physics_process(delta):
	if is_dead:
		return
	animated_sprite.play("idle")
	move_and_slide()

func take_damage():
	if is_dead:
		return
	health -= 1
	print("Slime took damage! Health: ", health)
	if health <= 0:
		die()

func die():
	is_dead = true
	animated_sprite.play("death")
	await animated_sprite.animation_finished
	queue_free()
