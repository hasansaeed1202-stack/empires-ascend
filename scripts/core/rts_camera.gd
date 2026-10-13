class_name RTSCamera
extends Node3D

## Lightweight keyboard, edge-pan, wheel-zoom, and middle-drag rotation camera.

@export var pan_speed := 16.0
@export var edge_pan_margin := 12.0
@export var rotation_speed := 1.5
@export var drag_rotation_sensitivity := 0.005
@export var zoom_step := 2.0
@export var min_zoom := 8.0
@export var max_zoom := 32.0
@export var world_bounds := Rect2(-48.0, -48.0, 96.0, 96.0)

@onready var camera: Camera3D = $Camera3D

var _zoom := 18.0
var _dragging_rotation := false


func _ready() -> void:
	_zoom = clampf(camera.position.length(), min_zoom, max_zoom)
	_apply_zoom()


func _process(delta: float) -> void:
	var input_vector := Input.get_vector(
		"camera_pan_left", "camera_pan_right", "camera_pan_forward", "camera_pan_back"
	)
	input_vector += _edge_pan_vector()
	if input_vector.length_squared() > 1.0:
		input_vector = input_vector.normalized()

	var movement := Vector3(input_vector.x, 0.0, input_vector.y)
	movement = movement.rotated(Vector3.UP, rotation.y)
	position += movement * pan_speed * delta
	position.x = clampf(position.x, world_bounds.position.x, world_bounds.end.x)
	position.z = clampf(position.z, world_bounds.position.y, world_bounds.end.y)

	var rotation_input := Input.get_axis("camera_rotate_left", "camera_rotate_right")
	rotate_y(-rotation_input * rotation_speed * delta)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("camera_zoom_in"):
		_zoom = clampf(_zoom - zoom_step, min_zoom, max_zoom)
		_apply_zoom()
	elif event.is_action_pressed("camera_zoom_out"):
		_zoom = clampf(_zoom + zoom_step, min_zoom, max_zoom)
		_apply_zoom()
	elif event.is_action_pressed("camera_rotate_drag"):
		_dragging_rotation = true
	elif event.is_action_released("camera_rotate_drag"):
		_dragging_rotation = false
	elif event is InputEventMouseMotion and _dragging_rotation:
		rotate_y(-event.relative.x * drag_rotation_sensitivity)


func _edge_pan_vector() -> Vector2:
	var visible_rect := get_viewport().get_visible_rect()
	return _edge_pan_vector_for_position(get_viewport().get_mouse_position(), visible_rect)


func _edge_pan_vector_for_position(mouse_position: Vector2, visible_rect: Rect2) -> Vector2:
	if not visible_rect.has_point(mouse_position):
		return Vector2.ZERO
	var direction := Vector2.ZERO
	if mouse_position.x <= visible_rect.position.x + edge_pan_margin:
		direction.x -= 1.0
	elif mouse_position.x >= visible_rect.end.x - edge_pan_margin:
		direction.x += 1.0
	if mouse_position.y <= visible_rect.position.y + edge_pan_margin:
		direction.y -= 1.0
	elif mouse_position.y >= visible_rect.end.y - edge_pan_margin:
		direction.y += 1.0
	return direction


func _apply_zoom() -> void:
	var direction := camera.position.normalized()
	if direction.is_zero_approx():
		direction = Vector3(0.0, 0.7, 0.7).normalized()
	camera.position = direction * _zoom
