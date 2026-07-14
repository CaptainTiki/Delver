extends RigidBody3D
class_name ThrownItem

const PICKABLE_ITEM_PREFAB := preload("uid://bosbcx0tmdb2c")

@export var weapon_data : WeaponData

@onready var collision_shape: CollisionShape3D = %CollisionShape3D

var original_basis : Basis = Basis.IDENTITY

func _ready() -> void:
	var thrown_object : Node3D = null
	original_basis = global_transform.basis
	if weapon_data:
		thrown_object = weapon_data.glb_mesh.instantiate()
		if thrown_object != null:
			add_child(thrown_object)
			var mesh_node := thrown_object.get_child(0) as MeshInstance3D
			collision_shape.shape = mesh_node.mesh.create_convex_shape()
			gravity_scale = 0.1
			linear_velocity = -global_basis.z * weapon_data.throw_movement_speed
			angular_velocity = -global_basis.y * weapon_data.throw_rotation_speed
			body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node) -> void:
	if body is Enemy:
		body.impale(self, global_basis)
	else:
		gravity_scale = 1


func _on_sleeping_state_changed() -> void:
	var pickable_item := PICKABLE_ITEM_PREFAB.instantiate()
	pickable_item.weapon_data = weapon_data
	pickable_item.global_transform = global_transform
	GameState.current_level.add_child(pickable_item)
	queue_free()
