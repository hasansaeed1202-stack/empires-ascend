extends Node

## Minimal economy boundary for Milestone 1. Production and spending behavior are
## intentionally deferred; this stub only owns initialization and read access.

signal resource_changed(resource: StringName, previous_amount: int, amount: int)
signal resources_initialized(resources: Dictionary)

var _resources: Dictionary = {}


func _ready() -> void:
	reset()


func reset() -> void:
	_resources.clear()
	for resource_type: StringName in Constants.RESOURCE_TYPES:
		_resources[resource_type] = Constants.DEFAULT_RESOURCE_AMOUNT
	resources_initialized.emit(snapshot())


func get_amount(resource: StringName) -> int:
	return int(_resources.get(resource, 0))


func snapshot() -> Dictionary:
	return _resources.duplicate(true)
