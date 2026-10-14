extends Node

## Owns capped integer resource balances for isolated player and AI namespaces.

signal resource_changed(
	entity: StringName, resource: StringName, previous_amount: int, amount: int
)
signal resources_changed(entity: StringName, previous_amounts: Dictionary, amounts: Dictionary)
signal resources_initialized(resources: Dictionary)

const PLAYER: StringName = &"player"
const AI: StringName = &"ai"
const RESOURCE_DEFINITION_PATHS: Array[String] = [
	"res://resources/economy/provisions.tres",
	"res://resources/economy/materials.tres",
	"res://resources/economy/craftsmanship.tres",
	"res://resources/economy/knowledge.tres",
	"res://resources/economy/influence.tres",
	"res://resources/economy/logistics.tres",
]

var _definitions: Dictionary = {}
var _inventories: Dictionary = {}


func _ready() -> void:
	reset()


func reset() -> void:
	_load_definitions()
	_inventories.clear()
	_initialize_inventory(PLAYER, true)
	_initialize_inventory(AI, false)
	resources_initialized.emit(all_snapshots())


func add(resource: StringName, amount: float, entity: StringName = PLAYER) -> int:
	return set_amount(resource, get_amount(resource, entity) + roundi(amount), entity)


func subtract(resource: StringName, amount: float, entity: StringName = PLAYER) -> int:
	return set_amount(resource, get_amount(resource, entity) - roundi(amount), entity)


func get_amount(resource: StringName, entity: StringName = PLAYER) -> int:
	_ensure_inventory(entity)
	return int(_inventories[entity].get(resource, 0))


func set_amount(resource: StringName, amount: float, entity: StringName = PLAYER) -> int:
	if not _definitions.has(resource):
		push_warning("Unknown resource: %s" % resource)
		return 0
	_ensure_inventory(entity)
	var previous_amount := get_amount(resource, entity)
	var next_amount := clampi(roundi(amount), 0, Constants.MAX_RESOURCE_AMOUNT)
	if previous_amount == next_amount:
		return next_amount
	var previous_snapshot := snapshot(entity)
	_inventories[entity][resource] = next_amount
	resource_changed.emit(entity, resource, previous_amount, next_amount)
	resources_changed.emit(entity, previous_snapshot, snapshot(entity))
	return next_amount


func try_consume(costs: Dictionary, entity: StringName = PLAYER) -> bool:
	var changes: Dictionary = {}
	for resource: Variant in costs:
		var cost := roundi(float(costs[resource]))
		if cost < 0:
			return false
		changes[resource] = -cost
	return try_transaction(changes, entity)


## Applies every signed delta or none. Values are rounded before validation.
func try_transaction(changes: Dictionary, entity: StringName = PLAYER) -> bool:
	_ensure_inventory(entity)
	var next_amounts := snapshot(entity)
	for resource: Variant in changes:
		if not resource is StringName and not resource is String:
			return false
		var resource_name := StringName(resource)
		if not _definitions.has(resource_name):
			return false
		var next_amount := int(next_amounts[resource_name]) + roundi(float(changes[resource]))
		if next_amount < 0 or next_amount > Constants.MAX_RESOURCE_AMOUNT:
			return false
		next_amounts[resource_name] = next_amount

	var previous_snapshot := snapshot(entity)
	if previous_snapshot == next_amounts:
		return true
	_inventories[entity] = next_amounts
	for resource: StringName in Constants.RESOURCE_TYPES:
		var previous_amount := int(previous_snapshot[resource])
		var next_amount := int(next_amounts[resource])
		if previous_amount != next_amount:
			resource_changed.emit(entity, resource, previous_amount, next_amount)
	resources_changed.emit(entity, previous_snapshot, snapshot(entity))
	return true


## Read-only consumer contract: callers receive a deep copy, never live storage.
func snapshot(entity: StringName = PLAYER) -> Dictionary:
	_ensure_inventory(entity)
	return _inventories[entity].duplicate(true)


func all_snapshots() -> Dictionary:
	var result: Dictionary = {}
	for entity: StringName in _inventories:
		result[entity] = snapshot(entity)
	return result


func get_definitions() -> Dictionary:
	return _definitions.duplicate()


func _load_definitions() -> void:
	_definitions.clear()
	for path: String in RESOURCE_DEFINITION_PATHS:
		var definition: ResourceDefinition = load(path)
		if definition == null:
			push_error("Unable to load resource definition: %s" % path)
			continue
		_definitions[definition.id] = definition


func _ensure_inventory(entity: StringName) -> void:
	if not _inventories.has(entity):
		_initialize_inventory(entity, false)


func _initialize_inventory(entity: StringName, use_starting_amounts: bool) -> void:
	var inventory: Dictionary = {}
	for resource: StringName in Constants.RESOURCE_TYPES:
		var definition: ResourceDefinition = _definitions.get(resource)
		inventory[resource] = definition.starting_amount if use_starting_amounts else 0
	_inventories[entity] = inventory
