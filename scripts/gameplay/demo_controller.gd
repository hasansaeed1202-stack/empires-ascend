class_name DemoController
extends Node3D

## Small, deterministic RTS vertical slice built from engine primitives.

const PLAYER := &"player"
const ENEMY := &"enemy"
const UNIT_LIMIT := 24
const BUILD_COSTS := {
	&"house": {&"materials": 50},
	&"farm": {&"materials": 30},
	&"resource_camp": {&"materials": 40, &"craftsmanship": 5},
	&"barracks": {&"materials": 100, &"craftsmanship": 10},
}
const SOLDIER_COST := {&"provisions": 50, &"logistics": 5}
const RESOURCE_LABELS := {
	&"provisions": "P", &"materials": "M", &"craftsmanship": "C",
	&"knowledge": "K", &"influence": "I", &"logistics": "L",
}

var entities: Array[Node3D] = []
var selected: Array[Node3D] = []
var build_mode: StringName = &""
var population_cap := 10
var gather_elapsed := 0.0
var match_over := false
var status_label: Label
var resources_label: Label
var selection_label: Label
var train_button: Button
var barracks_count := 0


func _ready() -> void:
	ResourceStore.reset()
	_build_arena()
	_build_hud()
	_spawn_starting_forces()
	ResourceStore.resources_changed.connect(_on_resources_changed)
	_update_hud()


func _process(delta: float) -> void:
	if match_over:
		return
	gather_elapsed += delta
	if gather_elapsed >= 1.0:
		gather_elapsed -= 1.0
		_gather_tick()
	_update_units(delta)
	_check_end_state()


func _unhandled_input(event: InputEvent) -> void:
	if match_over:
		return
	if event.is_action_pressed("selection_primary"):
		_handle_primary_click(event.position)
	elif event.is_action_pressed("command_move"):
		_handle_command_click(event.position)


func request_build(kind: StringName) -> bool:
	if match_over or not BUILD_COSTS.has(kind):
		return false
	build_mode = kind
	status_label.text = "Place %s on open ground (left click)" % _pretty(kind)
	return true


func place_building(kind: StringName, position_3d: Vector3) -> bool:
	if match_over or not BUILD_COSTS.has(kind):
		return false
	if not ResourceStore.try_consume(BUILD_COSTS[kind]):
		status_label.text = "Not enough resources for %s" % _pretty(kind)
		return false
	_spawn_building(kind, PLAYER, position_3d)
	if kind == &"house":
		population_cap += 5
	elif kind == &"barracks":
		barracks_count += 1
	build_mode = &""
	status_label.text = "%s completed" % _pretty(kind)
	_update_hud()
	return true


func train_soldier() -> bool:
	if match_over or barracks_count < 1:
		status_label.text = "Build a barracks first"
		return false
	if _player_population() >= population_cap or entities.size() >= UNIT_LIMIT:
		status_label.text = "Population cap reached"
		return false
	if not ResourceStore.try_consume(SOLDIER_COST):
		status_label.text = "Not enough resources to train a soldier"
		return false
	_spawn_unit(&"soldier", PLAYER, Vector3(-28 + barracks_count * 2, 0.8, 24))
	status_label.text = "Soldier trained"
	_update_hud()
	return true


func assign_selected_to(building: Node3D) -> int:
	if not is_instance_valid(building) or building.get_meta("team") != PLAYER:
		return 0
	var kind: StringName = building.get_meta("kind")
	var resource: StringName = &""
	if kind == &"farm":
		resource = &"provisions"
	elif kind == &"resource_camp":
		resource = &"materials"
	else:
		return 0
	var count := 0
	for unit in selected:
		if is_instance_valid(unit) and unit.get_meta("kind") == &"villager":
			unit.set_meta("gather_resource", resource)
			unit.set_meta("destination", building.position + Vector3(count % 3 - 1, 0.0, 3))
			count += 1
	status_label.text = "%d villager(s) assigned to %s" % [count, _pretty(kind)]
	return count


