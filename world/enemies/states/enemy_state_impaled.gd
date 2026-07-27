extends EnemyState
class_name EnemyStateImpaled

const EQUIPPED_ITEM_PREFAB := preload("uid://dcdd2kn8n007y")
const IMPALE_INTENSITY : float = 100

func _enter_tree() -> void:
	var impaled_item := EQUIPPED_ITEM_PREFAB.instantiate() as EquippedItem
	impaled_item.weapon_data = state_data.thrown_item.weapon_data
	enemy.physical_bone_torso.add_child(impaled_item)
	impaled_item.global_transform.basis = state_data.thrown_item_basis
	impaled_item.translate_object_local(impaled_item.weapon_data.impale_local_translation)
	impaled_item.rotate_object_local(Vector3.UP, impaled_item.weapon_data.impale_local_rotation)
	state_data.thrown_item.queue_free()
	var impulse : Vector3 = state_data.thrown_item_basis * Vector3.FORWARD * IMPALE_INTENSITY + Vector3.UP * IMPALE_INTENSITY
	transition_state(Enemy.State.DYING, EnemyStateData.new().set_impulse(impulse))
