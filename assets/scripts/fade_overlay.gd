extends CanvasLayer

var fade_rect: ColorRect
var is_fading: bool = false

func _ready():
	# Create the full-screen black overlay
	fade_rect = ColorRect.new()
	fade_rect.name = "FadeRect"
	fade_rect.color = Color.BLACK
	fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(fade_rect)

	# Connect to tree changed to update rect when scene loads
	get_tree().root.size_changed.connect(_on_viewport_size_changed)
	_on_viewport_size_changed()

	# Start invisible (fully transparent)
	fade_rect.modulate.a = 0.0

func _on_viewport_size_changed():
	var viewport = get_viewport()
	var size = viewport.size
	# Convert Vector2i to Vector2
	fade_rect.rect_size = Vector2(size.x, size.y)
	fade_rect.rect_position = Vector2.ZERO

# Fade to a target alpha - returns a signal that completes when done
func fade_to(target_alpha: float, duration: float = 1.0) -> Signal:
	if is_fading:
		push_warning("Fade already in progress")
		# Return an already completed signal
		var t = get_tree().create_timer(0.0)
		return t.timeout
	is_fading = true

	fade_rect.modulate.a = 1.0 - target_alpha if target_alpha < 0.5 else target_alpha
	var tween = create_tween()
	tween.tween_property(fade_rect, "modulate:a", target_alpha, duration)
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_LINEAR)

	var completed = tween.finished
	tween.connect("finished", _on_fade_complete)
	return completed

func _on_fade_complete():
	is_fading = false

# Fade in from black to transparent - returns awaitable signal
func fade_in(duration: float = 1.0) -> Signal:
	fade_rect.modulate.a = 1.0
	return fade_to(0.0, duration)

# Fade out to black - returns awaitable signal
func fade_out(duration: float = 0.5) -> Signal:
	fade_rect.modulate.a = 0.0
	return fade_to(1.0, duration)

# For backwards compatibility with existing code using await fade.fade_out_complete()
func fade_out_complete(duration: float = 1.0) -> Signal:
	return fade_out(duration)

