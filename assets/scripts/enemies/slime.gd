extends CharacterBody2D

@onready var animated_sprite = $AnimatedSprite2D

const SPEED = 100.0
const CHASE_SPEED = 80.0
const DETECTION_RANGE = 150.0
const STOP_RANGE = 40.0
var health = 3
var is_dead = false
var is_chasing = false
var player = null

func _physics_process(delta):
	if is_dead:
		return

	# Find player if not set
	if player == null:
		player = get_tree().get_first_node_in_group("player")

	# Check distance to player
	if player:
		var distance = global_position.distance_to(player.global_position)
		if distance < DETECTION_RANGE:
			is_chasing = true
		elif distance > DETECTION_RANGE * 1.5:
			is_chasing = false

	# Chase or idle
	if is_chasing and player:
		var distance = global_position.distance_to(player.global_position)
		var direction = global_position.direction_to(player.global_position)
		# Stop at minimum distance to avoid overlapping
		if distance > STOP_RANGE:
			velocity = direction * CHASE_SPEED
			animated_sprite.play("walk")
		else:
			velocity = Vector2.ZERO
			animated_sprite.play("idle")
		if direction.x < 0:
			animated_sprite.flip_h = true
		else:
			animated_sprite.flip_h = false
	else:
		velocity = Vector2.ZERO
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
	is_chasing = false
	animated_sprite.play("death")
	await animated_sprite.animation_finished
	queue_free()
