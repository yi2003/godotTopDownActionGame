extends CharacterBody2D

@onready var animated_sprite = $AnimatedSprite2D
@onready var health_bar = $HealthBar
@onready var damage_zone = $DamageZone
@onready var damage_zone_shape = $DamageZone/DamageZoneShape

const SPEED = 100.0
const CHASE_SPEED = 80.0
const DETECTION_RANGE = 150.0
const KNOCKBACK_DECAY = 0.85
const DAMAGE_AMOUNT = 1
const ATTACK_COOLDOWN = 1.0
const ATTACK_RANGE = 30.0

var health = 3
var max_health = 3
var is_dead = false
var is_chasing = false
var player = null
var knockback_velocity = Vector2.ZERO

enum State { CHASE, ATTACK, IDLE }
var state = State.CHASE
var idle_timer = 0.0

func _ready():
	health_bar.max_value = max_health
	health_bar.value = health

func _physics_process(delta):
	if is_dead:
		return

	# Apply knockback
	if knockback_velocity.length() > 1:
		velocity = knockback_velocity
		knockback_velocity *= KNOCKBACK_DECAY
		move_and_slide()
		return

	# Find player if not set
	if player == null:
		player = get_tree().get_first_node_in_group("player")

	# Check distance to player and update chasing state
	if player:
		var distance = global_position.distance_to(player.global_position)
		if distance < DETECTION_RANGE:
			is_chasing = true
		elif distance > DETECTION_RANGE * 1.5:
			is_chasing = false

	# State machine
	if is_chasing and player:
		match state:
			State.CHASE:
				var distance = global_position.distance_to(player.global_position)
				var direction = global_position.direction_to(player.global_position)
				if distance > ATTACK_RANGE:
					velocity = direction * CHASE_SPEED
					animated_sprite.play("walk")
				else:
					velocity = Vector2.ZERO
					animated_sprite.play("idle")
					state = State.ATTACK
				# Face player
				if direction.x < 0:
					animated_sprite.flip_h = true
				else:
					animated_sprite.flip_h = false

			State.ATTACK:
				velocity = Vector2.ZERO
				animated_sprite.play("attack")
				# Deal damage if player is within attack range
				var distance = global_position.distance_to(player.global_position)
				if distance <= ATTACK_RANGE and not player.is_dead:
					if player.has_method("take_damage"):
						player.take_damage()
						var knockback_dir = (player.global_position - global_position).normalized()
						var knockback = knockback_dir * 300
						if player.has_method("apply_knockback"):
							player.apply_knockback(knockback)
				state = State.IDLE
				idle_timer = ATTACK_COOLDOWN

			State.IDLE:
				velocity = Vector2.ZERO
				animated_sprite.play("idle")
				idle_timer -= delta
				if idle_timer <= 0:
					state = State.CHASE
	else:
		velocity = Vector2.ZERO
		animated_sprite.play("idle")
		state = State.CHASE

	move_and_slide()

func apply_knockback(force: Vector2):
	knockback_velocity = force

func take_damage():
	if is_dead:
		return
	health -= 1
	health_bar.value = health
	print("Slime took damage! Health: ", health)
	if health <= 0:
		die()

func die():
	is_dead = true
	is_chasing = false
	state = State.IDLE
	health_bar.visible = false
	animated_sprite.play("death")
	await animated_sprite.animation_finished
	queue_free()