func damage_entity(entity: Node3D, amount: int) -> void:
	if not is_instance_valid(entity) or bool(entity.get_meta("dead", false)):
		return
	var health := int(entity.get_meta("health")) - amount
	entity.set_meta("health", health)
	if health <= 0:
		entity.set_meta("dead", true)
		if entity.get_meta("kind") == &"barracks" and entity.get_meta("team") == PLAYER:
			barracks_count = maxi(0, barracks_count - 1)
		selected.erase(entity)
		entities.erase(entity)
		entity.queue_free()
		_update_hud()


func _build_arena() -> void:
	for data in [
		[Vector3(-38, 0.8, -12), Color(0.12, 0.36, 0.10), "tree"],
		[Vector3(-32, 0.8, 3), Color(0.12, 0.36, 0.10), "tree"],
		[Vector3(34, 0.8, 12), Color(0.12, 0.36, 0.10), "tree"],
		[Vector3(27, 0.8, -7), Color(0.45, 0.45, 0.48), "rock"],
		[Vector3(4, 0.8, 30), Color(0.45, 0.45, 0.48), "rock"],
		[Vector3(-4, 0.8, -31), Color(0.45, 0.45, 0.48), "rock"],
	]:
		var mesh := MeshInstance3D.new()
		mesh.position = data[0]
		mesh.mesh = _box_mesh(Vector3(2.0, 2.8 if data[2] == "tree" else 1.6, 2.0), data[1])
		add_child(mesh)


func _build_hud() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var panel := PanelContainer.new()
	panel.position = Vector2(12, 12)
	panel.custom_minimum_size = Vector2(510, 150)
	layer.add_child(panel)
	var box := VBoxContainer.new()
	panel.add_child(box)
	resources_label = Label.new()
	box.add_child(resources_label)
	selection_label = Label.new()
	box.add_child(selection_label)
	var buttons := HBoxContainer.new()
	box.add_child(buttons)
	for kind: StringName in [&"house", &"farm", &"resource_camp", &"barracks"]:
		var button := Button.new()
		button.text = _pretty(kind)
		button.pressed.connect(request_build.bind(kind))
		buttons.add_child(button)
	train_button = Button.new()
	train_button.text = "Train Soldier"
	train_button.pressed.connect(train_soldier)
	buttons.add_child(train_button)
	status_label = Label.new()
	status_label.text = "Select units with left click; right click to move or attack."
	box.add_child(status_label)
	var actions := HBoxContainer.new()
	box.add_child(actions)
	var restart := Button.new()
	restart.text = "Restart"
	restart.pressed.connect(func() -> void: get_tree().reload_current_scene())
	actions.add_child(restart)
	var exit := Button.new()
	exit.text = "Exit"
	exit.pressed.connect(func() -> void: get_tree().quit())
	actions.add_child(exit)


func _spawn_starting_forces() -> void:
	_spawn_building(&"town_center", PLAYER, Vector3(-32, 1.5, 28))
	for i in 6:
		_spawn_unit(&"villager", PLAYER, Vector3(-27 + (i % 3) * 2, 0.8, 24 + (i / 3) * 2))
	_spawn_building(&"town_center", ENEMY, Vector3(32, 1.5, -28))
	for i in 4:
		_spawn_unit(&"soldier", ENEMY, Vector3(26 + (i % 2) * 3, 0.8, -24 + (i / 2) * 3))


