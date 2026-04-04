extends CanvasLayer

@onready var heart_container = $HeartContainer

const MAX_HEARTS = 5
const HEART_SIZE = 16

var heart_nodes = []
var player = null

func _ready():
	create_hearts()
	# Don't connect to player yet - wait for main.gd to load the level
	# We'll be notified via connect_to_player() method

func connect_to_player(p: Node):
	# Disconnect from old player if any
	if player and is_instance_valid(player) and player.has_signal("health_changed"):
		if player.health_changed.is_connected(_on_player_health_changed):
			player.health_changed.disconnect(_on_player_health_changed)

	player = p
	if player and is_instance_valid(player) and player.has_signal("health_changed"):
		player.health_changed.connect(_on_player_health_changed)
		print("HealthUI: Connected to ", player.name, " ID=", player.get_instance_id())
	# Update hearts to reflect current health
	update_hearts()

func create_hearts():
	for i in range(MAX_HEARTS):
		var heart = TextureRect.new()
		heart.custom_minimum_size = Vector2(32, 32)
		heart.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		heart.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		heart_container.add_child(heart)
		heart_nodes.append(heart)
		update_heart_texture(heart, i, 4)  # Start with full

func update_heart_texture(heart_node, heart_index, state):
	var atlas_tex = AtlasTexture.new()
	atlas_tex.atlas = load("res://assets/images/tilesets/Heart.png")
	# Column 0 = empty, Column 2 = half, Column 4 = full
	# Each heart is 16px wide, so full state is at x = heart_index * 16 + 4
	# But states are in columns 0, 2, 4 (16px apart)
	atlas_tex.region = Rect2(state * HEART_SIZE, 0, HEART_SIZE, HEART_SIZE)
	heart_node.texture = atlas_tex

func update_hearts():
	if heart_nodes.is_empty():
		return
	var current_health = PlayerData.health
	var max_health = PlayerData.max_health
	print("HealthUI: update_hearts called, health=", current_health, "/", max_health)
	var health_per_heart = max_health / float(MAX_HEARTS)

	for i in range(MAX_HEARTS):
		var heart_start = i * health_per_heart
		var state: int
		if current_health >= heart_start + health_per_heart:
			state = 4  # Full
		elif current_health > heart_start:
			state = 2  # Half
		else:
			state = 0  # Empty

		update_heart_texture(heart_nodes[i], i, state)

func _on_player_health_changed():
	print("HealthUI: _on_player_health_changed called!")
	print("HealthUI: PlayerData.health=", PlayerData.health)
	print("HealthUI: heart_nodes count=", heart_nodes.size())
	update_hearts()
