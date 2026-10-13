extends Node

var failures: Array[String] = []


func _ready() -> void:
	var demo_scene: PackedScene = load("res://scenes/main/main.tscn")
	var demo: Node = demo_scene.instantiate()
	add_child(demo)
	await get_tree().process_frame
	_check(demo.entities.size() == 12, "one player TC, enemy TC, six villagers, four defenders")
	_check(demo._player_population() == 6, "starts with exactly six villagers")
	_check(demo.population_cap == 10, "starts with population capacity")
	var before := ResourceStore.get_amount(&"materials")
	_check(demo.place_building(&"house", Vector3(-20, 1.25, 20)), "house placement succeeds")
	_check(ResourceStore.get_amount(&"materials") == before - 50, "building cost is atomic")
	_check(demo.population_cap == 15, "house raises population cap")
	_check(demo.place_building(&"farm", Vector3(-15, 1.25, 20)), "farm placement succeeds")
	var farm: Node3D = demo.entities[-1]
	demo.selected.clear()
	demo.selected.append(demo.entities[1])
	demo.selected.append(demo.entities[2])
	_check(demo.assign_selected_to(farm) == 2, "villagers assign to farm")
	var provisions := ResourceStore.get_amount(&"provisions")
	demo._gather_tick()
	_check(ResourceStore.get_amount(&"provisions") == provisions + 6, "assignment gather tick credits resources")
	_check(demo.place_building(&"barracks", Vector3(-10, 1.25, 20)), "barracks placement succeeds")
	var population: int = demo._player_population()
	_check(demo.train_soldier(), "barracks trains soldier")
	_check(demo._player_population() == population + 1, "training adds one soldier")
	var enemy_tc := _find(demo, &"town_center", &"enemy")
	demo.damage_entity(enemy_tc, 500)
	demo._check_end_state()
	_check(demo.match_over, "destroying enemy Town Center ends match")
	demo.queue_free()
	await get_tree().process_frame
	var defeat_demo: Node = demo_scene.instantiate()
	add_child(defeat_demo)
	await get_tree().process_frame
	ResourceStore.set_amount(&"materials", 0)
	var entity_count: int = defeat_demo.entities.size()
	_check(not defeat_demo.place_building(&"house", Vector3.ZERO), "unaffordable building is rejected")
	_check(defeat_demo.entities.size() == entity_count, "failed building creates nothing")
	var player_tc := _find(defeat_demo, &"town_center", &"player")
	defeat_demo.damage_entity(player_tc, 500)
	defeat_demo._check_end_state()
	_check(defeat_demo.match_over, "destroying player Town Center ends match")
	if failures.is_empty():
		print("DEMO_TEST: PASS")
		get_tree().quit(0)
	else:
		for failure in failures: push_error(failure)
		print("DEMO_TEST: FAIL (%d)" % failures.size())
		get_tree().quit(1)


func _find(demo: Node, kind: StringName, team: StringName) -> Node3D:
	for entity in demo.entities:
		if entity.get_meta("kind") == kind and entity.get_meta("team") == team:
			return entity
	return null


func _check(condition: bool, message: String) -> void:
	if not condition: failures.append(message)