func _spawn_unit(kind: StringName, team: StringName, at: Vector3) -> Node3D:
	var body := CharacterBody3D.new()
	body.name = "%s_%s" % [team, kind]
	body.position = at
	body.collision_layer = 1
	body.collision_mask = 0
	body.set_meta("kind", kind)
	body.set_meta("team", team)
	body.set_meta("health", 65 if kind == &"villager" else 110)
	body.set_meta("dead", false)
	body.set_meta("destination", at)
	body.set_meta("target", null)
	body.set_meta("cooldown", 0.0)
	body.set_meta("gather_resource", &"")
	var shape := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.55
	capsule.height = 1.6
	shape.shape = capsule
	body.add_child(shape)
	var mesh := MeshInstance3D.new()
	mesh.mesh = _capsule_mesh(Color(0.20, 0.52, 0.95) if team == PLAYER else Color(0.82, 0.20, 0.16))
	body.add_child(mesh)
	add_child(body)
	entities.append(body)
	return body


func _spawn_building(kind: StringName, team: StringName, at: Vector3) -> Node3D:
	var body := StaticBody3D.new()
	body.name = "%s_%s" % [team, kind]
	body.position = at
	body.collision_layer = 2
	body.collision_mask = 0
	body.set_meta("kind", kind)
	body.set_meta("team", team)
	body.set_meta("health", 500 if kind == &"town_center" else 220)
	body.set_meta("dead", false)
	var size := Vector3(7, 3, 7) if kind == &"town_center" else Vector3(4, 2.5, 4)
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	shape.shape = box
	body.add_child(shape)
	var mesh := MeshInstance3D.new()
	var color := Color(0.38, 0.55, 0.78) if team == PLAYER else Color(0.62, 0.25, 0.20)
	if kind == &"farm": color = Color(0.74, 0.62, 0.22)
	if kind == &"resource_camp": color = Color(0.48, 0.35, 0.18)
	mesh.mesh = _box_mesh(size, color)
	body.add_child(mesh)
	add_child(body)
	entities.append(body)
	return body


func _handle_primary_click(screen_position: Vector2) -> void:
	var hit := _raycast(screen_position)
	if hit.is_empty():
		selected.clear()
		_update_hud()
		return
	var collider: Node3D = hit.collider
	if not build_mode.is_empty() and collider.name == "Terrain":
		place_building(build_mode, hit.position + Vector3.UP * 1.25)
		return
	if collider.has_meta("team") and collider.get_meta("team") == PLAYER:
		if collider.get_meta("kind") in [&"farm", &"resource_camp"] and not selected.is_empty():
			if assign_selected_to(collider) > 0:
				return
		selected = [collider]
	else:
		selected.clear()
	_update_hud()


func _handle_command_click(screen_position: Vector2) -> void:
	var hit := _raycast(screen_position)
	if hit.is_empty(): return
	var collider: Node3D = hit.collider
	for unit in selected:
		if not is_instance_valid(unit) or not unit is CharacterBody3D: continue
		unit.set_meta("gather_resource", &"")
		if collider.has_meta("team") and collider.get_meta("team") != PLAYER:
			unit.set_meta("target", collider)
		else:
			unit.set_meta("target", null)
			unit.set_meta("destination", hit.position)


func _raycast(screen_position: Vector2) -> Dictionary:
	var camera := get_viewport().get_camera_3d()
	var from := camera.project_ray_origin(screen_position)
	var query := PhysicsRayQueryParameters3D.create(from, from + camera.project_ray_normal(screen_position) * 200.0)
	query.collide_with_areas = false
	return get_world_3d().direct_space_state.intersect_ray(query)


func _update_units(delta: float) -> void:
	for entity in entities.duplicate():
		if not is_instance_valid(entity) or not entity is CharacterBody3D: continue
		var cooldown := maxf(0.0, float(entity.get_meta("cooldown")) - delta)
		entity.set_meta("cooldown", cooldown)
		var target: Variant = entity.get_meta("target") if entity.has_meta("target") else null
		if entity.get_meta("team") == ENEMY and (target == null or not is_instance_valid(target)):
			target = _nearest_enemy(entity, 12.0)
			entity.set_meta("target", target)
		if target != null and is_instance_valid(target):
			var target_node: Node3D = target
			var distance: float = entity.position.distance_to(target_node.position)
			if distance <= 2.3:
				if cooldown <= 0.0:
					damage_entity(target_node, 16 if entity.get_meta("kind") == &"soldier" else 5)
					entity.set_meta("cooldown", 0.8)
			else:
				_move_unit(entity, target_node.position, delta)
		else:
			_move_unit(entity, entity.get_meta("destination"), delta)


