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
	if get_node_or_null("RTSCamera") == null:
		failures.append("RTS camera node is unavailable")

	if failures.is_empty():
		print("FOUNDATION_TEST: PASS")
		get_tree().quit(0)
	else:
		for failure in failures:
			push_error(failure)
		get_tree().quit(1)
