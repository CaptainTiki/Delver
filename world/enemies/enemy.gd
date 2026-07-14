extends CharacterBody3D
class_name Enemy

const EQUIPPED_ITEM_PREFAB := preload("uid://dcdd2kn8n007y")

@onready var physical_bone_torso: PhysicalBone3D = %"Physical Bone Torso"

func impale(thrown_item: ThrownItem, basis : Basis) -> void:
	var impaled_item := EQUIPPED_ITEM_PREFAB.instantiate() as EquippedItem
	impaled_item.weapon_data = thrown_item.weapon_data
	physical_bone_torso.add_child(impaled_item)
	impaled_item.global_transform.basis = basis
	impaled_item.translate_object_local(thrown_item.weapon_data.impale_local_translation)
	impaled_item.rotate_object_local(Vector3.UP, thrown_item.weapon_data.impale_local_rotation)
	thrown_item.queue_free()
