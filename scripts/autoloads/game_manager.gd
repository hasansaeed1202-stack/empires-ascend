extends Node

## Owns high-level runtime state and future scene/save orchestration.

signal state_changed(previous_state: GameState, state: GameState)

enum GameState {
	BOOTING,
	RUNNING,
	PAUSED,
}

var state: GameState = GameState.BOOTING


func _ready() -> void:
	set_state(GameState.RUNNING)


func set_state(next_state: GameState) -> void:
	if next_state == state:
		return
	var previous_state := state
	state = next_state
	get_tree().paused = state == GameState.PAUSED
	state_changed.emit(previous_state, state)


func request_save_snapshot() -> Dictionary:
	return {
		"resources": ResourceStore.snapshot(),
		"game_state": state,
	}
