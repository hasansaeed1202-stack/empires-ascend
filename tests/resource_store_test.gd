extends Node

var _resource_events: Array[Array] = []
var _batch_events: Array[Array] = []


func _ready() -> void:
	var failures: Array[String] = []
	ResourceStore.resource_changed.connect(_on_resource_changed)
	ResourceStore.resources_changed.connect(_on_resources_changed)
	ResourceStore.reset()

	_test_definitions_and_initial_balances(failures)
	_test_independent_namespaces(failures)
	_test_clamping_and_rounding(failures)
	_test_atomic_transactions(failures)
	_test_signal_payloads(failures)
	_test_read_only_snapshot(failures)

	if failures.is_empty():
		print("RESOURCE_STORE_TEST: PASS")
		get_tree().quit(0)
	else:
		for failure: String in failures:
			push_error(failure)
		get_tree().quit(1)


func _test_definitions_and_initial_balances(failures: Array[String]) -> void:
	_assert_equal(ResourceStore.get_definitions().size(), 6, "Six definitions were not loaded", failures)
	var expected := {
		&"provisions": 350,
		&"materials": 300,
		&"craftsmanship": 30,
		&"knowledge": 0,
		&"influence": 25,
		&"logistics": 20,
	}
	_assert_equal(ResourceStore.snapshot(), expected, "Player starting balances are incorrect", failures)
	for resource: StringName in Constants.RESOURCE_TYPES:
		_assert_equal(
			ResourceStore.get_amount(resource, ResourceStore.AI),
			0,
			"AI %s did not initialize independently" % resource,
			failures
		)


func _test_independent_namespaces(failures: Array[String]) -> void:
	ResourceStore.set_amount(&"materials", 125, ResourceStore.AI)
	_assert_equal(ResourceStore.get_amount(&"materials", ResourceStore.AI), 125, "AI write failed", failures)
	_assert_equal(ResourceStore.get_amount(&"materials"), 300, "AI write changed player balance", failures)


func _test_clamping_and_rounding(failures: Array[String]) -> void:
	_assert_equal(ResourceStore.set_amount(&"knowledge", -10), 0, "Negative value was not clamped", failures)
	_assert_equal(ResourceStore.set_amount(&"knowledge", 2500), 2000, "Cap was not enforced", failures)
	_assert_equal(ResourceStore.set_amount(&"knowledge", 10.6), 11, "Set did not round", failures)
	_assert_equal(ResourceStore.add(&"knowledge", 1.6), 13, "Add did not round", failures)
	_assert_equal(ResourceStore.subtract(&"knowledge", 2.7), 10, "Subtract did not round", failures)


func _test_atomic_transactions(failures: Array[String]) -> void:
	ResourceStore.set_amount(&"provisions", 100)
	ResourceStore.set_amount(&"materials", 50)
	var before := ResourceStore.snapshot()
	_assert_equal(
		ResourceStore.try_consume({&"provisions": 20.2, &"materials": 60}),
		false,
		"Unaffordable transaction succeeded",
		failures
	)
	_assert_equal(ResourceStore.snapshot(), before, "Failed transaction changed a balance", failures)
	_assert_equal(
		ResourceStore.try_consume({&"provisions": 20.2, &"materials": 10}),
		true,
		"Affordable transaction failed",
		failures
	)
	_assert_equal(ResourceStore.get_amount(&"provisions"), 80, "Atomic consume rounded incorrectly", failures)
	_assert_equal(ResourceStore.get_amount(&"materials"), 40, "Atomic consume deducted incorrectly", failures)
	before = ResourceStore.snapshot()
	_assert_equal(
		ResourceStore.try_transaction({&"materials": -5, &"knowledge": 2500}),
		false,
		"Over-cap transaction succeeded",
		failures
	)
	_assert_equal(ResourceStore.snapshot(), before, "Over-cap transaction partially applied", failures)
	_assert_equal(
		ResourceStore.try_consume({&"provisions": -1}),
		false,
		"Negative cost was accepted",
		failures
	)


func _test_signal_payloads(failures: Array[String]) -> void:
	_resource_events.clear()
	_batch_events.clear()
	ResourceStore.set_amount(&"influence", 40, ResourceStore.AI)
	_assert_equal(_resource_events.size(), 1, "Expected one resource_changed signal", failures)
	_assert_equal(_batch_events.size(), 1, "Expected one resources_changed signal", failures)
	if not _resource_events.is_empty():
		_assert_equal(
			_resource_events[0],
			[ResourceStore.AI, &"influence", 0, 40],
			"resource_changed payload is incorrect",
			failures
		)
	if not _batch_events.is_empty():
		var event := _batch_events[0]
		_assert_equal(event[0], ResourceStore.AI, "resources_changed entity is incorrect", failures)
		_assert_equal(event[1][&"influence"], 0, "resources_changed old snapshot is incorrect", failures)
		_assert_equal(event[2][&"influence"], 40, "resources_changed new snapshot is incorrect", failures)


func _test_read_only_snapshot(failures: Array[String]) -> void:
	var hud_snapshot := ResourceStore.snapshot()
	hud_snapshot[&"logistics"] = 999
	_assert_equal(ResourceStore.get_amount(&"logistics"), 20, "Snapshot exposed mutable storage", failures)


func _on_resource_changed(
	entity: StringName, resource: StringName, previous_amount: int, amount: int
) -> void:
	_resource_events.append([entity, resource, previous_amount, amount])


func _on_resources_changed(
	entity: StringName, previous_amounts: Dictionary, amounts: Dictionary
) -> void:
	_batch_events.append([entity, previous_amounts, amounts])


func _assert_equal(actual: Variant, expected: Variant, message: String, failures: Array[String]) -> void:
	if actual != expected:
		failures.append("%s (expected %s, got %s)" % [message, expected, actual])
