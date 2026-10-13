extends Node

## Headless smoke test. Run with the command documented in docs/SETUP.md.


func _ready() -> void:
	var failures: Array[String] = []
	if not is_instance_valid(GameManager):
		failures.append("GameManager autoload is unavailable")
	if not is_instance_valid(ResourceStore):
		failures.append("ResourceStore autoload is unavailable")
	if not is_instance_valid(SaveSystem):
		failures.append("SaveSystem autoload is unavailable")
	if not is_instance_valid(Constants):
		failures.append("Constants autoload is unavailable")
	if ResourceStore.snapshot().size() != 6:
		failures.append("ResourceStore did not initialize all six resources")
	var rts_camera := get_node_or_null("RTSCamera")
	if rts_camera == null:
		failures.append("RTS camera node is unavailable")
	else:
		rts_camera.set_process(false)
		_test_camera_input_map(failures)
		_test_camera_pan(rts_camera, failures)
		_test_camera_rotation(rts_camera, failures)
		_test_camera_zoom(rts_camera, failures)
		_test_camera_bounds(rts_camera, failures)
		_test_edge_pan(rts_camera, failures)

	if failures.is_empty():
		print("FOUNDATION_TEST: PASS")
		get_tree().quit(0)
	else:
		for failure in failures:
			push_error(failure)
		get_tree().quit(1)


func _test_camera_pan(rts_camera, failures: Array[String]) -> void:
	rts_camera.edge_pan_margin = -1.0
	var actions := {
		"camera_pan_left": Vector3.LEFT,
		"camera_pan_right": Vector3.RIGHT,
		"camera_pan_forward": Vector3.FORWARD,
		"camera_pan_back": Vector3.BACK,
	}
	for action: String in actions:
		rts_camera.position = Vector3.ZERO
		Input.action_press(action)
		rts_camera._process(1.0)
		Input.action_release(action)
		_assert_vector3(
			rts_camera.position,
			actions[action] * rts_camera.pan_speed,
			"Camera action %s did not pan in the expected direction" % action,
			failures
		)


func _test_camera_input_map(failures: Array[String]) -> void:
	var expected_keys := {
		"camera_pan_left": [KEY_A, KEY_LEFT],
		"camera_pan_right": [KEY_D, KEY_RIGHT],
		"camera_pan_forward": [KEY_W, KEY_UP],
		"camera_pan_back": [KEY_S, KEY_DOWN],
		"camera_rotate_left": [KEY_Q],
		"camera_rotate_right": [KEY_E],
	}
	for action: String in expected_keys:
		var mapped_keys: Array[int] = []
		for event: InputEvent in InputMap.action_get_events(action):
			if event is InputEventKey:
				mapped_keys.append(event.physical_keycode if event.physical_keycode else event.keycode)
		for expected_key: int in expected_keys[action]:
			if expected_key not in mapped_keys:
				failures.append("Camera action %s is missing keycode %s" % [action, expected_key])

	var expected_buttons := {
		"camera_zoom_in": MOUSE_BUTTON_WHEEL_UP,
		"camera_zoom_out": MOUSE_BUTTON_WHEEL_DOWN,
		"camera_rotate_drag": MOUSE_BUTTON_MIDDLE,
	}
	for action: String in expected_buttons:
		var mapped := false
		for event: InputEvent in InputMap.action_get_events(action):
			if event is InputEventMouseButton and event.button_index == expected_buttons[action]:
				mapped = true
		if not mapped:
			failures.append("Camera action %s is missing mouse button %s" % [action, expected_buttons[action]])


func _test_camera_rotation(rts_camera, failures: Array[String]) -> void:
	for action: String in ["camera_rotate_left", "camera_rotate_right"]:
		rts_camera.rotation = Vector3.ZERO
		Input.action_press(action)
		rts_camera._process(1.0)
		Input.action_release(action)
		var expected_sign := 1.0 if action == "camera_rotate_left" else -1.0
		_assert_float(
			signf(rts_camera.rotation.y),
			expected_sign,
			"Camera action %s did not rotate in the expected direction" % action,
			failures
		)

	rts_camera.rotation = Vector3.ZERO
	var drag_start := InputEventAction.new()
	drag_start.action = "camera_rotate_drag"
	drag_start.pressed = true
	rts_camera._unhandled_input(drag_start)
	var drag_motion := InputEventMouseMotion.new()
	drag_motion.relative = Vector2(20.0, 0.0)
	rts_camera._unhandled_input(drag_motion)
	var drag_end := InputEventAction.new()
	drag_end.action = "camera_rotate_drag"
	drag_end.pressed = false
	rts_camera._unhandled_input(drag_end)
	_assert_float(
		rts_camera.rotation.y,
		-20.0 * rts_camera.drag_rotation_sensitivity,
		"Middle-drag rotation did not apply mouse motion",
		failures
	)


