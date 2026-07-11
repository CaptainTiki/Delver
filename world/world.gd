extends Node3D
class_name World

const LEVELS := [
	preload("uid://2346alrvcbvu") #level 1 welcome
	]

var current_level_index := 0
var current_loaded_level : BaseLevel = null

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	load_level(current_level_index)

func load_level(index: int) -> void:
	if current_loaded_level:
		current_loaded_level.queue_free()
	if LEVELS.size() > index:
		current_loaded_level = LEVELS[index].instantiate()
		add_child(current_loaded_level)
		GameState.register_level(current_loaded_level)
