extends Node2D

@export var next_level_path: String = ""

signal level_completed(next_level_path: String)

func _ready():
	print("[LevelRoot] _ready() STARTED")
	print("[LevelRoot] scene path: ", get_scene_file_path())
	print("[LevelRoot] next_level_path = '", next_level_path, "'")
	print("[LevelRoot] node name: ", name)
	print("[LevelRoot] parent: ", get_parent().name if get_parent() else "none")

	var exit_node = get_node_or_null("Exit")
	print("[LevelRoot] Exit node found: ", exit_node != null)

	if exit_node:
		print("[LevelRoot] Exit type: ", exit_node.get_class())
		print("[LevelRoot] Exit collision_layer: ", exit_node.collision_layer)
		print("[LevelRoot] Exit collision_mask (before): ", exit_node.collision_mask)
		print("[LevelRoot] Exit monitoring (before): ", exit_node.monitoring)

		# Ensure exit is properly configured
		exit_node.monitoring = true
		exit_node.collision_mask = 3  # Detect both layer 1 (bit0) and layer 2 (bit1)
		print("[LevelRoot] Exit collision_mask (after): ", exit_node.collision_mask)
		print("[LevelRoot] Exit monitoring (after): ", exit_node.monitoring)

		print("[LevelRoot] Exit position: ", exit_node.global_position)
		var shape_node = exit_node.get_node_or_null("CollisionShape2D")
		if shape_node:
			print("[LevelRoot] Exit shape: ", shape_node.shape)
			if shape_node.shape and shape_node.shape is RectangleShape2D:
				print("[LevelRoot] Exit shape size: ", shape_node.shape.size)
			print("[LevelRoot] Exit shape disabled (before): ", shape_node.disabled)
			if shape_node.disabled:
				print("[LevelRoot] Enabling Exit shape!")
				shape_node.disabled = false
			print("[LevelRoot] Exit shape disabled (after): ", shape_node.disabled)
		else:
			print("[LevelRoot] ERROR: Exit has no CollisionShape2D child!")

		var conn = exit_node.body_entered.get_connections()
		if conn.is_empty():
			print("[LevelRoot] Connecting body_entered signal...")
			exit_node.body_entered.connect(_on_exit_body_entered)
		else:
			print("[LevelRoot] body_entered already connected, connections: ", conn)

	# Check player
	var player = get_node_or_null("Player")
	if player:
		print("[LevelRoot] Player found: ", player)
		print("[LevelRoot] Player collision_layer (original): ", player.collision_layer if "collision_layer" in player else "N/A")
		# Ensure player is on a detectable layer
		if "collision_layer" in player:
			player.collision_layer = 1
			print("[LevelRoot] Player collision_layer (set to): ", player.collision_layer)

func _process(_delta):
	var exit_node = get_node_or_null("Exit")
	if exit_node:
		var player = get_node_or_null("Player")
		if player:
			var dist = exit_node.global_position.distance_to(player.global_position)
			#print("[LevelRoot] Player distance to Exit: ", dist)
			# Debug overlap check
			if exit_node.overlaps_body(player):
				print("[LevelRoot] >>> OVERLAP DETECTED (overlaps_body) <<<")

func _on_exit_body_entered(body):
	print("[LevelRoot] === EXIT ENTERED ===")
	print("[LevelRoot] body name: ", body.name)
	print("[LevelRoot] body group 'player': ", body.is_in_group("player"))
	print("[LevelRoot] next_level_path: '", next_level_path, "'")
	if body.is_in_group("player"):
		if next_level_path != "":
			print("[LevelRoot] Emitting level_completed signal")
			level_completed.emit(next_level_path)
		else:
			print("[LevelRoot] ERROR: next_level_path is empty!")
