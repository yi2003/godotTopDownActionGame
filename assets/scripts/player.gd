extends CharacterBody2D

@onready var animated_sprite = $AnimatedSprite2D
@onready var hitbox = $Hitbox
@onready var hitbox_shape = $Hitbox/HitboxShape

const SPEED = 300.0
var last_direction = Vector2(0, 1)
var is_attacking = false

func _ready():
	add_to_group("player")
	hitbox.body_entered.connect(_on_hitbox_body_entered)

func _physics_process(delta):
	if Input.is_action_just_pressed("ui_accept") and not is_attacking:
		perform_attack()
		return

	if not is_attacking:
		var direction_x = Input.get_axis("ui_left", "ui_right")
		var direction_y = Input.get_axis("ui_up", "ui_down")

		velocity = Vector2(direction_x, direction_y) * SPEED

		if direction_x != 0:
			last_direction.x = direction_x
			last_direction.y = 0
			animated_sprite.play("run_right")
			animated_sprite.flip_h = direction_x < 0
		elif direction_y < 0:
			last_direction.y = -1
			animated_sprite.play("run_up")
		elif direction_y > 0:
			last_direction.y = 1
			animated_sprite.play("run_down")
		elif direction_x == 0 and direction_y == 0:
			if last_direction.y < 0:
				animated_sprite.play("idle_up")
			elif last_direction.y > 0:
				animated_sprite.play("idle_right")
			else:
				animated_sprite.play("idle_right")

	move_and_slide()

func perform_attack():
	is_attacking = true
	hitbox_shape.disabled = false

	if last_direction.y < 0:
		animated_sprite.play("attack_up")
		hitbox.position = Vector2(0, -30)
	elif last_direction.y > 0:
		animated_sprite.play("attack_down")
		hitbox.position = Vector2(0, 30)
	else:
		animated_sprite.play("attack_right")
		animated_sprite.flip_h = last_direction.x < 0
		hitbox.position = Vector2(50 * last_direction.x, 0)

	animated_sprite.animation_finished.connect(_on_attack_finished)

func _on_attack_finished():
	is_attacking = false
	hitbox_shape.disabled = true
	animated_sprite.animation_finished.disconnect(_on_attack_finished)

func _on_hitbox_body_entered(body):
	print("Hit: ", body.name)
	if body.has_method("take_damage"):
		body.take_damage()
		# Apply knockback in the direction the player is facing
		var knockback = last_direction * 300
		if body.has_method("apply_knockback"):
			body.apply_knockback(knockback)
