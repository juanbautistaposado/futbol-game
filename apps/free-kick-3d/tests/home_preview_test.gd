extends SceneTree

const SAVE := "/tmp/futbol-home-player-preview-test.cfg"
var completed := false

func _initialize() -> void:
	call_deferred("run")

func _finalize() -> void:
	var release := InputEventMouseButton.new()
	release.button_index = MOUSE_BUTTON_LEFT
	release.pressed = false
	Input.parse_input_event(release)

func mouse_button(position: Vector2, pressed: bool) -> void:
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = pressed
	event.button_mask = MOUSE_BUTTON_MASK_LEFT if pressed else 0
	# Input.parse_input_event receives native window pixels. The UI rect and
	# Camera3D projection use the logical viewport under canvas_items stretch.
	event.position = root.get_final_transform() * position
	event.global_position = event.position
	Input.parse_input_event(event)
	await settle()

func mouse_motion(position: Vector2, relative: Vector2, pressed := false) -> void:
	var event := InputEventMouseMotion.new()
	event.position = root.get_final_transform() * position
	event.global_position = event.position
	event.relative = root.get_final_transform().basis_xform(relative)
	event.button_mask = MOUSE_BUTTON_MASK_LEFT if pressed else 0
	Input.parse_input_event(event)
	await settle()

func yaw_change(before: float, after: float) -> float:
	return absf(wrapf(after - before, -PI, PI))

func settle() -> void:
	for i in range(3):
		await process_frame

func run() -> void:
	create_timer(30.0).timeout.connect(func() -> void:
		if not completed:
			printerr("FAIL: home preview test did not finish within 30 seconds")
			quit(1)
	)
	DirAccess.remove_absolute(SAVE)
	var menu = load("res://Menu.tscn").instantiate()
	menu.save_path = SAVE
	root.add_child(menu)
	# Wait for the new native window and its GUI to finish their first layout.
	for i in range(20):
		await process_frame
	var player: Node3D = menu.background.player
	for resolution in [Vector2i(1280, 720), Vector2i(1024, 640), Vector2i(1920, 1080)]:
		root.size = resolution
		await settle()
		var preview: Control = menu.home_player_preview
		assert(is_instance_valid(preview) and preview.visible)
		var area := preview.get_global_rect()
		print("HOME_PREVIEW_LAYOUT requested=", resolution, " window=", root.size, " menu=", menu.size, " area=", area, " transform=", root.get_final_transform())
		assert(area.size.x > 40.0 and area.size.y > 100.0, "Player must have an accessible drag area")
		var point := area.get_center()
		assert(Rect2(Vector2.ZERO, menu.size).has_point(point), "Drag area must remain on screen after resizing")
		assert(not menu.play_button.get_global_rect().intersects(area), "Player interaction must leave Jugar usable")
		var configure: Control = menu.page.get_node("HomePoster/ConfigureButton")
		assert(not configure.get_global_rect().intersects(area), "Player interaction must leave Configurar usable")
		var before := player.rotation
		await mouse_motion(point, Vector2(50, 0))
		assert(player.rotation.is_equal_approx(before), "Hover must not rotate the player")
		await mouse_button(point, true)
		assert(preview.dragging, "A real mouse press over the player must start drag")
		await mouse_motion(point + Vector2(70, 36), Vector2(70, 36), true)
		assert(yaw_change(before.y, player.rotation.y) > 0.08, "Horizontal drag must visibly rotate the player")
		assert(is_equal_approx(before.x, player.rotation.x) and is_equal_approx(before.z, player.rotation.z), "Dragging must keep the player upright")
		var yaw := player.rotation.y
		await mouse_motion(point + Vector2(70, 76), Vector2(0, 40), true)
		assert(is_equal_approx(yaw, player.rotation.y), "Pure vertical drag must not spin the player")
		# Continue outside the preview, then release: rotation must not get stuck.
		var outside := Vector2(menu.size.x - 4.0, 6.0)
		await mouse_motion(outside, Vector2(45, -30), true)
		assert(yaw_change(yaw, player.rotation.y) > 0.02, "Captured drag must continue beyond the preview")
		await mouse_button(outside, false)
		assert(not preview.dragging)
		yaw = player.rotation.y
		await mouse_motion(point, Vector2(-50, 0))
		assert(is_equal_approx(yaw, player.rotation.y), "Release outside must end rotation")
		# A press that begins on a button cannot become a player drag.
		var button_point: Vector2 = menu.play_button.get_global_rect().get_center()
		await mouse_motion(button_point, Vector2.ZERO)
		await mouse_button(button_point, true)
		assert(not preview.dragging, "Jugar press must belong to the button")
		await mouse_motion(point, point - button_point, true)
		assert(is_equal_approx(yaw, player.rotation.y), "Dragging from a button must not rotate the player")
		await mouse_button(point, false)
		assert(menu.home_screen, "Releasing off Jugar must not activate the button")
	# Leaving home while dragging must remove the capture before another page opens.
	var old_preview: Control = menu.home_player_preview
	var point := old_preview.get_global_rect().get_center()
	await mouse_button(point, true)
	assert(old_preview.dragging)
	menu.show_settings()
	var yaw := player.rotation.y
	assert(menu.home_player_preview == null)
	assert(not old_preview.dragging)
	await mouse_motion(point + Vector2(80, 0), Vector2(80, 0), true)
	assert(is_equal_approx(yaw, player.rotation.y), "Changing pages must cancel pending rotation")
	await mouse_button(point, false)
	# The home gesture must not interfere with the editor's own rotation controls.
	menu.show_custom_striker()
	await settle()
	yaw = player.rotation.y
	await mouse_button(point, true)
	await mouse_motion(point + Vector2(80, 0), Vector2(80, 0), true)
	await mouse_button(point + Vector2(80, 0), false)
	assert(is_equal_approx(yaw, player.rotation.y), "Home mouse drag must be inactive in the character editor")
	var editor: Control = menu.page.get_node("CharacterEditor")
	editor.rotation_requested.emit(0.3)
	assert(yaw_change(yaw, player.rotation.y) > 0.2, "Existing editor rotation must still work")
	menu.show_menu()
	await settle()
	assert(not menu.background.editor_enabled)
	var preview: Control = menu.home_player_preview
	assert(is_instance_valid(preview) and not preview.dragging)
	point = preview.get_global_rect().get_center()
	yaw = player.rotation.y
	await mouse_button(point, true)
	await mouse_motion(point + Vector2(-60, 0), Vector2(-60, 0), true)
	await mouse_button(point + Vector2(-60, 0), false)
	assert(yaw_change(yaw, player.rotation.y) > 0.08, "Player drag must work after returning home")
	menu.queue_free()
	await process_frame
	DirAccess.remove_absolute(SAVE)
	completed = true
	print("PASS: real mouse drag rotates home player upright, releases outside, respects buttons/pages/editor and works after resizing and returning")
	quit()
