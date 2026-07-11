extends Node3D
class_name BaseLevel

@onready var player_spawn: Node3D = $PlayerSpawn

const PLAYER_PREFAB : PackedScene = preload("uid://dvndpmyv0sgqq")

func _ready() -> void:
	var player: Player = PLAYER_PREFAB.instantiate()
	player.global_transform = player_spawn.global_transform
	add_child(player)
