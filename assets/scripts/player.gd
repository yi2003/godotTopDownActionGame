extends CharacterBody2D

@onready var animated_sprite = $AnimatedSprite2D
@onready var health_bar = $HealthBar
@onready var hitbox = $Hitbox
@onready var hitbox_shape = $Hitbox/HitboxShape
@onready var camera = $Camera2D

const SPEED = 300.0
var last_direction = Vector2(0, 1)
var is_attacking = false
var health = 100
var max_health = 100
var is_dead = false
var is_invincible = false
var invincibility_duration = 0.5
var knockback_velocity = Vector2.ZERO
const KNOCKBACK_DECAY = 0.85

func _ready():
	print("=== PLAYER _READY() STARTED ===")
	print("Player parent: ", get_parent().name if get_parent() else "null")
	print("Player path: ", get_path())
	add_to_group("player")
	if health_bar:
		health_bar.max_value = max_health
		health_bar.value = health
	_setup_camera_limits()
	print("=== PLAYER _READY() ENDED ===")

func _physics_process(delta):
	if is_dead:
		return

	# Apply knockback
	if knockback_velocity.length() > 1:
		velocity = knockback_velocity
		knockback_velocity *= KNOCKBACK_DECAY
		move_and_slide()
		return

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

func _setup_camera_limits():
	var tilemap = get_node("../TileMapLayer_Terrian") as TileMapLayer
	if tilemap == null:
		print("Player: TileMap not found as sibling (../TileMapLayer_Terrian)")
		# Try alternative: search in parent
		var parent_node = get_parent()
		if parent_node:
			tilemap = parent_node.get_node("TileMapLayer_Terrian") as TileMapLayer
			if tilemap:
				print("Player: Found TileMap in parent")
			else:
				print("Player: Parent children: ", parent_node.get_children())
		return

	var used_rect = tilemap.get_used_rect()
	if used_rect.size == Vector2i.ZERO:
		print("Player: Used rect empty")
		return

	var tile_size = tilemap.tile_set.tile_size
	var tile_scale = tilemap.scale

	# Convert tile_size from Vector2i to Vector2 for proper multiplication
	var tile_size_f = Vector2(tile_size.x, tile_size.y)

	# Convert cell rect to world rect, including tilemap's position offset
	var world_rect_start = tilemap.position + Vector2(used_rect.position) * tile_size_f * tile_scale
	var world_rect_size = Vector2(used_rect.size) * tile_size_f * tile_scale

	var world_right = world_rect_start.x + world_rect_size.x
	var world_bottom = world_rect_start.y + world_rect_size.y

	print("Player: TileMap used rect (cells): ", used_rect)
	print("Player: TileMap world bounds: x=", world_rect_start.x, " to ", world_right, ", y=", world_rect_start.y, " to ", world_bottom)

	# Calculate how much of the world should be visible on each side
	var viewport_width = get_viewport().size.x
	var viewport_height = get_viewport().size.y
	var half_view_x = viewport_width / (2 * camera.zoom.x)
	var half_view_y = viewport_height / (2 * camera.zoom.y)

	print("Player: Viewport=", viewport_width, "x", viewport_height, " zoom=", camera.zoom, " half_view=", half_view_x, "x", half_view_y)

	# Set camera limits with padding so player can reach screen edges
	camera.limit_left = world_rect_start.x - half_view_x
	camera.limit_right = world_right + half_view_x
	camera.limit_top = world_rect_start.y - half_view_y
	camera.limit_bottom = world_bottom + half_view_y

	camera.make_current()

	print("Player: Camera limits - L:", camera.limit_left, " R:", camera.limit_right, " T:", camera.limit_top, " B:", camera.limit_bottom)

func apply_knockback(force: Vector2):
	knockback_velocity = force

func take_damage(damage_amount: int = 1):
	if is_dead or is_invincible:
		return
	is_invincible = true
	health -= damage_amount
	if health_bar:
		health_bar.value = health
	print("Player took damage! Health: ", health)
	# Flash to indicate invincibility
	animated_sprite.modulate.a = 0.5
	await get_tree().create_timer(invincibility_duration).timeout
	animated_sprite.modulate.a = 1.0
	is_invincible = false
	if health <= 0:
		die()

func die():
	is_dead = true
	velocity = Vector2.ZERO
	animated_sprite.play("die")
	await animated_sprite.animation_finished
	# Reset to main menu or respawn
	get_tree().change_scene_to_file("res://assets/scenes/level_root.tscn")
