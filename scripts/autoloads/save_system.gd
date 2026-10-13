extends Node

## Serialization contract only. Disk slots and full world persistence belong to a
## later milestone.

const SAVE_VERSION := 1


func serialize_state(state: Dictionary) -> String:
	var envelope := {
		"version": SAVE_VERSION,
		"state": state,
	}
	return JSON.stringify(envelope)


func deserialize_state(serialized_state: String) -> Dictionary:
	var parsed: Variant = JSON.parse_string(serialized_state)
	if not parsed is Dictionary:
		push_error("Save data must be a JSON object.")
		return {}
	var envelope: Dictionary = parsed
	if int(envelope.get("version", -1)) != SAVE_VERSION:
		push_error("Unsupported save version.")
		return {}
	var state: Variant = envelope.get("state", {})
	return state if state is Dictionary else {}
