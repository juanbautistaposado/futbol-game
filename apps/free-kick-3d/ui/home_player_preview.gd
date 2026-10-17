extends Control
## A drag surface follows the projected player without covering the menu buttons.

signal rotation_requested(amount: float)

const PLAYER_BOUNDS := AABB(Vector3(-0.65, 0.0, -0.45), Vector3(1.3, 2.1, 0.9))
var camera: Camera3D
var actor: Node3D
var dragging := false
var enabled := true

func configure(preview_camera: Camera3D, preview_actor: Node3D) -> void:
	camera = preview_camera
	actor = preview_actor
	update_bounds()

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	focus_mode = Control.FOCUS_NONE
	mouse_default_cursor_shape = Control.CURSOR_MOVE
	update_bounds()

func update_bounds() -> void:
	if not is_instance_valid(camera) or not is_instance_valid(actor) or not is_inside_tree():
		return
	var parent_transform := (get_parent() as CanvasItem).get_global_transform_with_canvas().affine_inverse()
	var projected := Rect2()
	for corner in range(8):
		var point := parent_transform * camera.unproject_position(actor.to_global(PLAYER_BOUNDS.get_endpoint(corner)))
		if corner == 0:
			projected = Rect2(point, Vector2.ZERO)
		else:
			projected = projected.expand(point)
	# Keep the drag surface inside the visible viewport.
	var viewport_rect := get_viewport_rect()
	var top_left := parent_transform * viewport_rect.position
	var bottom_right := parent_transform * viewport_rect.end
	projected = projected.intersection(Rect2(top_left, bottom_right - top_left))
	projected.size.y = minf(projected.size.y + 38.0, bottom_right.y - projected.position.y)
	position = projected.position
	size = projected.size

func _process(_delta: float) -> void:
	if enabled:
		update_bounds()

func _gui_input(event: InputEvent) -> void:
	if not enabled:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		dragging = true
		mouse_default_cursor_shape = Control.CURSOR_DRAG
		accept_event()

func _input(event: InputEvent) -> void:
	if not enabled or not dragging:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		cancel_drag()
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseMotion:
		if (event.button_mask & MOUSE_BUTTON_MASK_LEFT) == 0:
			cancel_drag()
			return
		rotation_requested.emit(event.relative.x * TAU / maxf(get_viewport_rect().size.x, 1.0))
		get_viewport().set_input_as_handled()

func cancel_drag() -> void:
	dragging = false
	mouse_default_cursor_shape = Control.CURSOR_MOVE

func deactivate() -> void:
	enabled = false
	cancel_drag()
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_process(false)
	set_process_input(false)

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_WM_WINDOW_FOCUS_OUT:
		cancel_drag()

func _exit_tree() -> void:
	cancel_drag()
