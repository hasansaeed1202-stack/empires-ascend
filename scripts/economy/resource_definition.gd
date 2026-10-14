class_name ResourceDefinition
extends Resource

## Data-only definition for one economy resource.

@export var id: StringName
@export var display_name: String
@export_range(0, 2000, 1) var starting_amount: int = 0
