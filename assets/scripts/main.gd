extends Node2D

var current_level: Node2D = null
var player: Node = null

func _ready():
	print("[Main] _ready() - Starting game")
	# Remove the design-time placeholder LevelRoot (if it exists)
	var placeholder = $LevelRoot
	if placeholder:
		print("[Main] Removing placeholder LevelRoot")
		placeholder.queue_free()
		placeholder = null
	# Load the first actual level
	load_level("res://assets/scenes/level_1.tscn")

func load_level(level_path: String):
	# Remove existing level if any
	if current_level:
		current_level.queue_free()
		current_level = null

	# Load and instance the new level
	var level_scene = load(level_path)
	if not level_scene:
		print("[Main] ERROR: Failed to load level at ", level_path)
		return
	current_level = level_scene.instantiate()
	add_child(current_level)
	print("[Main] Loaded level: ", level_path)

	# Connect to the level's level_completed signal
	if current_level.has_signal("level_completed"):
		current_level.level_completed.connect(_on_level_completed)
	else:
		print("[Main] WARNING: Level does not have level_completed signal")

	# Find player and connect death signal
	var new_player = current_level.get_node_or_null("Player")
	if new_player:
		if player and player.is_connected("player_died", _on_player_died):
			player.player_died.disconnect(_on_player_died)
		player = new_player
		player.player_died.connect(_on_player_died)
		print("[Main] Connected to player death signal")

	# Fade in from black when level loads
	var fade = $FadeOverlay
	if fade:
		fade.fade_in(1.0)

func _on_level_completed(next_level_path: String):
	print("[Main] Level completed, loading next level: ", next_level_path)
	# Fade out before transitioning
	var fade = $FadeOverlay
	if fade:
		await fade.fade_out_complete(1.0)
	load_level(next_level_path)

func _on_player_died():
	print("[Main] Player died - fading to black...")
	var fade = $FadeOverlay
	if fade:
		await fade.fade_out_complete(1.0)
	# Reset health and restart from level 1
	PlayerData.health = PlayerData.max_health
	PlayerData.last_direction = Vector2(0, 1)
	print("[Main] Restarting from level 1")
	load_level("res://assets/scenes/level_1.tscn")