func _move_unit(unit: CharacterBody3D, destination: Vector3, delta: float) -> void:
	var flat := destination - unit.position
	flat.y = 0.0
	if flat.length() < 0.2:
		unit.velocity = Vector3.ZERO
		return
	unit.velocity = flat.normalized() * 5.0
	unit.move_and_slide()
	unit.position.x = clampf(unit.position.x, -48.0, 48.0)
	unit.position.z = clampf(unit.position.z, -48.0, 48.0)


func _nearest_enemy(source: Node3D, radius: float) -> Node3D:
	var best: Node3D
	var best_distance := radius
	for candidate in entities:
		if not is_instance_valid(candidate) or candidate.get_meta("team") == source.get_meta("team"): continue
		var distance := source.position.distance_to(candidate.position)
		if distance < best_distance:
			best = candidate
			best_distance = distance
	return best


func _gather_tick() -> void:
	var gains: Dictionary = {}
	for entity in entities:
		if not is_instance_valid(entity) or entity.get_meta("team") != PLAYER: continue
		var resource: StringName = entity.get_meta("gather_resource", &"")
		if not resource.is_empty(): gains[resource] = int(gains.get(resource, 0)) + 3
	if not gains.is_empty():
		ResourceStore.try_transaction(gains)


func _check_end_state() -> void:
	var player_tc := false
	var enemy_tc := false
	var player_units := 0
	for entity in entities:
		if not is_instance_valid(entity): continue
		if entity.get_meta("kind") == &"town_center":
			if entity.get_meta("team") == PLAYER: player_tc = true
			else: enemy_tc = true
		elif entity.get_meta("team") == PLAYER:
			player_units += 1
	if not enemy_tc: _finish_match("VICTORY — enemy Town Center destroyed")
	elif not player_tc or (player_units == 0 and barracks_count == 0): _finish_match("DEFEAT — your settlement has fallen")


func _finish_match(message: String) -> void:
	match_over = true
	selected.clear()
	status_label.text = message + ". Restart or Exit."
	_update_hud()


func _player_population() -> int:
	var count := 0
	for entity in entities:
		if is_instance_valid(entity) and entity is CharacterBody3D and entity.get_meta("team") == PLAYER:
			count += 1
	return count


func _update_hud() -> void:
	if resources_label == null: return
	var snapshot := ResourceStore.snapshot()
	var parts: Array[String] = []
	for resource: StringName in Constants.RESOURCE_TYPES:
		parts.append("%s %d" % [RESOURCE_LABELS[resource], snapshot[resource]])
	resources_label.text = "Resources: " + "   ".join(parts) + "   |   Pop %d/%d" % [_player_population(), population_cap]
	selection_label.text = "Selected: %s" % ("none" if selected.is_empty() else _pretty(selected[0].get_meta("kind")))
	train_button.disabled = barracks_count < 1 or match_over


func _on_resources_changed(_entity: StringName, _previous: Dictionary, _amounts: Dictionary) -> void:
	_update_hud()


func _pretty(value: StringName) -> String:
	return String(value).replace("_", " ").capitalize()


func _box_mesh(size: Vector3, color: Color) -> BoxMesh:
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh.material = _material(color)
	return mesh


func _capsule_mesh(color: Color) -> CapsuleMesh:
	var mesh := CapsuleMesh.new()
	mesh.radius = 0.55
	mesh.height = 1.6
	mesh.material = _material(color)
	return mesh


func _material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.9
	return material