func _test_camera_zoom(rts_camera, failures: Array[String]) -> void:
	rts_camera._zoom = rts_camera.min_zoom + rts_camera.zoom_step
	rts_camera._apply_zoom()
	_send_action(rts_camera, "camera_zoom_in")
	_assert_float(rts_camera.camera.position.length(), rts_camera.min_zoom, "Zoom in failed", failures)
	_send_action(rts_camera, "camera_zoom_in")
	_assert_float(
		rts_camera.camera.position.length(),
		rts_camera.min_zoom,
		"Zoom in exceeded the minimum limit",
		failures
	)
	rts_camera._zoom = rts_camera.max_zoom - rts_camera.zoom_step
	rts_camera._apply_zoom()
	_send_action(rts_camera, "camera_zoom_out")
	_assert_float(rts_camera.camera.position.length(), rts_camera.max_zoom, "Zoom out failed", failures)
	_send_action(rts_camera, "camera_zoom_out")
	_assert_float(
		rts_camera.camera.position.length(),
		rts_camera.max_zoom,
		"Zoom out exceeded the maximum limit",
		failures
	)


func _test_camera_bounds(rts_camera, failures: Array[String]) -> void:
	rts_camera.edge_pan_margin = -1.0
	rts_camera.rotation = Vector3.ZERO
	rts_camera.position = Vector3(rts_camera.world_bounds.end.x, 0.0, rts_camera.world_bounds.end.y)
	Input.action_press("camera_pan_right")
	Input.action_press("camera_pan_back")
	rts_camera._process(1.0)
	Input.action_release("camera_pan_right")
	Input.action_release("camera_pan_back")
	_assert_vector3(
		rts_camera.position,
		Vector3(rts_camera.world_bounds.end.x, 0.0, rts_camera.world_bounds.end.y),
		"Camera exceeded positive world bounds",
		failures
	)
	rts_camera.position = Vector3(rts_camera.world_bounds.position.x, 0.0, rts_camera.world_bounds.position.y)
	Input.action_press("camera_pan_left")
	Input.action_press("camera_pan_forward")
	rts_camera._process(1.0)
	Input.action_release("camera_pan_left")
	Input.action_release("camera_pan_forward")
	_assert_vector3(
		rts_camera.position,
		Vector3(rts_camera.world_bounds.position.x, 0.0, rts_camera.world_bounds.position.y),
		"Camera exceeded negative world bounds",
		failures
	)


func _test_edge_pan(rts_camera, failures: Array[String]) -> void:
	rts_camera.edge_pan_margin = 12.0
	var visible_rect := Rect2(100.0, 50.0, 800.0, 600.0)
	var cases := {
		Vector2(101.0, 350.0): Vector2.LEFT,
		Vector2(899.0, 350.0): Vector2.RIGHT,
		Vector2(500.0, 51.0): Vector2.UP,
		Vector2(500.0, 649.0): Vector2.DOWN,
		Vector2(500.0, 350.0): Vector2.ZERO,
		Vector2(99.0, 350.0): Vector2.ZERO,
	}
	for mouse_position: Vector2 in cases:
		var direction: Vector2 = rts_camera._edge_pan_vector_for_position(mouse_position, visible_rect)
		if not direction.is_equal_approx(cases[mouse_position]):
			failures.append(
				"Edge pan at %s expected %s, got %s"
				% [mouse_position, cases[mouse_position], direction]
			)


func _send_action(rts_camera, action: String) -> void:
	var event := InputEventAction.new()
	event.action = action
	event.pressed = true
	rts_camera._unhandled_input(event)


func _assert_float(
	actual: float, expected: float, message: String, failures: Array[String]
) -> void:
	if not is_equal_approx(actual, expected):
		failures.append("%s (expected %.3f, got %.3f)" % [message, expected, actual])


func _assert_vector3(
	actual: Vector3, expected: Vector3, message: String, failures: Array[String]
) -> void:
	if not actual.is_equal_approx(expected):
		failures.append("%s (expected %s, got %s)" % [message, expected, actual])
