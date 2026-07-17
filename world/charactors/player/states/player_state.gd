extends Node
class_name PlayerState

signal transition_requested(new_state: Player.State)

var player : Player

func _init(source_player: Player) -> void:
	player = source_player

func transition_state(new_state: Player.State) -> void:
	transition_requested.emit(new_state)
