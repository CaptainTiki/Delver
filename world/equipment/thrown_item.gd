extends RigidBody3D
class_name ThrownItem

const PICKABLE_ITEM_PREFAB := preload("uid://bosbcx0tmdb2c")

@export var weapon_data : WeaponData

@onready var collision_shape: CollisionShape3D = %CollisionShape3D


var mesh_node : MeshInstance3D
var thrown_direction : Vector3 = Vector3.ZERO

func _ready() -> void:
	var thrown_object : Node3D = null
	if weapon_data:
		thrown_object = weapon_data.glb_mesh.instantiate()
		if thrown_object != null:
			add_child(thrown_object)
			mesh_node = thrown_object.get_child(0) as MeshInstance3D
			collision_shape.shape = mesh_node.mesh.create_convex_shape()


func _on_body_entered(_body: Node) -> void:
	pass


func _on_sleeping_state_changed() -> void:
	var pickable_item := PICKABLE_ITEM_PREFAB.instantiate()
	pickable_item.weapon_data = weapon_data
	pickable_item.global_transform = global_transform
	get_parent().add_child(pickable_item)
	queue_free()
