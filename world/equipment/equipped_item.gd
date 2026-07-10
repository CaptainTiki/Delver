extends Node3D
class_name EquippedItem

@export var weapon_data : WeaponData

func _ready() -> void:
	var equipped_object : Node3D = weapon_data.glb_mesh.instantiate()
	if equipped_object != null:
		add_child(equipped_object)
